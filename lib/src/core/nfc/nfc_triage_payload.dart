// lib/src/core/nfc/nfc_triage_payload.dart
//
// Builds the minimal triage payload to write on the patient's NFC wristband.
// This payload must be as small as possible because it targets NTAG chips
// with limited capacity (180–924 bytes).
//
// Field keys are abbreviated to minimize CBOR size:
//   fn  = firstName         ln  = firstLastName
//   dob = dateOfBirth       sex = biologicalSex
//   bt  = bloodType         docT = documentType
//   docN = documentNumber   gPh = guardianPhone
//   gUid = guardian1 device_uid
//   g2Uid = guardian2 device_uid (optional)
//   chr = chronicConditions (semicolon-separated descriptions)
//   alg = allergies [{c: category, a: allergen, r: reaction}]
//   vid = VIDA code (when available from IHCE)

import '../../features/nfc/domain/patient_record.dart';

/// Builds the triage payload map from a full patient record.
///
/// This map is fed into [NfcPayloadCodec.encode] to produce the
/// encrypted bytes written to the patient's NFC wristband.
class NfcTriagePayload {
  NfcTriagePayload._();

  /// Builds the minimal triage map for the patient's NFC wristband.
  static Map<String, dynamic> buildPatientPayload({
    required PatientFullRecord record,
    String? vidaCode,
  }) {
    final pi = record.patientInfo;
    final gi = record.guardianInfo;
    final bg = record.backgroundHistory;

    final payload = <String, dynamic>{
      'fn': pi.firstName,
      'ln': pi.firstLastName,
      'dob': pi.dob,
      'sex': pi.biologicalSex,
      'bt': pi.bloodType ?? '',
      'docT': pi.identification.documentType,
      'docN': pi.identification.documentNumber,
    };

    // Guardian 1
    if (gi.phone.isNotEmpty) payload['gPh'] = gi.phone;
    if (gi.deviceUid != null && gi.deviceUid!.isNotEmpty) {
      payload['gUid'] = gi.deviceUid;
    }

    // Guardian 2
    final g2 = record.guardian2Info;
    if (g2 != null && g2.deviceUid != null && g2.deviceUid!.isNotEmpty) {
      payload['g2Uid'] = g2.deviceUid;
    }

    // Chronic conditions (abbreviated — join descriptions with semicolon)
    if (bg != null && bg.chronicConditions.isNotEmpty) {
      final chrStr = bg.chronicConditions
          .map((c) => c.chronicDescription)
          .where((d) => d.isNotEmpty)
          .join('; ');
      if (chrStr.isNotEmpty) payload['chr'] = chrStr;
    }

    // Allergies (compact format)
    if (record.allergies.isNotEmpty) {
      payload['alg'] = record.allergies.map((a) {
        final entry = <String, String>{};
        if (a.category.isNotEmpty) entry['c'] = a.category;
        if (a.allergen.isNotEmpty) entry['a'] = a.allergen;
        if (a.reaction != null && a.reaction!.isNotEmpty) {
          entry['r'] = a.reaction!;
        }
        return entry;
      }).toList();
    }

    // VIDA code (from IHCE, if available)
    if (vidaCode != null && vidaCode.isNotEmpty) {
      payload['vid'] = vidaCode;
    }

    return payload;
  }

  /// Reconstructs a human-readable triage summary from a decoded payload.
  ///
  /// Used when reading a patient's NFC wristband in emergency/triage mode.
  static TriageSummary fromPayload(Map<String, dynamic> payload) {
    final allergies = <TriageAllergy>[];
    final algList = payload['alg'];
    if (algList is List) {
      for (final a in algList) {
        if (a is Map) {
          allergies.add(TriageAllergy(
            category: a['c']?.toString() ?? '',
            allergen: a['a']?.toString() ?? '',
            reaction: a['r']?.toString() ?? '',
          ));
        }
      }
    }

    return TriageSummary(
      firstName: payload['fn']?.toString() ?? '',
      lastName: payload['ln']?.toString() ?? '',
      dob: payload['dob']?.toString() ?? '',
      biologicalSex: payload['sex']?.toString() ?? '',
      bloodType: payload['bt']?.toString() ?? '',
      documentType: payload['docT']?.toString() ?? '',
      documentNumber: payload['docN']?.toString() ?? '',
      guardianPhone: payload['gPh']?.toString() ?? '',
      guardianDeviceUid: payload['gUid']?.toString() ?? '',
      guardian2DeviceUid: payload['g2Uid']?.toString(),
      chronicConditions: payload['chr']?.toString() ?? '',
      allergies: allergies,
      vidaCode: payload['vid']?.toString(),
    );
  }
}

/// Read-only summary extracted from an NFC triage payload.
class TriageSummary {
  const TriageSummary({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.biologicalSex,
    required this.bloodType,
    required this.documentType,
    required this.documentNumber,
    required this.guardianPhone,
    required this.guardianDeviceUid,
    this.guardian2DeviceUid,
    required this.chronicConditions,
    required this.allergies,
    this.vidaCode,
  });

  final String firstName;
  final String lastName;
  final String dob;
  final String biologicalSex;
  final String bloodType;
  final String documentType;
  final String documentNumber;
  final String guardianPhone;
  final String guardianDeviceUid;
  final String? guardian2DeviceUid;
  final String chronicConditions;
  final List<TriageAllergy> allergies;
  final String? vidaCode;

  String get fullName => '$firstName $lastName';

  /// Whether 2FA scan matches either guardian.
  bool isGuardianMatch(String scannedUid) {
    if (guardianDeviceUid == scannedUid) return true;
    if (guardian2DeviceUid != null && guardian2DeviceUid == scannedUid) {
      return true;
    }
    return false;
  }
}

class TriageAllergy {
  const TriageAllergy({
    required this.category,
    required this.allergen,
    required this.reaction,
  });

  final String category;
  final String allergen;
  final String reaction;

  @override
  String toString() => '$category: $allergen → $reaction';
}
