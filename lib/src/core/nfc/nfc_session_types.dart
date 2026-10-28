// lib/src/core/nfc/nfc_session_types.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

abstract class HwbNdef {
  bool get isWritable;

  int get maxSize;

  NdefMessage? get cachedMessage;

  Future<void> write(NdefMessage message);
}

class HwbTag {
  const HwbTag({required this.uid, this.ndef});

  final String uid;

  final HwbNdef? ndef;
}

abstract class NfcTagSource {
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout,
    NfcCancelToken? cancel,

    String? alertMessage,
  });
}

enum NfcRadioState { unsupported, disabled, off, idle, waiting, working }

class NfcCancelToken {
  final Completer<void> _completer = Completer<void>();

  Future<void> get whenCancelled => _completer.future;

  bool get isCancelled => _completer.isCompleted;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String formatNfcUid(Uint8List bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(':');

String normalizeNfcUid(String uid) {
  return uid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
}

String normalizeTypedNfcUid(String input) {
  final String t = input.trim();
  if (t.isEmpty) return '';

  if (RegExp(r'^[0-9a-fA-F\s:.\-]+$').hasMatch(t)) {
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

class NfcSessionException implements Exception {
  NfcSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

class NfcDisabledException extends NfcSessionException {
  NfcDisabledException()
    : super('NFC is turned off. Enable it in system settings.');
}

class NfcBusyException extends NfcSessionException {
  NfcBusyException() : super('Another NFC operation is already in progress.');
}

class NfcTimeoutException extends NfcSessionException {
  NfcTimeoutException(this.timeout)
    : super('No device detected. Hold it against the reader and try again.');
  final Duration timeout;
}

class NfcCancelledException extends NfcSessionException {
  NfcCancelledException() : super('NFC operation cancelled.');
}

class NfcInterruptedException extends NfcSessionException {
  NfcInterruptedException() : super('NFC operation interrupted.');
}

class NfcTagAlreadyPresentException extends NfcSessionException {
  NfcTagAlreadyPresentException()
    : super('Lift the device away and tap it again.');
}
