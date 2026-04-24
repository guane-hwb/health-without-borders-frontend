import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

/// Reads the factory UID from NFC wristbands.
///
/// The UID is the immutable serial number burned into every NFC chip.
/// It becomes the `device_uid` field in the backend.
class NfcService {
  NfcService._();

  /// Whether the device hardware supports NFC.
  static Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  /// Starts an NFC session and reads the chip's factory UID.
  ///
  /// Returns the UID as a colon-separated hex string (e.g., "04:A1:B2:C3").
  /// Throws [NfcNotAvailableException] if the device lacks NFC hardware.
  /// Throws [NfcSessionException] on read error or cancellation.
  static Future<String> readDeviceUid() async {
    if (!await NfcManager.instance.isAvailable()) {
      throw NfcNotAvailableException();
    }

    final Completer<String> completer = Completer<String>();

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          final Uint8List? id = _extractIdentifier(tag);
          if (id == null || id.isEmpty) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcSessionException('Could not read tag identifier.'),
              );
            }
          } else {
            if (!completer.isCompleted) {
              completer.complete(_bytesToHex(id));
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

  static Uint8List? _extractIdentifier(NfcTag tag) {
    // Try each technology in order of likelihood for NTAG/MIFARE wristbands
    final nfcA = NfcA.from(tag);
    if (nfcA != null) return nfcA.identifier;

    final nfcB = NfcB.from(tag);
    if (nfcB != null) return nfcB.identifier;

    final nfcV = NfcV.from(tag);
    if (nfcV != null) return nfcV.identifier;

    final nfcF = NfcF.from(tag);
    if (nfcF != null) return nfcF.identifier;

    // iOS-specific
    final iso7816 = Iso7816.from(tag);
    if (iso7816 != null) return iso7816.identifier;

    return null;
  }

  /// [0x04, 0xA1, 0xB2] → "04:A1:B2"
  static String _bytesToHex(Uint8List bytes) {
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