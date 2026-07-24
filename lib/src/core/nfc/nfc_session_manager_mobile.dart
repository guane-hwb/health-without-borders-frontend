// lib/src/core/nfc/nfc_session_manager_mobile.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import 'nfc_session_types.dart';

/// The one and only owner of the NFC radio.
///
/// Nothing else in the app may call `nfc_manager`. Two behaviours here are load
/// bearing, and both come straight out of what the NFC stack does on device:
///
/// 1. **Reader mode stays up for as long as the app is in the foreground**,
///    not just while a screen wants a chip. While reader mode is off the OS
///    owns the radio and dispatches tags to its own tag viewer, which is the
///    "Nueva etiqueta escaneada / Etiqueta vacía" screen. Holding reader mode
///    also removes the ~76 ms window in which discovery is stopped while it is
///    being enabled — a tap landing in that window used to be lost outright.
///    Chips that arrive while no caller is waiting are discarded, so the
///    clinician still only reads when they press the button.
///
/// 2. **Exactly one caller at a time**, enforced with [NfcBusyException]. The
///    plugin keeps a single global discovery callback; a second session used to
///    replace the first one's silently, leaving its future pending forever and
///    leaving reader mode enabled. A leaked session then poisons the next one:
///    `NfcAdapter.setReaderMode` ends in `applyRouting(false)`, which skips the
///    RF discovery restart when the parameters have not changed, so the chip is
///    never re-polled.
class NfcSessionManager with WidgetsBindingObserver implements NfcTagSource {
  NfcSessionManager._();

  static final NfcSessionManager instance = NfcSessionManager._();

  static const Duration defaultTimeout = Duration(seconds: 20);

  /// A chip seen while idle within this window means one is parked on the
  /// antenna right now.
  static const Duration presenceWindow = Duration(seconds: 4);

  /// What the radio is doing. Drive "hold still" / "tap again" copy off this.
  ///
  /// Not named `state`: that collides with the parameter of
  /// [didChangeAppLifecycleState]. Shadowing a field inside a lifecycle
  /// callback is a trap worth designing out rather than suppressing.
  final ValueNotifier<NfcRadioState> radioState = ValueNotifier<NfcRadioState>(
    NfcRadioState.off,
  );

  bool _attached = false;
  bool _readerModeOn = false;
  StreamSubscription<NfcAdapterStateAndroid>? _adapterSubscription;
  _Consumer? _consumer;
  DateTime? _lastIdleTagAt;

  /// Aborts the in-flight Core NFC session, if any. Set while an iOS session is
  /// open; null otherwise. The Android path uses [_consumer] instead, which the
  /// iOS path never populates — without this, cancelPending() would silently do
  /// nothing on iOS and leave the system sheet stranded on screen.
  Future<void> Function()? _iosCancelHook;

  bool get _usesReaderMode => defaultTargetPlatform == TargetPlatform.android;

  /// iOS has no persistent reader mode: Core NFC only polls inside a
  /// user-initiated session that the system draws its own sheet for. Every iOS
  /// path branches away before touching the Android code above, so that the
  /// working Android behaviour is bit-for-bit unchanged.
  bool get _usesIosSession => defaultTargetPlatform == TargetPlatform.iOS;

  /// Starts owning the radio. Call once, from the app root, after the first
  /// frame. Safe to call repeatedly.
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;

    WidgetsBinding.instance.addObserver(this);

    if (_usesIosSession) {
      // Nothing to hold: sessions are created per operation in _withTagIos.
      _setState(NfcRadioState.idle);
      return;
    }

    if (_usesReaderMode) {
      _adapterSubscription = NfcManagerAndroid.instance.onStateChanged.listen(
        _onAdapterStateChanged,
      );
    }

    await _enableReaderMode();
  }

  /// Releases the radio. For tests and for a clean shutdown.
  @visibleForTesting
  Future<void> detach() async {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    await _adapterSubscription?.cancel();
    _adapterSubscription = null;
    _failPending(NfcInterruptedException());
    await _disableReaderMode();
  }

  /// Waits for a chip and runs [action] against it.
  ///
  /// Always resolves: on success, or with [NfcTimeoutException],
  /// [NfcCancelledException], [NfcInterruptedException], [NfcBusyException],
  /// [NfcTagAlreadyPresentException], [NfcDisabledException],
  /// [NfcNotAvailableException], or whatever [action] throws. Nothing here can
  /// hang, which is the whole point: every spinner in the app used to depend on
  /// a callback that Android may simply never deliver.
  ///
  /// [timeout] only covers the wait for a chip. Once [action] starts running
  /// the timer is off — we never abort a write half-way through.
  @override
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout = defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    await attach();

    // iOS branches here, before any Android reader-mode logic runs.
    if (_usesIosSession) {
      return _withTagIos<T>(
        action,
        timeout: timeout,
        cancel: cancel,
        alertMessage: alertMessage,
      );
    }

    await _requireRadio();

    // Make sure the radio is actually polling before we sit and wait for a tag.
    // attach() only enables reader mode once, and the OS turns it back off on
    // its own — when the screen sleeps, on backgrounding, on a hot restart —
    // logging "Disabling reader mode because app died or moved to background".
    // Crucially it does NOT tell us, so _readerModeOn can read true while the
    // radio is actually off. Force a clean re-enable here rather than trusting
    // the flag: without this, withTag registers a consumer and waits forever on
    // a dead radio, which is exactly the "no device detected" that no amount of
    // holding the chip could fix.
    await _forceReaderMode();
    if (!_readerModeOn) throw NfcNotAvailableException();

    if (_consumer != null) throw NfcBusyException();

    // Android will not re-poll a chip that was already in the field, so if one
    // is sitting there we would wait out the full timeout for nothing. Say so.
    final seenAt = _lastIdleTagAt;
    if (seenAt != null && DateTime.now().difference(seenAt) < presenceWindow) {
      _lastIdleTagAt = null;
      throw NfcTagAlreadyPresentException();
    }

    if (cancel != null && cancel.isCancelled) throw NfcCancelledException();

    final completer = Completer<T>();
    late final _Consumer consumer;

    void release() {
      consumer.cancelTimer();
      if (identical(_consumer, consumer)) {
        _consumer = null;
        _publishIdleState();
      }
    }

    void fail(Object error) {
      if (consumer.busy || completer.isCompleted) return;
      completer.completeError(error);
      release();
    }

    consumer = _Consumer(
      timeout: timeout,
      onTimeout: () => fail(NfcTimeoutException(timeout)),
      onTag: (NfcTag raw) async {
        if (consumer.busy || completer.isCompleted) return;
        consumer.busy = true;
        consumer.cancelTimer();
        _lastIdleTagAt = null;
        _setState(NfcRadioState.working);
        try {
          final value = await action(_adapt(raw));
          if (!completer.isCompleted) completer.complete(value);
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        } finally {
          release();
        }
      },
      fail: fail,
    );

    unawaited(
      cancel?.whenCancelled.then((_) => fail(NfcCancelledException())) ??
          Future<void>.value(),
    );

    _consumer = consumer;
    consumer.startTimer();
    _setState(NfcRadioState.waiting);

    return completer.future;
  }

  // ── iOS ───────────────────────────────────────────────────────────────────

  /// Core NFC equivalent of [withTag].
  ///
  /// iOS has no persistent polling: a session is opened per operation, the
  /// system draws its own modal sheet over the app for its duration, and it
  /// closes when we invalidate it. That means several Android concerns simply
  /// do not exist here — there is no OS tag viewer to suppress, and no chip can
  /// be "already parked" because polling only starts when the sheet opens.
  ///
  /// [alertMessage] is the text inside that system sheet. On iOS it is the only
  /// way to tell the clinician which chip is being asked for, since our own UI
  /// is covered while the sheet is up.
  Future<T> _withTagIos<T>(
    Future<T> Function(HwbTag tag) action, {
    required Duration timeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    if (_consumer != null) throw NfcBusyException();

    final available = await NfcManagerIos.instance.tagSessionReadingAvailable();
    if (!available) throw NfcNotAvailableException();

    final completer = Completer<T>();
    var settled = false;
    Timer? timer;

    Future<void> finish({Object? error, T? value, String? sheetError}) async {
      if (settled) return;
      settled = true;
      timer?.cancel();
      _iosCancelHook = null;
      _setState(NfcRadioState.idle);
      try {
        await NfcManagerIos.instance.tagSessionInvalidate(
          errorMessage: sheetError,
        );
      } catch (_) {
        // The session may already be gone; nothing useful to do.
      }
      if (completer.isCompleted) return;
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(value as T);
      }
    }

    await NfcManagerIos.instance.tagSessionBegin(
      pollingOptions: const <NfcPollingOption>{
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      alertMessage: alertMessage,
      // We invalidate ourselves once the action has finished, so the sheet stays
      // up (and the tag stays connected) for the whole read or write.
      invalidateAfterFirstRead: false,
      didDetectTag: (NfcTag tag) async {
        if (settled) return;
        _setState(NfcRadioState.working);
        try {
          final value = await action(_adaptIos(tag));
          await finish(value: value);
        } catch (error) {
          await finish(error: error, sheetError: error.toString());
        }
      },
      didInvalidateWithError: (NfcReaderSessionErrorIos error) {
        if (settled) return;
        settled = true;
        timer?.cancel();
        _iosCancelHook = null;
        _setState(NfcRadioState.idle);
        if (completer.isCompleted) return;
        completer.completeError(_mapIosError(error));
      },
    );

    _iosCancelHook = () => finish(error: NfcCancelledException());
    _setState(NfcRadioState.waiting);

    // iOS enforces its own ~60s limit, but ours is shorter and keeps the
    // behaviour aligned with Android.
    timer = Timer(timeout, () {
      unawaited(finish(error: NfcTimeoutException(timeout)));
    });
    unawaited(
      cancel?.whenCancelled.then(
            (_) => finish(error: NfcCancelledException()),
          ) ??
          Future<void>.value(),
    );

    return completer.future;
  }

  /// Translates a Core NFC invalidation into the same exceptions the rest of
  /// the app already handles, so no call site needs to know the platform.
  static Object _mapIosError(NfcReaderSessionErrorIos error) {
    switch (error.code) {
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled:
        return NfcCancelledException();
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout:
        return NfcTimeoutException(defaultTimeout);
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorSystemIsBusy:
        return NfcBusyException();
      case NfcReaderErrorCodeIos
          .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
        return NfcInterruptedException();
      // ignore: no_default_cases
      default:
        return NfcSessionException(error.message);
    }
  }

  /// iOS counterpart of [_adapt].
  ///
  /// NTAG 215/216 wristbands surface as MiFare on iOS, which is where the
  /// identifier lives; DESFire cards do too. NDEF is exposed separately.
  HwbTag _adaptIos(NfcTag tag) {
    final mifare = MiFareIos.from(tag);
    final ndef = NdefIos.from(tag);
    return HwbTag(
      uid: mifare == null ? '' : formatNfcUid(mifare.identifier),
      ndef: ndef == null ? null : _IosNdef(ndef),
    );
  }

  /// Aborts whatever is waiting for a chip, if anything.
  ///
  /// This is what a screen's `dispose()` wants: the radio itself stays up (it
  /// belongs to the app, not to the screen), but the pending caller is released
  /// with [NfcCancelledException] instead of being left registered forever and
  /// making the next screen fail with [NfcBusyException].
  ///
  /// A no-op once a chip is in hand: we do not abort a write half-way through.
  void cancelPending() {
    final iosCancel = _iosCancelHook;
    if (iosCancel != null) {
      unawaited(iosCancel());
      return;
    }
    _failPending(NfcCancelledException());
  }

  // ── Radio lifecycle ──────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Screen woke or app came back to front. Re-take the radio and resume
        // the countdown from where it froze.
        unawaited(_enableReaderMode());
        _consumer?.startTimer();
      case AppLifecycleState.inactive:
        // Transient: notification shade, a system dialog, the app switcher
        // preview. The activity is still resumed as far as the NFC framework
        // is concerned, so keep the radio.
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // The screen slept or the app was backgrounded. Android hands the radio
        // back to the OS regardless, so drop reader mode — but do NOT abort the
        // pending read. A clinician holding a wristband to a phone whose display
        // times out is the core use case; killing the wait here is the bug that
        // made every held read fail with "no chip detected". Freeze the timeout
        // instead and resume on wake.
        _consumer?.pauseTimer();
        unawaited(_disableReaderMode());
      case AppLifecycleState.detached:
        // The engine is being torn down; the read genuinely cannot complete.
        _failPending(NfcInterruptedException());
        unawaited(_disableReaderMode());
    }
  }

  void _onAdapterStateChanged(NfcAdapterStateAndroid adapterState) {
    switch (adapterState) {
      case NfcAdapterStateAndroid.on:
        unawaited(_enableReaderMode());
      case NfcAdapterStateAndroid.off:
      case NfcAdapterStateAndroid.turningOff:
        _readerModeOn = false;
        _failPending(NfcDisabledException());
        _setState(NfcRadioState.disabled);
      case NfcAdapterStateAndroid.turningOn:
        break;
    }
  }

  Future<void> _enableReaderMode() async {
    if (!_usesReaderMode || _readerModeOn) return;
    await _doEnableReaderMode();
  }

  /// Re-enables reader mode even if [_readerModeOn] claims it is already on.
  ///
  /// The OS disables our reader mode without notifying us (screen sleep,
  /// backgrounding, hot restart), leaving the flag stale. Callers that are
  /// about to depend on the radio actually polling — [withTag] — force through
  /// this instead of the guarded [_enableReaderMode].
  Future<void> _forceReaderMode() async {
    if (!_usesReaderMode) return;
    // disableReaderMode first so the framework's internal state matches ours;
    // enabling twice without a disable is a no-op on some devices.
    if (_readerModeOn) {
      _readerModeOn = false;
      try {
        await NfcManagerAndroid.instance.disableReaderMode();
      } catch (_) {
        // Already off on the OS side; that is the state we want anyway.
      }
    }
    await _doEnableReaderMode();
  }

  Future<void> _doEnableReaderMode() async {
    try {
      await NfcManagerAndroid.instance.enableReaderMode(
        // NFC-A (NTAG 215/216 wristbands), NFC-B, NFC-V. Verified on device:
        // reader mode with exactly this mask activates an NTAG215 in under a
        // second. noPlatformSounds is intentionally NOT here — on this Samsung
        // it made enableReaderMode throw, which the catch below then swallowed,
        // so reader mode never came up and no tag was ever seen. The OS chime
        // on read is acceptable; a radio that never polls is not.
        flags: const {
          NfcReaderFlagAndroid.nfcA,
          NfcReaderFlagAndroid.nfcB,
          NfcReaderFlagAndroid.nfcV,
        },
        onTagDiscovered: _onTagDiscovered,
      );
      _readerModeOn = true;
      _publishIdleState();
    } catch (error, stackTrace) {
      // Do NOT swallow this silently. A failure here means the radio is not
      // polling at all, and a mute catch is exactly what hid that for days.
      _readerModeOn = false;
      _setState(NfcRadioState.off);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nfc_session_manager',
          context: ErrorDescription('enabling NFC reader mode'),
        ),
      );
    }
  }

  Future<void> _disableReaderMode() async {
    if (!_usesReaderMode || !_readerModeOn) return;
    _readerModeOn = false;
    _lastIdleTagAt = null;
    try {
      await NfcManagerAndroid.instance.disableReaderMode();
    } catch (_) {
      // Nothing useful to do; the OS reclaims the radio when we lose focus.
    }
    _setState(NfcRadioState.off);
  }

  Future<void> _requireRadio() async {
    switch (await NfcManager.instance.checkAvailability()) {
      case NfcAvailability.unsupported:
        throw NfcNotAvailableException();
      case NfcAvailability.disabled:
        throw NfcDisabledException();
      case NfcAvailability.enabled:
        break;
    }
  }

  // ── Dispatch ─────────────────────────────────────────────────────────────

  void _onTagDiscovered(NfcTag tag) {
    final consumer = _consumer;
    if (consumer == null) {
      // Nobody asked for this. Swallowing it is the point: we hold the radio so
      // the OS tag viewer never appears, but a chip brushing the phone is not
      // an instruction to read a patient record. Remember that one was here so
      // withTag can tell the difference between "waiting" and "parked".
      _lastIdleTagAt = DateTime.now();
      return;
    }
    consumer.onTag(tag);
  }

  void _failPending(Object error) => _consumer?.fail(error);

  void _publishIdleState() {
    if (!_readerModeOn) {
      _setState(NfcRadioState.off);
      return;
    }
    _setState(_consumer == null ? NfcRadioState.idle : NfcRadioState.waiting);
  }

  void _setState(NfcRadioState next) {
    if (radioState.value != next) radioState.value = next;
  }

  HwbTag _adapt(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    final ndef = NdefAndroid.from(tag);
    return HwbTag(
      uid: androidTag == null ? '' : formatNfcUid(androidTag.id),
      ndef: ndef == null ? null : _AndroidNdef(ndef),
    );
  }
}

class _Consumer {
  _Consumer({
    required this.onTag,
    required this.fail,
    required this.timeout,
    required this.onTimeout,
  }) : _remaining = timeout;

  final void Function(NfcTag tag) onTag;
  final void Function(Object error) fail;

  /// Set once a chip is in hand, to keep the timeout and cancel from yanking
  /// the future out from under an in-flight transceive.
  bool busy = false;

  final Duration timeout;
  final void Function() onTimeout;

  Timer? _timer;
  DateTime? _startedAt;
  Duration _remaining;

  /// Starts the timeout, or restarts it with the time that was left when it was
  /// last paused.
  void startTimer() {
    if (busy) return;
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_remaining, onTimeout);
  }

  /// Freezes the countdown. Called when the screen sleeps: a clinician holding
  /// a wristband to a phone whose display times out has not walked away, so the
  /// wait must survive until the screen wakes — otherwise it dies mid-read.
  void pauseTimer() {
    if (busy || _timer == null) return;
    _timer!.cancel();
    _timer = null;
    final started = _startedAt;
    if (started != null) {
      _remaining -= DateTime.now().difference(started);
      if (_remaining < Duration.zero) _remaining = Duration.zero;
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// iOS NDEF surface.
///
/// Core NFC calls the budget `capacity` and reports writability through a
/// status enum rather than a bool, so both are mapped onto the shared contract
/// the rest of the app already uses.
class _IosNdef implements HwbNdef {
  _IosNdef(this._ndef);

  final NdefIos _ndef;

  @override
  bool get isWritable => _ndef.status == NdefStatusIos.readWrite;

  @override
  int get maxSize => _ndef.capacity;

  @override
  NdefMessage? get cachedMessage => _ndef.cachedNdefMessage;

  @override
  Future<void> write(NdefMessage message) => _ndef.writeNdef(message);
}

class _AndroidNdef implements HwbNdef {
  _AndroidNdef(this._ndef);

  final NdefAndroid _ndef;

  @override
  bool get isWritable => _ndef.isWritable;

  @override
  int get maxSize => _ndef.maxSize;

  @override
  NdefMessage? get cachedMessage => _ndef.cachedNdefMessage;

  @override
  Future<void> write(NdefMessage message) => _ndef.writeNdefMessage(message);
}
