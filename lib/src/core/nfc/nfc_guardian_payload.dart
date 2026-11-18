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
// and which patient device it pairs with for 2FA.

import '../../features/nfc/domain/patient_record.dart';
import 'nfc_guardian_alias.dart';
import 'nfc_triage_payload.dart';

/// Builds and reconstructs the guardian NFC payload (bounded full record).
abstract final class NfcGuardianPayload {
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

    map['medicalHistory'] = consultations
        .map((MedicalHistoryItem m) => _withoutAiMetadata(m.toJson()))
        .toList();
    map['vaccinationRecord'] = vaccines
        .map((VaccinationRecordItem v) => v.toJson())
        .toList();

    _stripConsentSignature(map['guardianInfo']);
    _stripConsentSignature(map['guardian2Info']);

    return map;
  }

  /// Builds the largest guardian payload that fits within [capacityBytes].
  ///
  /// Two steps:
  ///
  /// 1. **Trim.** Starts from [maxConsultations]/[maxVaccines] and, while the
  ///    estimated encoded size exceeds the card capacity, drops the oldest
  ///    entry of one history at a time, alternating between the two (a
  ///    consultation first when both hold the same number), until it fits or
  ///    there is nothing left to drop.
  /// 2. **Give back.** Once it fits, the history that was *not* cut last gets
  ///    back, one at a time, the entries it lost while they still fit.
  ///
  /// Step 2 exists because the trim has to keep dropping vaccines in step with
  /// consultations until the first combination that fits, and a consultation
  /// is several times larger than a vaccine: without it, a card with room for
  /// three vaccines was written with one. After step 2 no entry is left out
  /// while there is room for it: adding the next consultation or the next
  /// vaccine to the result would not fit. Entries stay the most recent ones of
  /// each history, so the partial-device notice still reads true.
  ///
  /// [estimateSize] should be [NfcPayloadCodec.estimateSize], which accounts
  /// for CBOR + DEFLATE + the 28-byte AES-GCM overhead. It is called once per
  /// combination tried and never twice for the same one.
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
    if (n > record.medicalHistory.length) {
      n = record.medicalHistory.length;
    }
    if (m > record.vaccinationRecord.length) {
      m = record.vaccinationRecord.length;
    }
    final int maxN = n;
    final int maxM = m;

    // The payload is built with the full, readable shape, but what actually
    // gets written (and must fit) is the key-aliased version. Measure that, so
    // the loops reflect the real on-chip size and do not over-trim. It is
    // carried aliased: reconstructFromGuardian un-aliases on read.
    Map<String, dynamic> aliased(int consultations, int vaccines) =>
        aliasGuardianPayload(
          buildGuardianPayload(
            record: record,
            maxConsultations: consultations,
            maxVaccines: vaccines,
          ),
        );

    var payload = aliased(n, m);
    var size = estimateSize(payload);

    // Step 1: trim, alternating between the two histories.
    var consultationCutLast = false;
    var vaccineCutLast = false;
    while (size > capacityBytes && (n > 0 || m > 0)) {
      consultationCutLast = n >= m && n > 0;
      vaccineCutLast = !consultationCutLast;
      if (consultationCutLast) {
        n--;
      } else {
        m--;
      }
      payload = aliased(n, m);
      size = estimateSize(payload);
    }

    // Step 2: give back to the other history what still fits. The history cut
    // last cannot grow: one more of its entries is the combination the trim
    // just left because it did not fit.
    if (size <= capacityBytes) {
      while (consultationCutLast && m < maxM) {
        final Map<String, dynamic> candidate = aliased(n, m + 1);
        final int candidateSize = estimateSize(candidate);
        if (candidateSize > capacityBytes) break;
        m++;
        payload = candidate;
        size = candidateSize;
      }
      while (vaccineCutLast && n < maxN) {
        final Map<String, dynamic> candidate = aliased(n + 1, m);
        final int candidateSize = estimateSize(candidate);
        if (candidateSize > capacityBytes) break;
        n++;
        payload = candidate;
        size = candidateSize;
      }
    }

    return GuardianPayloadFit(
      // The aliased payload: this is what will be written, and its size is
      // what `estimatedBytes` reflects.
      payload: payload,
      includedConsultations: n,
      includedVaccines: m,
      totalConsultations: record.medicalHistory.length,
      totalVaccines: record.vaccinationRecord.length,
      estimatedBytes: size,
      fits: size <= capacityBytes,
    );
  }

  // ---------------------------------------------------------------------------
  // Reconstruct
  // ---------------------------------------------------------------------------

  /// Reconstructs a full record from a decoded guardian payload.
  ///
  /// The guardian card is a superset of the patient device, so when it is
  /// available this is the authoritative offline source.
  static PatientFullRecord reconstructFromGuardian(
    Map<String, dynamic> decoded,
  ) {
    // Expand short keys back to the full shape. A card written before aliasing
    // (no schema marker) is returned unchanged, so older chips keep working.
    return PatientFullRecord.fromJson(unaliasGuardianPayload(decoded));
  }

  /// Reconstructs a partial record from the patient device triage only.
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

    final hasGuardian2 =
        triage.guardian2DeviceUid != null &&
        triage.guardian2DeviceUid!.isNotEmpty;

    return PatientFullRecord(
      patientId: '',
      deviceUid: deviceUid,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: triage.documentType.isEmpty
              ? 'MS'
              : triage.documentType,
          documentNumber: triage.documentNumber,
        ),
        firstLastName: triage.lastName,
        firstName: triage.firstName,
        dob: triage.dob,
        biologicalSex: triage.biologicalSex.isEmpty
            ? 'I'
            : triage.biologicalSex,
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
      backgroundHistory: chronic.isEmpty
          ? null
          : BackgroundHistory(chronicConditions: chronic),
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

  /// Drops the AI model name and timestamp from each diagnosis of a
  /// serialized consultation. They are audit metadata the server keeps; on a
  /// card with a few hundred bytes they would push consultations off it. The
  /// `source` stays: it is what tells a reader offline that a diagnosis is an
  /// AI suggestion.
  static Map<String, dynamic> _withoutAiMetadata(Map<String, dynamic> visit) {
    final Object? diagnoses = visit['diagnosis'];
    if (diagnoses is List) {
      for (final Object? d in diagnoses) {
        if (d is Map) {
          d
            ..remove('model')
            ..remove('generatedAt');
        }
      }
    }
    return visit;
  }

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
    required this.totalConsultations,
    required this.totalVaccines,
    required this.estimatedBytes,
    required this.fits,
  });

  /// The encoded-ready map (already bounded and signature-stripped).
  final Map<String, dynamic> payload;

  /// Number of consultations kept after capacity trimming.
  final int includedConsultations;

  /// Number of vaccines kept after capacity trimming.
  final int includedVaccines;

  /// Total consultations in the source record, before trimming.
  final int totalConsultations;

  /// Total vaccines in the source record, before trimming.
  final int totalVaccines;

  /// Estimated encoded size in bytes (CBOR + DEFLATE + AES-GCM overhead).
  final int estimatedBytes;

  /// Whether the payload fits within the requested capacity. When false, even
  /// the demographic base exceeds the card and the write should be rejected.
  final bool fits;

  /// Consultations that did not fit and were left off the card.
  int get droppedConsultations => totalConsultations - includedConsultations;

  /// Vaccines that did not fit and were left off the card.
  int get droppedVaccines => totalVaccines - includedVaccines;

  /// Whether any history was trimmed to make the record fit. When true the card
  /// holds a partial record and the UI should say so.
  bool get isPartial => droppedConsultations > 0 || droppedVaccines > 0;
}
