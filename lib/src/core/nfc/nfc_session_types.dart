// lib/src/core/nfc/nfc_session_types.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

/// The NDEF surface HWB needs from a chip.
///
/// This exists so that nothing above [NfcSessionManager] ever touches a
/// `nfc_manager` type. The plugin seals its tag classes (`final class NfcTag`,
/// `@protected Object data`), which makes them impossible to fake; every layer
/// that needs to be testable therefore talks to this interface instead.
abstract class HwbNdef {
  /// Whether the chip will accept a write.
  bool get isWritable;

  /// Maximum size in bytes of the whole NDEF *message* the chip can hold.
  ///
  /// This is not the payload budget: the MIME record's own header and type
  /// string come out of it. Compare against [NdefMessage.byteLength], never
  /// against a bare payload length.
  int get maxSize;

  /// The NDEF message the platform read at discovery, if any.
  NdefMessage? get cachedMessage;

  /// Writes [message] to the chip.
  Future<void> write(NdefMessage message);
}

/// A chip sitting in the RF field, normalised to what HWB cares about.
class HwbTag {
  const HwbTag({required this.uid, this.ndef});

  /// Colon-separated uppercase hex, e.g. `04:A1:B2:C3`.
  ///
  /// Empty when the identifier could not be read.
  final String uid;

  /// Null when the chip is not NDEF-formatted.
  final HwbNdef? ndef;
}

/// The only thing the rest of the app is allowed to ask of the NFC radio.
///
/// `NfcSessionManager` is the production implementation; tests supply a fake.
/// This is the seam that used to live on the plugin's own types, which v4 made
/// impossible to fake (`final class NfcTag`, `@protected Object data`, and a
/// `TagPigeon` that is not exported).
abstract class NfcTagSource {
  /// Waits for a chip and runs [action] against it.
  ///
  /// Never hangs: resolves with [action]'s result, or throws
  /// [NfcTimeoutException], [NfcCancelledException], [NfcBusyException],
  /// [NfcTagAlreadyPresentException], [NfcInterruptedException],
  /// [NfcDisabledException] or [NfcNotAvailableException].
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout,
    NfcCancelToken? cancel,

    /// Text shown inside the iOS system scanning sheet. Ignored on Android,
    /// where the app draws its own scanning UI.
    String? alertMessage,
  });
}

/// What the NFC radio is doing, for the UI to show.
enum NfcRadioState {
  /// No NFC hardware.
  unsupported,

  /// NFC is switched off in system settings.
  disabled,

  /// HWB is not polling: the app is not in the foreground.
  off,

  /// Reader mode is up and polling. Chips that arrive are discarded, because
  /// nobody asked for one. This is what keeps the OS tag viewer off the screen
  /// without acting on chips the clinician did not intend to read.
  idle,

  /// A caller is waiting for a chip.
  waiting,

  /// A chip is being read or written. Do not remove it.
  working,
}

/// Lets a caller abort a pending [NfcSessionManager.withTag].
///
/// Uses a completer rather than private callbacks so the manager can observe it
/// from another library file.
class NfcCancelToken {
  final Completer<void> _completer = Completer<void>();

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  bool get isCancelled => _completer.isCompleted;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/// `[0x04, 0xA1, 0xB2]` → `"04:A1:B2"`.
String formatNfcUid(Uint8List bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(':');

/// Normalises a UID for comparison: hex digits only, uppercased.
///
String normalizeNfcUid(String uid) {
  return uid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
}

// lib/src/core/nfc/nfc_session_types.dart

/// Normaliza un UID tecleado manualmente conservando el casing original (mayúsculas/minúsculas)
/// e insertando los dos puntos `:` en bloques de a 2 caracteres si es hexadecimal.
String normalizeTypedNfcUid(String input) {
  final String t = input.trim();
  if (t.isEmpty) return '';

  // Verifica si es una secuencia tipo hex/tecleada con posibles espacios, guiones o puntos
  if (RegExp(r'^[0-9a-fA-F\s:.\-]+$').hasMatch(t)) {
    // Quita caracteres no hexadecimales SIN modificar mayúsculas o minúsculas
    final String cleanHex = t.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleanHex.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i > 0) buffer.write(':');
      if (i + 2 <= cleanHex.length) {
        buffer.write(cleanHex.substring(i, i + 2));
      } else {
        buffer.write(cleanHex.substring(i));
      }
    }
    return buffer.toString();
  }

  return t;
}

// ── Exceptions ──────────────────────────────────────────────────────────────

/// Base type for every recoverable NFC failure. Carries a message the UI can
/// show as-is.
class NfcSessionException implements Exception {
  NfcSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The device has no NFC hardware.
///
/// Intentionally not an [NfcSessionException]: callers catch it separately.
class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

/// NFC is switched off in system settings.
class NfcDisabledException extends NfcSessionException {
  NfcDisabledException()
    : super('NFC is turned off. Enable it in system settings.');
}

/// Another NFC operation is already waiting for a chip.
///
/// The radio has exactly one consumer at a time. Before this existed, a second
/// `startSession` silently replaced the first one's callback and its future
/// never completed.
class NfcBusyException extends NfcSessionException {
  NfcBusyException() : super('Another NFC operation is already in progress.');
}

/// No chip arrived before the timeout elapsed.
class NfcTimeoutException extends NfcSessionException {
  NfcTimeoutException(this.timeout)
    : super('No device detected. Hold it against the reader and try again.');
  final Duration timeout;
}

/// The caller aborted the operation.
class NfcCancelledException extends NfcSessionException {
  NfcCancelledException() : super('NFC operation cancelled.');
}

/// The app left the foreground, so the radio was handed back to the OS.
class NfcInterruptedException extends NfcSessionException {
  NfcInterruptedException() : super('NFC operation interrupted.');
}

/// A chip is already parked on the antenna.
///
/// Android does not re-poll a chip that was already in the field when reader
/// mode came up, so waiting would hang until the timeout. Surfacing this lets
/// the UI say "lift it and tap again" instead of spinning.
class NfcTagAlreadyPresentException extends NfcSessionException {
  NfcTagAlreadyPresentException()
    : super('Lift the device away and tap it again.');
}
