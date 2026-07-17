// lib/src/core/nfc/nfc_session_manager_mobile.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

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

  bool get _usesReaderMode => defaultTargetPlatform == TargetPlatform.android;

  /// Starts owning the radio. Call once, from the app root, after the first
  /// frame. Safe to call repeatedly.
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;

    WidgetsBinding.instance.addObserver(this);

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
  }) async {
    await attach();
    await _requireRadio();

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
    Timer? timer;

    void release() {
      timer?.cancel();
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
      onTag: (NfcTag raw) async {
        if (consumer.busy || completer.isCompleted) return;
        consumer.busy = true;
        _lastIdleTagAt = null;
        _setState(NfcRadioState.working);
        try {
          final value = await action(_adapt(raw));
          if (!completer.isCompleted) completer.complete(value);
        } catch (error, stackTrace) {
          if (!completer.isCompleted)
            completer.completeError(error, stackTrace);
        } finally {
          release();
        }
      },
      fail: fail,
    );

    timer = Timer(timeout, () => fail(NfcTimeoutException(timeout)));
    unawaited(
      cancel?.whenCancelled.then((_) => fail(NfcCancelledException())) ??
          Future<void>.value(),
    );

    _consumer = consumer;
    _setState(NfcRadioState.waiting);

    return completer.future;
  }

  /// Aborts whatever is waiting for a chip, if anything.
  ///
  /// This is what a screen's `dispose()` wants: the radio itself stays up (it
  /// belongs to the app, not to the screen), but the pending caller is released
  /// with [NfcCancelledException] instead of being left registered forever and
  /// making the next screen fail with [NfcBusyException].
  ///
  /// A no-op once a chip is in hand: we do not abort a write half-way through.
  void cancelPending() => _failPending(NfcCancelledException());

  // ── Radio lifecycle ──────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_enableReaderMode());
      case AppLifecycleState.inactive:
        // Transient: notification shade, a system dialog, the app switcher
        // preview. The activity is still resumed as far as the NFC framework
        // is concerned, so keep the radio.
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
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
    try {
      await NfcManagerAndroid.instance.enableReaderMode(
        // Matches what the app polled before the migration: NFC-A (NTAG 215/216
        // wristbands), NFC-B, NFC-V. Verified on device — reader mode with this
        // mask activates an NTAG215 in well under a second. noPlatformSounds
        // keeps the OS chime off, since our own UI reports the tap.
        flags: const {
          NfcReaderFlagAndroid.nfcA,
          NfcReaderFlagAndroid.nfcB,
          NfcReaderFlagAndroid.nfcV,
          NfcReaderFlagAndroid.noPlatformSounds,
        },
        onTagDiscovered: _onTagDiscovered,
      );
      _readerModeOn = true;
      _publishIdleState();
    } catch (_) {
      _readerModeOn = false;
      _setState(NfcRadioState.off);
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
  _Consumer({required this.onTag, required this.fail});

  final void Function(NfcTag tag) onTag;
  final void Function(Object error) fail;

  /// Set once a chip is in hand, to keep the timeout and cancel from yanking
  /// the future out from under an in-flight transceive.
  bool busy = false;
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
