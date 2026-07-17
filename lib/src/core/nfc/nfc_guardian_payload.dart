// lib/src/core/nfc/nfc_guardian_payload.dart
//
// Builds the bounded full-record payload written to the guardian's NFC card
// (DESFire EV3 4K) and reconstructs a PatientFullRecord from the chips when
// there is no connectivity.
//
// Unlike the patient triage payload (which targets tiny NTAG chips and uses
// abbreviated keys), the guardian payload keeps the full PatientFullRecord
// JSON shape. PatientFullRecord.fromJson is fully tolerant — every field has
// a default — so reconstruction is a direct fromJson with no hand-written
// field mapping, and it stays correct as the model evolves.
//
// The payload is the same map produced by PatientFullRecord.toJson() with
// three adjustments:
//   1. medicalHistory is bounded to the most recent N consultations.
//   2. vaccinationRecord is bounded to the most recent M vaccines.
//   3. Guardian consent signatures (PNG base64) are stripped — they can be
//      kilobytes and are not needed offline.
//
// Identity/linkage fields (patientId, patient device_uid, guardian device_uids)
// are already part of toJson(), so the reconstructed record knows who it is
// and which patient wristband it pairs with for 2FA.

import '../../features/nfc/domain/patient_record.dart';
import 'nfc_triage_payload.dart';

/// Builds and reconstructs the guardian NFC payload (bounded full record).
class NfcGuardianPayload {
  NfcGuardianPayload._();

  /// Default number of most-recent consultations stored on the guardian card.
  static const int kDefaultMaxConsultations = 3;

  /// Default number of most-recent vaccines stored on the guardian card.
  static const int kDefaultMaxVaccines = 3;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Builds the guardian payload map from a full patient record, bounding the
  /// dynamic history to the most recent [maxConsultations] and [maxVaccines].
  ///
  /// The returned map is fed into [NfcPayloadCodec.encode] to produce the
  /// encrypted bytes written to the guardian's card. It does NOT mutate
  /// [record].
  static Map<String, dynamic> buildGuardianPayload({
    required PatientFullRecord record,
    int maxConsultations = kDefaultMaxConsultations,
    int maxVaccines = kDefaultMaxVaccines,
  }) {
    // toJson() returns a fresh map (and fresh nested maps) every call, so the
    // mutations below never touch the original record.
    final map = record.toJson();

    final consultations = _mostRecent<MedicalHistoryItem>(
      record.medicalHistory,
      (MedicalHistoryItem m) => m.startDateTime,
      maxConsultations,
    );
    final vaccines = _mostRecent<VaccinationRecordItem>(
      record.vaccinationRecord,
      (VaccinationRecordItem v) => v.date,
      maxVaccines,
    );

    map['medicalHistory'] =
        consultations.map((MedicalHistoryItem m) => m.toJson()).toList();
    map['vaccinationRecord'] =
        vaccines.map((VaccinationRecordItem v) => v.toJson()).toList();

    _stripConsentSignature(map['guardianInfo']);
    _stripConsentSignature(map['guardian2Info']);

    return map;
  }

  /// Builds the largest guardian payload that fits within [capacityBytes].
  ///
  /// Starts from [maxConsultations]/[maxVaccines] and, if the estimated
  /// encoded size exceeds the card capacity, drops the oldest entries one at a
  /// time (alternating between the two histories) until it fits or there is
  /// nothing left to drop.
  ///
  /// [estimateSize] should be [NfcPayloadCodec.estimateSize], which accounts
  /// for CBOR + DEFLATE + the 28-byte AES-GCM overhead.
  static GuardianPayloadFit buildWithinCapacity({
    required PatientFullRecord record,
    required int capacityBytes,
    required int Function(Map<String, dynamic>) estimateSize,
    int maxConsultations = kDefaultMaxConsultations,
    int maxVaccines = kDefaultMaxVaccines,
  }) {
    var n = maxConsultations < 0 ? 0 : maxConsultations;
    var m = maxVaccines < 0 ? 0 : maxVaccines;

    // Never ask for more than the record actually holds, so the trim loop does
    // not waste iterations on empty slots.
    if (n > record.medicalHistory.length) n = record.medicalHistory.length;
    if (m > record.vaccinationRecord.length) m = record.vaccinationRecord.length;

    var payload = buildGuardianPayload(
      record: record,
      maxConsultations: n,
      maxVaccines: m,
    );
    var size = estimateSize(payload);

    while (size > capacityBytes && (n > 0 || m > 0)) {
      // Drop from whichever history is currently larger; alternate on ties so
      // neither one is starved unnecessarily.
      if (n >= m && n > 0) {
        n--;
      } else if (m > 0) {
        m--;
      } else {
        n--;
      }
      payload = buildGuardianPayload(
        record: record,
        maxConsultations: n,
        maxVaccines: m,
      );
      size = estimateSize(payload);
    }

    return GuardianPayloadFit(
      payload: payload,
      includedConsultations: n,
      includedVaccines: m,
      estimatedBytes: size,
      fits: size <= capacityBytes,
    );
  }

  // ---------------------------------------------------------------------------
  // Reconstruct
  // ---------------------------------------------------------------------------

  /// Reconstructs a full record from a decoded guardian payload.
  ///
  /// The guardian card is a superset of the patient wristband, so when it is
  /// available this is the authoritative offline source.
  static PatientFullRecord reconstructFromGuardian(
    Map<String, dynamic> decoded,
  ) {
    return PatientFullRecord.fromJson(decoded);
  }

  /// Reconstructs a partial record from the patient wristband triage only.
  ///
  /// Used when the guardian card is unavailable (e.g. an adult patient with no
  /// guardian, or the guardian is not present). Fills the demographic and
  /// critical fields the triage carries; dynamic history is left empty.
  static PatientFullRecord reconstructFromTriage(
    TriageSummary triage, {
    String deviceUid = '',
  }) {
    final chronic = triage.chronicConditions
        .split(';')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .map((String d) => ChronicConditionItem(chronicDescription: d))
        .toList();

    final allergies = triage.allergies
        .map(
          (TriageAllergy a) => AllergyInfo(
            category: a.category.isEmpty ? '06' : a.category,
            allergen: a.allergen,
            reaction: a.reaction.isEmpty ? null : a.reaction,
          ),
        )
        .toList();

    final hasGuardian2 = triage.guardian2DeviceUid != null &&
        triage.guardian2DeviceUid!.isNotEmpty;

    return PatientFullRecord(
      patientId: '',
      deviceUid: deviceUid,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType:
              triage.documentType.isEmpty ? 'MS' : triage.documentType,
          documentNumber: triage.documentNumber,
        ),
        firstLastName: triage.lastName,
        firstName: triage.firstName,
        dob: triage.dob,
        biologicalSex:
            triage.biologicalSex.isEmpty ? 'I' : triage.biologicalSex,
        address: Address(city: '', state: ''),
        bloodType: triage.bloodType.isEmpty ? null : triage.bloodType,
      ),
      guardianInfo: GuardianInfo(
        name: '',
        relationship: '',
        phone: triage.guardianPhone,
        deviceUid: triage.guardianDeviceUid.isEmpty
            ? null
            : triage.guardianDeviceUid,
      ),
      guardian2Info: hasGuardian2
          ? GuardianInfo(
              name: '',
              relationship: '',
              phone: '',
              deviceUid: triage.guardian2DeviceUid,
            )
          : null,
      backgroundHistory:
          chronic.isEmpty ? null : BackgroundHistory(chronicConditions: chronic),
      allergies: allergies,
    );
  }

  /// Reconstructs the best available record from whatever chips were read.
  ///
  /// Prefers the guardian card (full record) when present; otherwise falls back
  /// to the patient triage (partial record). Throws if neither is provided.
  static PatientFullRecord reconstruct({
    TriageSummary? triage,
    Map<String, dynamic>? guardianRecord,
    String patientDeviceUid = '',
  }) {
    if (guardianRecord != null) {
      return reconstructFromGuardian(guardianRecord);
    }
    if (triage != null) {
      return reconstructFromTriage(triage, deviceUid: patientDeviceUid);
    }
    throw ArgumentError(
      'reconstruct requires at least one source: triage or guardianRecord.',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns up to [limit] items with the most recent [dateOf] value, newest
  /// first. ISO 8601 and YYYY-MM-DD strings sort lexicographically in
  /// chronological order; empty/unparseable values sort as oldest.
  static List<T> _mostRecent<T>(
    List<T> items,
    String Function(T) dateOf,
    int limit,
  ) {
    if (limit <= 0 || items.isEmpty) return <T>[];
    final sorted = List<T>.from(items)
      ..sort((T a, T b) => dateOf(b).compareTo(dateOf(a)));
    return sorted.take(limit).toList();
  }

  /// Removes a guardian's consent signature (PNG base64) from its serialized
  /// map, if present. Accepts the raw `guardianInfo`/`guardian2Info` value.
  static void _stripConsentSignature(Object? guardianMap) {
    if (guardianMap is Map && guardianMap['consent'] is Map) {
      (guardianMap['consent'] as Map).remove('signatureBase64');
    }
  }
}

/// Result of [NfcGuardianPayload.buildWithinCapacity]: the payload that fit
/// plus how much of the history it could keep.
class GuardianPayloadFit {
  const GuardianPayloadFit({
    required this.payload,
    required this.includedConsultations,
    required this.includedVaccines,
    required this.estimatedBytes,
    required this.fits,
  });

  /// The encoded-ready map (already bounded and signature-stripped).
  final Map<String, dynamic> payload;

  /// Number of consultations kept after capacity trimming.
  final int includedConsultations;

  /// Number of vaccines kept after capacity trimming.
  final int includedVaccines;

  /// Estimated encoded size in bytes (CBOR + DEFLATE + AES-GCM overhead).
  final int estimatedBytes;

  /// Whether the payload fits within the requested capacity. When false, even
  /// the demographic base exceeds the card and the write should be rejected.
  final bool fits;
}
