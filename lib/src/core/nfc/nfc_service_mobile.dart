import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// Reads the factory UID from NFC wristbands.
///
/// The UID is the immutable serial number burned into every NFC chip.
/// It becomes the `device_uid` field in the backend.
class NfcService {
  NfcService._();

  static Future<String> Function()? overrideReadDeviceUid;

  /// Whether the device hardware supports NFC.
  static Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  /// Starts an NFC session and reads the chip's factory UID.
  ///
  /// Returns the UID as a colon-separated hex string (e.g., "04:A1:B2:C3").
  /// Throws [NfcNotAvailableException] if the device lacks NFC hardware.
  /// Throws [NfcSessionException] on read error or cancellation.
  static Future<String> readDeviceUid() async {
    if (overrideReadDeviceUid != null) {
      return overrideReadDeviceUid!();
    }
    if (!await NfcManager.instance.isAvailable()) {
      throw NfcNotAvailableException();
    }

    final Completer<String> completer = Completer<String>();

    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          final Uint8List? id = extractIdentifier(tag);
          if (id == null || id.isEmpty) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcSessionException('Could not read tag identifier.'),
              );
            }
          } else {
            if (!completer.isCompleted) {
              completer.complete(bytesToHex(id));
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(NfcSessionException('$e'));
          }
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcSessionException('$error'));
        }
        await NfcManager.instance.stopSession();
      },
    );

    return completer.future;
  }

  /// Cancels any active NFC session.
  static Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  @visibleForTesting
  static Uint8List? extractIdentifier(NfcTag tag) {
    final data = tag.data;

    for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
      final tech = data[key] as Map<dynamic, dynamic>?;
      if (tech != null) {
        final id = tech['identifier'];
        if (id is List) {
          return Uint8List.fromList(id.cast<int>());
        }
      }
    }

    return null;
  }

  /// [0x04, 0xA1, 0xB2] → "04:A1:B2"
  @visibleForTesting
  static String bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}

// ── Exceptions ──────────────────────────────────────────────────────────────

class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

class NfcSessionException implements Exception {
  NfcSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}
