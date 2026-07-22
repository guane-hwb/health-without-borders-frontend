// lib/src/core/nfc/nfc_payload_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

import 'nfc_payload_codec.dart';
import 'nfc_session_manager.dart';
import 'nfc_triage_payload.dart';

export 'nfc_session_manager.dart'
    show
        NfcBusyException,
        NfcCancelToken,
        NfcCancelledException,
        NfcDisabledException,
        NfcInterruptedException,
        NfcNotAvailableException,
        NfcSessionException,
        NfcTagAlreadyPresentException,
        NfcTimeoutException;

/// MIME type used for HWB NFC payloads.
const String kHwbNdefMimeType = 'application/vnd.hwb.triage';

/// MIME type for the guardian card's bounded full-record payload.
/// A distinct type lets the reader tell a patient wristband apart from a
/// guardian card and pick the right reconstructor.
const String kHwbGuardianMimeType = 'application/vnd.hwb.guardian';

/// High-level NFC operations for reading/writing encrypted payloads.
///
/// Owns no radio state: every operation goes through [NfcTagSource], which
/// serialises callers and guarantees the future resolves.
class NfcPayloadService {
  NfcPayloadService({required this.codec, NfcTagSource? tagSource})
    : _tagSource = tagSource ?? NfcSessionManager.instance;

  final NfcPayloadCodec codec;
  final NfcTagSource _tagSource;

  Future<NfcWriteResult> writeTriagePayload(
    Map<String, dynamic> triagePayload, {
    String? expectedUid,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) {
    return _writePayload(
      triagePayload,
      mimeType: kHwbNdefMimeType,
      expectedUid: expectedUid,
      timeout: timeout,
      cancel: cancel,
    );
  }

  /// Writes the guardian's bounded full-record payload to the guardian card.
  ///
  /// The map should be produced by NfcGuardianPayload.buildWithinCapacity so it
  /// already fits the card. Pass [expectedUid] to refuse writing unless the
  /// tapped card matches the guardian UID recorded for this patient.
  Future<NfcWriteResult> writeGuardianPayload(
    Map<String, dynamic> guardianPayload, {
    String? expectedUid,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) {
    return _writePayload(
      guardianPayload,
      mimeType: kHwbGuardianMimeType,
      expectedUid: expectedUid,
      timeout: timeout,
      cancel: cancel,
    );
  }

  /// Shared NDEF write: encodes [payload], waits for a chip, optionally
  /// verifies its UID against [expectedUid], checks capacity, and writes one
  /// MIME record of type [mimeType].
  ///
  /// Throws [NfcUidMismatchException] if [expectedUid] is given and the tapped
  /// chip's UID differs, or [NfcWriteException] on any other failure.
  Future<NfcWriteResult> _writePayload(
    Map<String, dynamic> payload, {
    required String mimeType,
    String? expectedUid,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) async {
    // Encode and frame before asking for the tap: CBOR + DEFLATE + AES-GCM off
    // the critical path keeps the chip in the field for as little as possible.
    final encrypted = await codec.encode(payload);
    final message = NdefMessage(
      records: [buildMimeRecord(mimeType, encrypted)],
    );

    return _tagSource.withTag<NfcWriteResult>(
      (HwbTag tag) async {
        final uid = tag.uid;
        if (uid.isEmpty) {
          throw NfcWriteException('Could not read chip UID');
        }

        // Safeguard: never seal one person's data onto a different chip.
        if (expectedUid != null &&
            normalizeNfcUid(uid) != normalizeNfcUid(expectedUid)) {
          throw NfcUidMismatchException(expected: expectedUid, actual: uid);
        }

        final ndef = tag.ndef;
        if (ndef == null) {
          throw NfcWriteException(
            'Chip is not NDEF-formatted. Use an NTAG (patient) or an '
            'NDEF-formatted DESFire (guardian).',
          );
        }

        if (!ndef.isWritable) {
          throw NfcWriteException('Chip is read-only or locked');
        }

        // Measure the whole NDEF message, not the bare payload. `maxSize` is the
        // budget for the message, and the MIME record's header plus its 28-byte
        // type string come out of that budget too. Comparing the payload alone
        // let a payload that was a few dozen bytes under the limit pass this
        // check and then fail inside write().
        final needed = message.byteLength;
        if (needed > ndef.maxSize) {
          throw NfcPayloadTooLargeException(
            messageBytes: needed,
            payloadBytes: encrypted.length,
            chipCapacity: ndef.maxSize,
          );
        }

        await ndef.write(message);

        return NfcWriteResult(
          uid: uid,
          bytesWritten: encrypted.length,
          messageBytes: needed,
          chipCapacity: ndef.maxSize,
        );
      },
      timeout: timeout,
      cancel: cancel,
    );
  }

  /// Reads and decrypts a triage payload from an NFC chip.
  Future<NfcReadResult> readTriagePayload({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) {
    return _tagSource.withTag<NfcReadResult>(
      (HwbTag tag) async {
        final uid = tag.uid;
        if (uid.isEmpty) {
          throw NfcReadException('Could not read chip UID');
        }

        final payload = _findRecord(tag, kHwbNdefMimeType);
        if (payload == null) {
          return NfcReadResult(uid: uid, triage: null);
        }

        final decoded = await codec.decode(payload);
        return NfcReadResult(
          uid: uid,
          triage: decoded != null
              ? NfcTriagePayload.fromPayload(decoded)
              : null,
        );
      },
      timeout: timeout,
      cancel: cancel,
    );
  }

  /// Reads any HWB chip — patient wristband or guardian card — in one tap.
  ///
  /// Returns the UID plus whichever payload was found, decoded and ready to
  /// reconstruct a record. If both records are present the guardian one wins
  /// (it is a superset). Returns [HwbChipKind.none] for a blank or non-HWB
  /// chip (the UID is still populated when readable). Used for offline reads.
  Future<HwbChipReadResult> readHwbChip({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) {
    return _tagSource.withTag<HwbChipReadResult>(
      (HwbTag tag) async {
        final uid = tag.uid;

        final guardianPayload = _findRecord(tag, kHwbGuardianMimeType);
        if (guardianPayload != null) {
          final decoded = await codec.decode(guardianPayload);
          return HwbChipReadResult(
            uid: uid,
            kind: decoded != null ? HwbChipKind.guardian : HwbChipKind.none,
            guardianRecord: decoded,
          );
        }

        final triagePayload = _findRecord(tag, kHwbNdefMimeType);
        if (triagePayload != null) {
          final decoded = await codec.decode(triagePayload);
          final triage = decoded != null
              ? NfcTriagePayload.fromPayload(decoded)
              : null;
          return HwbChipReadResult(
            uid: uid,
            kind: triage != null ? HwbChipKind.triage : HwbChipKind.none,
            triage: triage,
          );
        }

        return HwbChipReadResult(uid: uid, kind: HwbChipKind.none);
      },
      timeout: timeout,
      cancel: cancel,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Builds the single MIME record HWB writes.
  ///
  /// v4 dropped `NdefRecord.createMime`, so the record is assembled by hand.
  static NdefRecord buildMimeRecord(String mimeType, Uint8List payload) {
    return NdefRecord(
      typeNameFormat: TypeNameFormat.media,
      type: Uint8List.fromList(ascii.encode(mimeType)),
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// The payload of the first MIME record on [tag] whose type is [mimeType],
  /// or null when the chip is blank, not NDEF-formatted, or carries no such
  /// record.
  static Uint8List? _findRecord(HwbTag tag, String mimeType) {
    final cached = tag.ndef?.cachedMessage;
    if (cached == null) return null;
    for (final record in cached.records) {
      if (record.typeNameFormat == TypeNameFormat.media &&
          String.fromCharCodes(record.type) == mimeType) {
        return record.payload;
      }
    }
    return null;
  }
}

class NfcWriteResult {
  const NfcWriteResult({
    required this.uid,
    required this.bytesWritten,
    required this.messageBytes,
    required this.chipCapacity,
  });

  final String uid;

  /// Encrypted payload size.
  final int bytesWritten;

  /// Size of the whole NDEF message actually written — payload plus record
  /// overhead. This is what is measured against [chipCapacity].
  final int messageBytes;

  final int chipCapacity;

  double get utilizationPercent => (messageBytes / chipCapacity) * 100;
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
//
// NfcNotAvailableException is re-exported from nfc_session_types.dart above; it
// used to be declared here *and* in nfc_service_mobile.dart as two unrelated
// classes with the same name, which any file importing both could not name.

class NfcWriteException implements Exception {
  NfcWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The framed NDEF message does not fit the chip.
///
/// Carries the numbers so the UI and the logs can say which chip is too small
/// and by how much, instead of only "write failed".
class NfcPayloadTooLargeException implements Exception {
  NfcPayloadTooLargeException({
    required this.messageBytes,
    required this.payloadBytes,
    required this.chipCapacity,
  });

  /// Whole NDEF message size, payload plus record overhead.
  final int messageBytes;

  /// Encrypted payload size on its own.
  final int payloadBytes;

  /// What the chip reports it can hold.
  final int chipCapacity;

  int get overflowBytes => messageBytes - chipCapacity;

  @override
  String toString() =>
      'NDEF message needs $messageBytes bytes ($payloadBytes of payload plus '
      '${messageBytes - payloadBytes} of record overhead) but the chip holds '
      '$chipCapacity — $overflowBytes over.';
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
