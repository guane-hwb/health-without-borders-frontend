// lib/src/core/nfc/nfc_payload_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

import '../../features/nfc/domain/patient_record.dart';
import 'nfc_guardian_alias.dart';
import 'nfc_guardian_payload.dart';
import 'nfc_keyring.dart' show kLegacyNfcKeyVersion;
import 'nfc_payload_codec.dart';
import 'nfc_payload_format.dart';
import 'nfc_payload_v2.dart';
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

/// Given the usable payload budget (chip NDEF capacity minus record overhead),
/// returns the trimmed guardian payload that fits. In practice this is
/// [NfcGuardianPayload.buildWithinCapacity] with its record and estimator bound.
typedef GuardianFitBuilder = GuardianPayloadFit Function(int payloadBudget);

/// Binds a record and codec into a [GuardianFitBuilder] for
/// [NfcPayloadService.writeGuardianRecord].
///
/// Both the register wizard and the profile "update chips" flow need exactly
/// this; keeping it here means neither screen carries a copy, and the wiring is
/// unit-testable instead of only reachable by driving a full screen.
///
/// [format] must be the one the service writes in: it decides how a payload
/// is measured. Both default to [kNfcWriteFormat].
GuardianFitBuilder guardianFitBuilder({
  required PatientFullRecord record,
  required NfcPayloadCodec codec,
  NfcPayloadFormat format = kNfcWriteFormat,
}) {
  final int Function(Map<String, dynamic>) estimateSize =
      format == NfcPayloadFormat.v2
      ? (Map<String, dynamic> payload) => codec.sealedSize(
          NfcPayloadV2.plaintextSize(payload, NfcPayloadKind.guardian),
        )
      : codec.estimateSize;
  return (int budget) => NfcGuardianPayload.buildWithinCapacity(
    record: record,
    capacityBytes: budget,
    estimateSize: estimateSize,
  );
}

/// NDEF capacity Android reports for an NTAG215, the smaller of the two chips
/// ADR-004 supports. A guardian copy that does not fit here needs an NTAG216.
const int kNtag215NdefCapacity = 492;

/// The payload budget a guardian copy has on a chip whose NDEF capacity is
/// [ndefCapacity]: the capacity minus what the record adds around the payload
/// (its header and type string: the 28-character MIME type in format 1, the
/// 17-character external type in format 2).
///
/// The overhead is measured on a 256-byte payload. From that size on the record
/// stores its length in 4 bytes instead of 1, and a guardian copy is in
/// practice longer than 255 B; measuring an empty payload came out 3 B short.
/// A shorter copy just gets a budget 3 B on the safe side.
///
/// [NfcPayloadService.writeGuardianRecord] and the register wizard's check
/// before the tap both use this, so the two cannot disagree.
int guardianPayloadBudget(
  int ndefCapacity, {
  NfcPayloadFormat format = kNfcWriteFormat,
}) {
  const int probe = 256;
  final NdefRecord record = format == NfcPayloadFormat.v2
      ? buildExternalRecord(kHwbGuardianV2Type, Uint8List(probe))
      : NfcPayloadService.buildMimeRecord(
          kHwbGuardianMimeType,
          Uint8List(probe),
        );
  final int overhead =
      NdefMessage(records: <NdefRecord>[record]).byteLength - probe;
  return ndefCapacity - overhead;
}

/// MIME type used for HWB NFC payloads.
const String kHwbNdefMimeType = 'application/vnd.hwb.triage';

Uint8List chipBindingAad(String uid, String mimeType) {
  return Uint8List.fromList(
    utf8.encode('hwb-chip-binding|v1|${normalizeNfcUid(uid)}|$mimeType'),
  );
}

/// MIME type for the guardian card's bounded full-record payload.
/// A distinct type lets the reader tell a patient device apart from a
/// guardian card and pick the right reconstructor.
const String kHwbGuardianMimeType = 'application/vnd.hwb.guardian';

/// High-level NFC operations for reading/writing encrypted payloads.
///
/// Owns no radio state: every operation goes through [NfcTagSource], which
/// serialises callers and guarantees the future resolves.
class NfcPayloadService {
  /// Reads both payload formats; writes [writeFormat], which defaults to the
  /// build's [kNfcWriteFormat].
  NfcPayloadService({
    required this.codec,
    NfcTagSource? tagSource,
    this.writeFormat = kNfcWriteFormat,
  }) : _tagSource = tagSource ?? NfcSessionManager.instance;

  final NfcPayloadCodec codec;
  final NfcTagSource _tagSource;

  /// Format of every payload this service writes.
  final NfcPayloadFormat writeFormat;

  bool get _bindsToChip {
    final int? version = codec.writeKeyVersion;
    return version != null && version != kLegacyNfcKeyVersion;
  }

  Future<NfcDecodeResult?> _decodeFromChip(
    Uint8List payload,
    String uid,
    String mimeType,
  ) async {
    final NfcDecodeResult? bound = await codec.decodeDetailed(
      payload,
      extraAad: chipBindingAad(uid, mimeType),
    );
    if (bound != null) return bound;
    return codec.decodeDetailed(payload);
  }

  /// Opens a format 2 record: decrypts with the chip binding first and then
  /// without, as [_decodeFromChip] does, and decodes the plaintext. Null when
  /// no key opens it or it is not a valid format 2 payload.
  Future<NfcDecodeResult?> _decodeV2FromChip(
    Uint8List payload,
    String uid,
    NfcPayloadKind kind,
  ) async {
    final String type = _v2Type(kind);
    final NfcOpenResult? opened =
        await codec.open(payload, extraAad: chipBindingAad(uid, type)) ??
        await codec.open(payload);
    if (opened == null) return null;
    try {
      return NfcDecodeResult(
        data: NfcPayloadV2.decode(opened.plaintext, kind),
        keyVersion: opened.keyVersion,
        hadHeader: opened.hadHeader,
      );
    } on FormatException {
      return null;
    }
  }

  static String _v1Type(NfcPayloadKind kind) =>
      kind == NfcPayloadKind.triage ? kHwbNdefMimeType : kHwbGuardianMimeType;

  static String _v2Type(NfcPayloadKind kind) =>
      kind == NfcPayloadKind.triage ? kHwbTriageV2Type : kHwbGuardianV2Type;

  /// Whether [tag] carries a record of [kind], in either format.
  static bool _holds(HwbTag tag, NfcPayloadKind kind) =>
      _findRecordOf(tag, TypeNameFormat.external, _v2Type(kind)) != null ||
      _findRecord(tag, _v1Type(kind)) != null;

  /// The payload of [kind] on [tag], decoded, in whichever format it was
  /// written. Null when there is none or no key opens it.
  Future<NfcDecodeResult?> _readPayload(HwbTag tag, NfcPayloadKind kind) async {
    final Uint8List? v2 = _findRecordOf(
      tag,
      TypeNameFormat.external,
      _v2Type(kind),
    );
    if (v2 != null) return _decodeV2FromChip(v2, tag.uid, kind);
    final Uint8List? v1 = _findRecord(tag, _v1Type(kind));
    if (v1 != null) return _decodeFromChip(v1, tag.uid, _v1Type(kind));
    return null;
  }

  /// Record type this service writes for [kind].
  String _writeType(NfcPayloadKind kind) =>
      writeFormat == NfcPayloadFormat.v2 ? _v2Type(kind) : _v1Type(kind);

  /// The encrypted payload this service writes for [payload], bound to
  /// [bindUid] when given. Format 2 checks that the payload reads back exactly
  /// before anything is encrypted; when it would not, nothing is written.
  Future<Uint8List> _seal(
    Map<String, dynamic> payload,
    NfcPayloadKind kind,
    String? bindUid,
  ) async {
    final Uint8List? aad = bindUid == null
        ? null
        : chipBindingAad(bindUid, _writeType(kind));
    if (writeFormat == NfcPayloadFormat.v2) {
      final Uint8List plaintext;
      try {
        plaintext = NfcPayloadV2.encode(payload, kind);
      } on NfcPayloadV2Exception catch (e) {
        throw NfcWriteException(e.message);
      }
      return codec.seal(plaintext, extraAad: aad);
    }
    return codec.encode(payload, extraAad: aad);
  }

  /// The single record this service writes for [encrypted].
  NdefRecord _record(NfcPayloadKind kind, Uint8List encrypted) =>
      writeFormat == NfcPayloadFormat.v2
      ? buildExternalRecord(_writeType(kind), encrypted)
      : buildMimeRecord(_writeType(kind), encrypted);

  Future<NfcWriteResult> writeTriagePayload(
    Map<String, dynamic> triagePayload, {
    String? expectedUid,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) {
    return _writePayload(
      triagePayload,
      kind: NfcPayloadKind.triage,
      expectedUid: expectedUid,
      timeout: timeout,
      cancel: cancel,
      alertMessage: alertMessage,
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
    String? alertMessage,
  }) {
    return _writePayload(
      guardianPayload,
      kind: NfcPayloadKind.guardian,
      expectedUid: expectedUid,
      timeout: timeout,
      cancel: cancel,
      alertMessage: alertMessage,
    );
  }

  /// Writes a guardian record, fitting it to the chip's *actual* capacity.
  ///
  /// The old flow fit the payload against a hardcoded 4000-byte constant sized
  /// for a DESFire that was never bought, so on a real NTAG the payload was
  /// built too large and only failed at write() time. Here the fit is computed
  /// inside the tap, once [buildFit] is handed the chip's real NDEF capacity —
  /// minus the MIME record overhead, since that comes out of the same budget.
  ///
  /// [buildFit] is [NfcGuardianPayload.buildWithinCapacity] with the record and
  /// estimator already bound; it receives the usable payload budget and returns
  /// the trimmed fit. The resulting [GuardianPayloadFit] rides back on
  /// [NfcWriteResult.fit] so the UI can report any history that was dropped.
  ///
  /// Each minor has a guardian device of their own: it holds one copy, and
  /// offline it opens that copy. With [patientId], a chip that holds another
  /// patient's copy, or is a patient device, is refused with
  /// [NfcDeviceInUseException] before anything is written.
  Future<NfcWriteResult> writeGuardianRecord({
    required GuardianFitBuilder buildFit,
    String? expectedUid,
    String? patientId,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) {
    return _tagSource.withTag<NfcWriteResult>(
      (HwbTag tag) async {
        final uid = tag.uid;
        if (uid.isEmpty) {
          throw NfcWriteException('Could not read chip UID');
        }
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
        if (patientId != null) {
          await _refuseAnotherPatientsDevice(tag, uid, patientId);
        }

        // The record overhead comes out of maxSize; see
        // guardianPayloadBudget.
        final payloadBudget = guardianPayloadBudget(
          ndef.maxSize,
          format: writeFormat,
        );

        final fit = buildFit(payloadBudget);
        final encrypted = await _seal(
          fit.payload,
          NfcPayloadKind.guardian,
          _bindsToChip ? uid : null,
        );
        final message = NdefMessage(
          records: [_record(NfcPayloadKind.guardian, encrypted)],
        );

        final needed = message.byteLength;
        if (needed > ndef.maxSize) {
          // Even the demographic base does not fit — nothing to trim further.
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
          fit: fit,
        );
      },
      timeout: timeout,
      cancel: cancel,
      alertMessage: alertMessage,
    );
  }

  /// Shared NDEF write: encodes [payload], waits for a chip, optionally
  /// verifies its UID against [expectedUid], checks capacity, and writes one
  /// record of [kind] in [writeFormat].
  ///
  /// Throws [NfcUidMismatchException] if [expectedUid] is given and the tapped
  /// chip's UID differs, or [NfcWriteException] on any other failure.
  Future<NfcWriteResult> _writePayload(
    Map<String, dynamic> payload, {
    required NfcPayloadKind kind,
    String? expectedUid,
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    final bool bind = _bindsToChip;
    Uint8List? preEncrypted;
    NdefMessage? preMessage;

    if (!bind || (expectedUid != null && expectedUid.isNotEmpty)) {
      try {
        preEncrypted = await _seal(payload, kind, bind ? expectedUid! : null);
        preMessage = NdefMessage(records: [_record(kind, preEncrypted)]);
      } catch (_) {}
    }

    return _tagSource.withTag<NfcWriteResult>(
      (HwbTag tag) async {
        final uid = tag.uid;
        if (uid.isEmpty) {
          throw NfcWriteException('Could not read chip UID');
        }

        if (expectedUid != null &&
            expectedUid.isNotEmpty &&
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

        final Uint8List encrypted =
            preEncrypted ?? await _seal(payload, kind, bind ? uid : null);

        final NdefMessage message =
            preMessage ?? NdefMessage(records: [_record(kind, encrypted)]);

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
      alertMessage: alertMessage,
    );
  }

  /// Reads and decrypts a triage payload from an NFC chip.
  Future<NfcReadResult> readTriagePayload({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) {
    return _tagSource.withTag<NfcReadResult>(
      (HwbTag tag) async {
        final uid = tag.uid;
        if (uid.isEmpty) {
          throw NfcReadException('Could not read chip UID');
        }

        if (!_holds(tag, NfcPayloadKind.triage)) {
          return NfcReadResult(uid: uid, triage: null);
        }

        final decoded = await _readPayload(tag, NfcPayloadKind.triage);
        return NfcReadResult(
          uid: uid,
          triage: decoded != null
              ? NfcTriagePayload.fromPayload(decoded.data)
              : null,
          keyVersion: decoded?.keyVersion,
          hadHeader: decoded?.hadHeader,
        );
      },
      timeout: timeout,
      cancel: cancel,
      alertMessage: alertMessage,
    );
  }

  /// Reads any HWB chip — patient device or guardian card — in one tap.
  ///
  /// Returns the UID plus whichever payload was found, decoded and ready to
  /// reconstruct a record. If both records are present the guardian one wins
  /// (it is a superset). Returns [HwbChipKind.none] for a blank or non-HWB
  /// chip (the UID is still populated when readable). Used for offline reads.
  Future<HwbChipReadResult> readHwbChip({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) {
    return _tagSource.withTag<HwbChipReadResult>(
      (HwbTag tag) async {
        final uid = tag.uid;

        if (_holds(tag, NfcPayloadKind.guardian)) {
          final decoded = await _readPayload(tag, NfcPayloadKind.guardian);
          return HwbChipReadResult(
            uid: uid,
            kind: decoded != null ? HwbChipKind.guardian : HwbChipKind.none,
            guardianRecord: decoded?.data,
            keyVersion: decoded?.keyVersion,
            hadHeader: decoded?.hadHeader,
          );
        }

        if (_holds(tag, NfcPayloadKind.triage)) {
          final decoded = await _readPayload(tag, NfcPayloadKind.triage);
          final triage = decoded != null
              ? NfcTriagePayload.fromPayload(decoded.data)
              : null;
          return HwbChipReadResult(
            uid: uid,
            kind: triage != null ? HwbChipKind.triage : HwbChipKind.none,
            triage: triage,
            keyVersion: decoded?.keyVersion,
            hadHeader: decoded?.hadHeader,
          );
        }

        return HwbChipReadResult(uid: uid, kind: HwbChipKind.none);
      },
      timeout: timeout,
      cancel: cancel,
      alertMessage: alertMessage,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Throws [NfcDeviceInUseException] when [tag] is a patient device, or a
  /// guardian device holding the copy of a patient other than [patientId].
  /// A blank chip, this patient's own copy, or data no key in the ring can
  /// open (nothing to compare) is let through.
  Future<void> _refuseAnotherPatientsDevice(
    HwbTag tag,
    String uid,
    String patientId,
  ) async {
    if (_holds(tag, NfcPayloadKind.guardian)) {
      final decoded = await _readPayload(tag, NfcPayloadKind.guardian);
      final String? owner = decoded == null
          ? null
          : guardianCopyPatientId(decoded.data);
      if (owner != null && owner.isNotEmpty && owner != patientId) {
        throw NfcDeviceInUseException(patientDevice: false);
      }
      return;
    }
    if (_holds(tag, NfcPayloadKind.triage) &&
        await _readPayload(tag, NfcPayloadKind.triage) != null) {
      throw NfcDeviceInUseException(patientDevice: true);
    }
  }

  /// The `patientId` of a decoded guardian copy, aliased or not.
  static String? guardianCopyPatientId(Map<String, dynamic> decoded) {
    final Object? id = unaliasGuardianPayload(decoded)['patientId'];
    return id is String ? id : null;
  }

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
  static Uint8List? _findRecord(HwbTag tag, String mimeType) =>
      _findRecordOf(tag, TypeNameFormat.media, mimeType);

  /// The payload of the first record on [tag] with [format] and [type].
  static Uint8List? _findRecordOf(
    HwbTag tag,
    TypeNameFormat format,
    String type,
  ) {
    final cached = tag.ndef?.cachedMessage;
    if (cached == null) return null;
    for (final record in cached.records) {
      if (record.typeNameFormat == format &&
          String.fromCharCodes(record.type) == type) {
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
    this.fit,
  });

  final String uid;

  /// Encrypted payload size.
  final int bytesWritten;

  /// Size of the whole NDEF message actually written — payload plus record
  /// overhead. This is what is measured against [chipCapacity].
  final int messageBytes;

  final int chipCapacity;

  /// For guardian writes: how the record was fitted to the chip, including any
  /// history that was trimmed. Null for triage writes.
  final GuardianPayloadFit? fit;

  double get utilizationPercent => (messageBytes / chipCapacity) * 100;
}

class NfcReadResult {
  const NfcReadResult({
    required this.uid,
    required this.triage,
    this.keyVersion,
    this.hadHeader,
  });
  final String uid;
  final TriageSummary? triage;

  /// Key version that decrypted this chip, or null when nothing was decoded.
  final int? keyVersion;

  /// Whether the payload carried a version header (version 1 or later).
  final bool? hadHeader;
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
    this.keyVersion,
    this.hadHeader,
  });

  final String uid;
  final HwbChipKind kind;
  final TriageSummary? triage;
  final Map<String, dynamic>? guardianRecord;

  /// Key version that decrypted this chip, or null when nothing was decoded.
  ///
  /// Recorded so a rotation can be measured instead of guessed: retiring a
  /// version while chips are still on it makes them unreadable offline.
  final int? keyVersion;

  /// Whether the payload carried a version header (version 1 or later).
  final bool? hadHeader;
}

// ── Exceptions ──────────────────────────────────────────────────────────────

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
  String toString() {
    final bool isNtag213 = chipCapacity <= 180;
    final bool isNtag215 = chipCapacity > 180 && chipCapacity <= 504;
    final String hint = isNtag213
        ? ' (NTAG213 detectado: utilice dispositivos NTAG215 o NTAG216).'
        : (isNtag215
              ? ' (Capacidad NTAG215 insuficiente: utilice un dispositivo NTAG216, de mayor capacidad).'
              : '.');
    return 'NDEF message needs $messageBytes bytes ($payloadBytes of payload plus '
        '${messageBytes - payloadBytes} of record overhead) but the chip holds '
        '$chipCapacity — $overflowBytes over$hint';
  }
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

/// Thrown when a chip about to become a guardian device already belongs to
/// another patient: a patient device, or the guardian device of another minor.
/// Every minor needs a guardian device of their own.
class NfcDeviceInUseException implements Exception {
  NfcDeviceInUseException({required this.patientDevice});

  /// True for a patient device; false for another minor's guardian device.
  final bool patientDevice;

  @override
  String toString() => patientDevice
      ? 'The chip is a patient device.'
      : "The chip holds another patient's guardian copy.";
}

class NfcReadException implements Exception {
  NfcReadException(this.message);
  final String message;
  @override
  String toString() => message;
}
