// lib/src/core/nfc/nfc_payload_service.dart
//
// High-level service that combines NfcService (UID read) with
// NfcPayloadCodec (encode/decode) and nfc_manager NDEF write/read.
//
// This service handles the full NFC lifecycle:
//   1. Read factory UID (existing)
//   2. Write encrypted triage payload to patient wristband
//   3. Read and decrypt triage payload from patient wristband

import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

import 'nfc_payload_codec.dart';
import 'nfc_triage_payload.dart';

/// MIME type used for HWB NFC payloads.
/// This allows the app to identify its own NDEF records.
const String kHwbNdefMimeType = 'application/vnd.hwb.triage';

/// High-level NFC operations for reading/writing encrypted payloads.
class NfcPayloadService {
  NfcPayloadService({required this.codec});

  final NfcPayloadCodec codec;

  /// Writes an encrypted triage payload to the NFC chip.
  ///
  /// Returns the factory UID of the chip that was written to.
  /// Throws [NfcWriteException] if the chip doesn't have enough space
  /// or if the write fails.
  Future<NfcWriteResult> writeTriagePayload(
    Map<String, dynamic> triagePayload,
  ) async {
    if (!await NfcManager.instance.isAvailable()) {
      throw NfcNotAvailableException();
    }

    // Encode the payload first to check size
    final encrypted = await codec.encode(triagePayload);

    final completer = Completer<NfcWriteResult>();

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          // Extract UID
          final uid = _extractUid(tag);
          if (uid == null) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcWriteException('Could not read chip UID'),
              );
            }
            return;
          }

          // Get NDEF interface
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcWriteException(
                  'Chip does not support NDEF. '
                  'Make sure you are using NTAG 213/215/216.',
                ),
              );
            }
            return;
          }

          // Check if writable
          if (!ndef.isWritable) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcWriteException('Chip is read-only or locked'),
              );
            }
            return;
          }

          // Check capacity
          final capacity = ndef.maxSize;
          if (encrypted.length > capacity) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcWriteException(
                  'Payload too large: ${encrypted.length} bytes, '
                  'chip capacity: $capacity bytes. '
                  'Reduce allergies/conditions or use a larger chip.',
                ),
              );
            }
            return;
          }

          // Build NDEF message with our MIME type
          final ndefMessage = NdefMessage([
            NdefRecord.createMime(kHwbNdefMimeType, encrypted),
          ]);

          // Write!
          await ndef.write(ndefMessage);

          if (!completer.isCompleted) {
            completer.complete(NfcWriteResult(
              uid: uid,
              bytesWritten: encrypted.length,
              chipCapacity: capacity,
            ));
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(
              NfcWriteException('Write failed: $e'),
            );
          }
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcWriteException('NFC error: $error'));
        }
        await NfcManager.instance.stopSession();
      },
    );

    return completer.future;
  }

  /// Reads and decrypts a triage payload from an NFC chip.
  ///
  /// Returns [NfcReadResult] containing the UID and decoded triage data.
  /// Returns null triage if the chip has no HWB payload (e.g., blank chip).
  Future<NfcReadResult> readTriagePayload() async {
    if (!await NfcManager.instance.isAvailable()) {
      throw NfcNotAvailableException();
    }

    final completer = Completer<NfcReadResult>();

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          // Extract UID
          final uid = _extractUid(tag);
          if (uid == null) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcReadException('Could not read chip UID'),
              );
            }
            return;
          }

          // Try to read NDEF
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            // Chip doesn't support NDEF — return UID only
            if (!completer.isCompleted) {
              completer.complete(NfcReadResult(uid: uid, triage: null));
            }
            return;
          }

          final cachedMessage = ndef.cachedMessage;
          if (cachedMessage == null || cachedMessage.records.isEmpty) {
            // No NDEF message — chip is blank or formatted but empty
            if (!completer.isCompleted) {
              completer.complete(NfcReadResult(uid: uid, triage: null));
            }
            return;
          }

          // Find our HWB record by MIME type
          Uint8List? hwbPayload;
          for (final record in cachedMessage.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.media) {
              final type = String.fromCharCodes(record.type);
              if (type == kHwbNdefMimeType) {
                hwbPayload = record.payload;
                break;
              }
            }
          }

          if (hwbPayload == null) {
            // No HWB record found
            if (!completer.isCompleted) {
              completer.complete(NfcReadResult(uid: uid, triage: null));
            }
            return;
          }

          // Decrypt and decode
          final decoded = await codec.decode(hwbPayload);
          final triage = decoded != null
              ? NfcTriagePayload.fromPayload(decoded)
              : null;

          if (!completer.isCompleted) {
            completer.complete(NfcReadResult(uid: uid, triage: triage));
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(NfcReadException('Read failed: $e'));
          }
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcReadException('NFC error: $error'));
        }
        await NfcManager.instance.stopSession();
      },
    );

    return completer.future;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String? _extractUid(NfcTag tag) {
    final data = tag.data;
    for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
      final tech = data[key] as Map<dynamic, dynamic>?;
      if (tech != null) {
        final id = tech['identifier'];
        if (id is List) {
          final bytes = Uint8List.fromList(id.cast<int>());
          return bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(':');
        }
      }
    }
    return null;
  }
}

// ── Result types ────────────────────────────────────────────────────────────

class NfcWriteResult {
  const NfcWriteResult({
    required this.uid,
    required this.bytesWritten,
    required this.chipCapacity,
  });

  final String uid;
  final int bytesWritten;
  final int chipCapacity;

  double get utilizationPercent => (bytesWritten / chipCapacity) * 100;
}

class NfcReadResult {
  const NfcReadResult({required this.uid, required this.triage});

  final String uid;

  /// Null if the chip has no HWB payload (blank or different format).
  final TriageSummary? triage;
}

// ── Exceptions ──────────────────────────────────────────────────────────────

class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

class NfcWriteException implements Exception {
  NfcWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NfcReadException implements Exception {
  NfcReadException(this.message);
  final String message;
  @override
  String toString() => message;
}
