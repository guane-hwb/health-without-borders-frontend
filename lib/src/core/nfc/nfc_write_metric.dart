// lib/src/core/nfc/nfc_write_metric.dart
//
// What the app reports about each chip it writes: sizes and counts, nothing
// that identifies a chip, a patient or a record.
//
// The NFC payload format is being redesigned (dictionary, typed values, a
// shorter record type) and the guardian copy may carry less. Both decisions
// need the real distribution of what gets written: how close each write comes
// to the chip's capacity and how often the guardian copy had to leave history
// out. The audit that motivates them measured synthetic records only.

import 'nfc_keyring.dart' show kLegacyNfcKeyVersion;

/// Format of the payloads this build writes: CBOR + DEFLATE + AES-GCM in a
/// MIME record (see `docs/architecture/nfc-encryption.md`).
const int kCurrentNfcPayloadFormat = 1;

/// Called after every successful chip write. Implementations must not throw:
/// a lost metric delays a decision, it must never fail a write.
typedef NfcWriteObserver = Future<void> Function(NfcWriteMetric metric);

/// Sizes and counts of one successful chip write.
class NfcWriteMetric {
  const NfcWriteMetric({
    required this.deviceRole,
    required this.payloadFormat,
    required this.keyVersion,
    required this.payloadBytes,
    required this.messageBytes,
    required this.chipCapacity,
    required this.writtenAt,
    this.consultationsKept,
    this.consultationsTotal,
    this.vaccinesKept,
    this.vaccinesTotal,
  });

  /// `'patient'` for the triage on the patient device, `'guardian'` for the
  /// bounded copy on a guardian device.
  final String deviceRole;

  /// [kCurrentNfcPayloadFormat] for this build.
  final int payloadFormat;

  /// Key version the payload was encrypted under.
  final int keyVersion;

  /// Encrypted payload, without the NDEF record around it.
  final int payloadBytes;

  /// Whole NDEF message written, which is what the chip's capacity bounds.
  final int messageBytes;

  /// NDEF capacity the chip reported.
  final int chipCapacity;

  /// Consultations on the guardian copy and in the record; null for a patient
  /// device, whose triage carries no history.
  final int? consultationsKept;
  final int? consultationsTotal;

  /// Vaccines on the guardian copy and in the record; null for a patient
  /// device.
  final int? vaccinesKept;
  final int? vaccinesTotal;

  /// When the write finished, in UTC.
  final DateTime writtenAt;

  /// The row `LocalDatabase.recordNfcWriteMetric` stores.
  Map<String, Object?> toRow() => <String, Object?>{
    'device_role': deviceRole,
    'payload_format': payloadFormat,
    'key_version': keyVersion,
    'payload_bytes': payloadBytes,
    'message_bytes': messageBytes,
    'chip_capacity': chipCapacity,
    'consultations_kept': consultationsKept,
    'consultations_total': consultationsTotal,
    'vaccines_kept': vaccinesKept,
    'vaccines_total': vaccinesTotal,
    'written_at': writtenAt.toUtc().toIso8601String(),
  };

  /// The entry `POST /api/v1/patients/nfc-write-metrics` takes, built from a
  /// stored row. Only these fields leave the device: the local id and the sync
  /// bookkeeping stay, so the wire payload cannot drift into carrying more.
  static Map<String, Object?> apiEntryFromRow(Map<String, Object?> row) {
    final Object? at = row['written_at'];
    final DateTime? parsed = at is String ? DateTime.tryParse(at) : null;
    return <String, Object?>{
      'device_role': row['device_role'],
      'payload_format': row['payload_format'],
      'key_version': row['key_version'],
      'payload_bytes': row['payload_bytes'],
      'message_bytes': row['message_bytes'],
      'chip_capacity': row['chip_capacity'],
      'consultations_kept': row['consultations_kept'],
      'consultations_total': row['consultations_total'],
      'vaccines_kept': row['vaccines_kept'],
      'vaccines_total': row['vaccines_total'],
      // The server needs an offset: a naive value would be read as UTC.
      'written_at': (parsed?.toUtc() ?? DateTime.now().toUtc())
          .toIso8601String(),
    };
  }

  /// The key version a codec writes under, or the legacy one when it reports
  /// none (a write that succeeded always had one).
  static int keyVersionOf(int? writeKeyVersion) =>
      writeKeyVersion ?? kLegacyNfcKeyVersion;
}
