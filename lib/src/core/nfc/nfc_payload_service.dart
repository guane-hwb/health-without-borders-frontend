// lib/src/core/nfc/nfc_payload_service.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

import 'nfc_payload_codec.dart';
import 'nfc_triage_payload.dart';

/// MIME type used for HWB NFC payloads.
const String kHwbNdefMimeType = 'application/vnd.hwb.triage';

/// MIME type for the guardian card's bounded full-record payload.
/// A distinct type lets the reader tell a patient wristband apart from a
/// guardian card and pick the right reconstructor.
const String kHwbGuardianMimeType = 'application/vnd.hwb.guardian';

/// High-level NFC operations for reading/writing encrypted payloads.
class NfcPayloadService {
  NfcPayloadService({required this.codec, NfcManager? nfcManager})
    : _nfcManager = nfcManager ?? NfcManager.instance;

  final NfcPayloadCodec codec;
  final NfcManager _nfcManager;

  Future<NfcWriteResult> writeTriagePayload(
    Map<String, dynamic> triagePayload, {
    String? expectedUid,
  }) {
    return _writePayload(
      triagePayload,
      mimeType: kHwbNdefMimeType,
      expectedUid: expectedUid,
    );
  }

  /// Writes the guardian's bounded full-record payload to the guardian card
  /// (DESFire EV3 4K formatted as an NDEF / Type 4 tag).
  ///
  /// The map should be produced by NfcGuardianPayload.buildWithinCapacity so
  /// it already fits the card. Pass [expectedUid] to refuse writing unless the
  /// tapped card matches the guardian UID recorded for this patient.
  Future<NfcWriteResult> writeGuardianPayload(
    Map<String, dynamic> guardianPayload, {
    String? expectedUid,
  }) {
    return _writePayload(
      guardianPayload,
      mimeType: kHwbGuardianMimeType,
      expectedUid: expectedUid,
    );
  }

  /// Shared NDEF write: encodes [payload], finds the chip, optionally verifies
  /// its UID against [expectedUid], checks capacity, and writes one MIME record
  /// of type [mimeType].
  ///
  /// Throws [NfcUidMismatchException] if [expectedUid] is given and the tapped
  /// chip's UID differs, or [NfcWriteException] on any other failure.
  Future<NfcWriteResult> _writePayload(
    Map<String, dynamic> payload, {
    required String mimeType,
    String? expectedUid,
  }) async {
    if (!await _nfcManager.isAvailable()) {
      throw NfcNotAvailableException();
    }

    // Encode the payload first to check size
    final encrypted = await codec.encode(payload);

    final completer = Completer<NfcWriteResult>();

    _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
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

          // Safeguard: never seal one person's data onto a different chip.
          if (expectedUid != null &&
              _normalizeUid(uid) != _normalizeUid(expectedUid)) {
            if (!completer.isCompleted) {
              completer.completeError(
                NfcUidMismatchException(expected: expectedUid, actual: uid),
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
                  'Chip is not NDEF-formatted. Use an NTAG (patient) or an '
                  'NDEF-formatted DESFire (guardian).',
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
                  'chip capacity: $capacity bytes.',
                ),
              );
            }
            return;
          }

          // Build NDEF message with the requested MIME type
          final ndefMessage = NdefMessage([
            NdefRecord.createMime(mimeType, encrypted),
          ]);

          // Write!
          await ndef.write(ndefMessage);

          if (!completer.isCompleted) {
            completer.complete(
              NfcWriteResult(
                uid: uid,
                bytesWritten: encrypted.length,
                chipCapacity: capacity,
              ),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(NfcWriteException('Write failed: $e'));
          }
        } finally {
          await _nfcManager.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcWriteException('NFC error: $error'));
        }
        await _nfcManager.stopSession();
      },
    );

    return completer.future;
  }

  /// Reads and decrypts a triage payload from an NFC chip.
  Future<NfcReadResult> readTriagePayload() async {
    if (!await _nfcManager.isAvailable()) {
      throw NfcNotAvailableException();
    }

    final completer = Completer<NfcReadResult>();

    _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
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
            if (!completer.isCompleted) {
              completer.complete(NfcReadResult(uid: uid, triage: null));
            }
            return;
          }

          final cachedMessage = ndef.cachedMessage;
          if (cachedMessage == null || cachedMessage.records.isEmpty) {
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
          await _nfcManager.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcReadException('NFC error: $error'));
        }
        await _nfcManager.stopSession();
      },
    );

    return completer.future;
  }

  /// Reads any HWB chip — patient wristband or guardian card — in one tap.
  ///
  /// Returns the UID plus whichever payload was found, decoded and ready to
  /// reconstruct a record. If both records are present the guardian one wins
  /// (it is a superset). Returns [HwbChipKind.none] for a blank or non-HWB
  /// chip (the UID is still populated when readable). Used for offline reads.
  Future<HwbChipReadResult> readHwbChip() async {
    if (!await _nfcManager.isAvailable()) {
      throw NfcNotAvailableException();
    }

    final completer = Completer<HwbChipReadResult>();

    _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          final uid = _extractUid(tag) ?? '';

          final ndef = Ndef.from(tag);
          final cached = ndef?.cachedMessage;
          if (ndef == null || cached == null || cached.records.isEmpty) {
            if (!completer.isCompleted) {
              completer.complete(
                HwbChipReadResult(uid: uid, kind: HwbChipKind.none),
              );
            }
            return;
          }

          // Collect HWB records by MIME type (guardian preferred over triage).
          Uint8List? guardianPayload;
          Uint8List? triagePayload;
          for (final record in cached.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.media) {
              final type = String.fromCharCodes(record.type);
              if (type == kHwbGuardianMimeType) {
                guardianPayload = record.payload;
              } else if (type == kHwbNdefMimeType) {
                triagePayload = record.payload;
              }
            }
          }

          if (guardianPayload != null) {
            final decoded = await codec.decode(guardianPayload);
            if (!completer.isCompleted) {
              completer.complete(
                HwbChipReadResult(
                  uid: uid,
                  kind: decoded != null
                      ? HwbChipKind.guardian
                      : HwbChipKind.none,
                  guardianRecord: decoded,
                ),
              );
            }
            return;
          }

          if (triagePayload != null) {
            final decoded = await codec.decode(triagePayload);
            final triage = decoded != null
                ? NfcTriagePayload.fromPayload(decoded)
                : null;
            if (!completer.isCompleted) {
              completer.complete(
                HwbChipReadResult(
                  uid: uid,
                  kind: triage != null ? HwbChipKind.triage : HwbChipKind.none,
                  triage: triage,
                ),
              );
            }
            return;
          }

          if (!completer.isCompleted) {
            completer.complete(
              HwbChipReadResult(uid: uid, kind: HwbChipKind.none),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(NfcReadException('Read failed: $e'));
          }
        } finally {
          await _nfcManager.stopSession();
        }
      },
      onError: (dynamic error) async {
        if (!completer.isCompleted) {
          completer.completeError(NfcReadException('NFC error: $error'));
        }
        await _nfcManager.stopSession();
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

  /// Normalizes a UID for comparison: keeps only hex digits, uppercased.
  /// Tolerates formatting differences (colons, case) between the value read
  /// at scan time and the value stored on the record.
  static String _normalizeUid(String uid) =>
      uid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
}

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
  final TriageSummary? triage;
}

/// Which HWB payload a chip carries.
enum HwbChipKind { none, triage, guardian }

/// Result of reading an HWB chip with [NfcPayloadService.readHwbChip].
///
/// For [HwbChipKind.guardian], [guardianRecord] is the full-record JSON map
/// (feed it to NfcGuardianPayload.reconstructFromGuardian). For
/// [HwbChipKind.triage], [triage] is the decoded triage summary (feed it to
/// NfcGuardianPayload.reconstructFromTriage).
class HwbChipReadResult {
  const HwbChipReadResult({
    required this.uid,
    required this.kind,
    this.triage,
    this.guardianRecord,
  });

  final String uid;
  final HwbChipKind kind;
  final TriageSummary? triage;
  final Map<String, dynamic>? guardianRecord;
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

/// Thrown when the tapped chip's UID does not match the expected UID, to avoid
/// sealing one person's data onto a different device.
class NfcUidMismatchException implements Exception {
  NfcUidMismatchException({required this.expected, required this.actual});
  final String expected;
  final String actual;
  @override
  String toString() =>
      'Scanned chip UID ($actual) does not match expected UID ($expected).';
}

class NfcReadException implements Exception {
  NfcReadException(this.message);
  final String message;
  @override
  String toString() => message;
}
