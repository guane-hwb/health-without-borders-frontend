// test/unit/nfc_triage_payload_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ---------------------------------------------------------------------------
// Test-double helpers
// ---------------------------------------------------------------------------

PatientFullRecord _fullRecord({
  String firstName = 'Ana',
  String firstLastName = 'García',
  String dob = '2015-03-10',
  String biologicalSex = 'F',
  String? bloodType = 'O+',
  bool isBloodTypeCertified = false,
  String documentType = 'DNI',
  String documentNumber = '12345678',
  String guardianName = 'Guardian One',
  String guardianPhone = '+50688887777',
  String? guardianDeviceUid = 'device-uid-001',
  GuardianInfo? guardian2,
  List<ChronicConditionItem>? chronicConditions,
  List<AllergyInfo> allergies = const [],
}) {
  return PatientFullRecord(
    patientId: 'patient-001',
    deviceUid: 'device-patient-001',
    patientInfo: PatientInfo(
      firstName: firstName,
      firstLastName: firstLastName,
      dob: dob,
      biologicalSex: biologicalSex,
      bloodType: bloodType,
      isBloodTypeCertified: isBloodTypeCertified,
      identification: PatientIdentification(
        documentType: documentType,
        documentNumber: documentNumber,
      ),
      address: Address(city: 'Bogotá', state: 'DC'),
    ),
    guardianInfo: GuardianInfo(
      name: guardianName,
      relationship: '01',
      phone: guardianPhone,
      deviceUid: guardianDeviceUid,
    ),
    guardian2Info: guardian2,
    backgroundHistory: chronicConditions != null
        ? BackgroundHistory(chronicConditions: chronicConditions)
        : null,
    allergies: allergies,
  );
}

// ---------------------------------------------------------------------------
// NfcTriagePayload.buildPatientPayload
// ---------------------------------------------------------------------------

void main() {
  group('NfcTriagePayload.buildPatientPayload —', () {
    // -----------------------------------------------------------------------
    // Core fields (always present)
    // -----------------------------------------------------------------------
    test('includes mandatory patient fields in the payload', () {
      final record = _fullRecord(bloodType: null);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['fn'], 'Ana');
      expect(payload['ln'], 'García');
      expect(payload['dob'], '2015-03-10');
      expect(payload['sex'], 'F');
      expect(payload['bt'], '');
      expect(payload['docT'], 'DNI');
      expect(payload['docN'], '12345678');
    });

    test('includes bloodType when provided', () {
      final record = _fullRecord(bloodType: 'A-');
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['bt'], 'A-');
    });

    test('writes btC only for a certified blood type', () {
      final certified = NfcTriagePayload.buildPatientPayload(
        record: _fullRecord(bloodType: 'A-', isBloodTypeCertified: true),
      );
      final reported = NfcTriagePayload.buildPatientPayload(
        record: _fullRecord(bloodType: 'A-'),
      );

      expect(certified['btC'], isTrue);
      expect(reported.containsKey('btC'), isFalse);
    });

    // -----------------------------------------------------------------------
    // Guardian 1
    // -----------------------------------------------------------------------
    test('includes guardian phone when not empty', () {
      final record = _fullRecord(guardianPhone: '+50611112222');
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['gPh'], '+50611112222');
    });

    test('omits guardian phone when empty', () {
      final record = _fullRecord(guardianPhone: '');
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('gPh'), isFalse);
    });

    test('includes guardian device UID when present and not empty', () {
      final record = _fullRecord(guardianDeviceUid: 'uid-abc');
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['gUid'], 'uid-abc');
    });

    test('omits guardian device UID when null', () {
      final record = _fullRecord(guardianDeviceUid: null);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('gUid'), isFalse);
    });

    test('omits guardian device UID when empty string', () {
      final record = _fullRecord(guardianDeviceUid: '');
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('gUid'), isFalse);
    });

    // -----------------------------------------------------------------------
    // Guardian 2
    // -----------------------------------------------------------------------
    test('includes guardian2 UID when present and not empty', () {
      final record = _fullRecord(
        guardian2: GuardianInfo(
          name: '',
          relationship: '',
          phone: '',
          deviceUid: 'uid-g2',
        ),
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['g2Uid'], 'uid-g2');
    });

    test('omits guardian2 when record.guardian2Info is null', () {
      final record = _fullRecord(guardian2: null);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('g2Uid'), isFalse);
    });

    test('omits guardian2 UID when guardian2 deviceUid is null', () {
      final record = _fullRecord(
        guardian2: GuardianInfo(
          name: '',
          relationship: '',
          phone: '',
          deviceUid: null,
        ),
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('g2Uid'), isFalse);
    });

    test('omits guardian2 UID when guardian2 deviceUid is empty string', () {
      final record = _fullRecord(
        guardian2: GuardianInfo(
          name: '',
          relationship: '',
          phone: '',
          deviceUid: '',
        ),
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('g2Uid'), isFalse);
    });

    // -----------------------------------------------------------------------
    // Chronic conditions
    // -----------------------------------------------------------------------
    test('joins chronic condition descriptions with semicolon', () {
      final record = _fullRecord(
        chronicConditions: [
          ChronicConditionItem(chronicDescription: 'Asthma'),
          ChronicConditionItem(chronicDescription: 'Diabetes'),
        ],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['chr'], 'Asthma; Diabetes');
    });

    test('filters out empty chronic condition descriptions', () {
      final record = _fullRecord(
        chronicConditions: [
          ChronicConditionItem(chronicDescription: ''),
          ChronicConditionItem(chronicDescription: 'Epilepsy'),
        ],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload['chr'], 'Epilepsy');
    });

    test('omits chr key when all chronic descriptions are empty', () {
      final record = _fullRecord(
        chronicConditions: [ChronicConditionItem(chronicDescription: '')],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('chr'), isFalse);
    });

    test('omits chr key when chronicConditions list is empty', () {
      final record = _fullRecord(chronicConditions: []);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('chr'), isFalse);
    });

    test('omits chr key when backgroundHistory is null', () {
      final record = _fullRecord(chronicConditions: null);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('chr'), isFalse);
    });

    // -----------------------------------------------------------------------
    // Allergies
    // -----------------------------------------------------------------------
    test('encodes allergies with category, allergen and reaction', () {
      final record = _fullRecord(
        allergies: [
          AllergyInfo(
            category: 'Food',
            allergen: 'Peanuts',
            reaction: 'Anaphylaxis',
          ),
        ],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      final algList = payload['alg'] as List;
      expect(algList.length, 1);
      expect(algList[0], {'c': 'Food', 'a': 'Peanuts', 'r': 'Anaphylaxis'});
    });

    test('omits optional allergy sub-fields when empty', () {
      final record = _fullRecord(
        allergies: [AllergyInfo(category: '', allergen: '', reaction: null)],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      final algList = payload['alg'] as List;
      expect(algList[0], <String, String>{});
    });

    test('omits reaction sub-field when null', () {
      final record = _fullRecord(
        allergies: [
          AllergyInfo(category: 'Drug', allergen: 'Penicillin', reaction: null),
        ],
      );
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      final algList = payload['alg'] as List;
      expect((algList[0] as Map).containsKey('r'), isFalse);
    });

    test('omits alg key when allergies list is empty', () {
      final record = _fullRecord(allergies: []);
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('alg'), isFalse);
    });

    // -----------------------------------------------------------------------
    // VIDA code
    // -----------------------------------------------------------------------
    test('includes vida code when provided', () {
      final record = _fullRecord();
      final payload = NfcTriagePayload.buildPatientPayload(
        record: record,
        vidaCode: 'VID-00123',
      );

      expect(payload['vid'], 'VID-00123');
    });

    test('omits vida code when null', () {
      final record = _fullRecord();
      final payload = NfcTriagePayload.buildPatientPayload(record: record);

      expect(payload.containsKey('vid'), isFalse);
    });

    test('omits vida code when empty string', () {
      final record = _fullRecord();
      final payload = NfcTriagePayload.buildPatientPayload(
        record: record,
        vidaCode: '',
      );

      expect(payload.containsKey('vid'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // NfcTriagePayload.fromPayload
  // -------------------------------------------------------------------------
  group('NfcTriagePayload.fromPayload —', () {
    final Map<String, dynamic> fullPayload = {
      'fn': 'Ana',
      'ln': 'García',
      'dob': '2015-03-10',
      'sex': 'F',
      'bt': 'O+',
      'docT': 'DNI',
      'docN': '12345678',
      'gPh': '+50688887777',
      'gUid': 'device-uid-001',
      'g2Uid': 'device-uid-002',
      'chr': 'Asthma; Diabetes',
      'alg': [
        {'c': 'Food', 'a': 'Peanuts', 'r': 'Anaphylaxis'},
        {'c': 'Drug', 'a': 'Penicillin'},
      ],
      'vid': 'VID-00123',
    };

    test('reads btC as a certified blood type', () {
      final summary = NfcTriagePayload.fromPayload(<String, dynamic>{
        ...fullPayload,
        'btC': true,
      });

      expect(summary.bloodTypeCertified, isTrue);
    });

    test('anything but btC: true reads as not certified', () {
      for (final Object? value in <Object?>[null, false, 'true', 1]) {
        final payload = <String, dynamic>{...fullPayload};
        if (value != null) payload['btC'] = value;

        expect(
          NfcTriagePayload.fromPayload(payload).bloodTypeCertified,
          isFalse,
          reason: 'btC = $value',
        );
      }
    });

    test('maps all fields to TriageSummary correctly', () {
      final summary = NfcTriagePayload.fromPayload(fullPayload);

      expect(summary.firstName, 'Ana');
      expect(summary.lastName, 'García');
      expect(summary.dob, '2015-03-10');
      expect(summary.biologicalSex, 'F');
      expect(summary.bloodType, 'O+');
      expect(summary.documentType, 'DNI');
      expect(summary.documentNumber, '12345678');
      expect(summary.guardianPhone, '+50688887777');
      expect(summary.guardianDeviceUid, 'device-uid-001');
      expect(summary.guardian2DeviceUid, 'device-uid-002');
      expect(summary.chronicConditions, 'Asthma; Diabetes');
      expect(summary.vidaCode, 'VID-00123');
    });

    test('parses allergy list including entry without reaction key', () {
      final summary = NfcTriagePayload.fromPayload(fullPayload);

      expect(summary.allergies.length, 2);
      expect(summary.allergies[0].category, 'Food');
      expect(summary.allergies[0].allergen, 'Peanuts');
      expect(summary.allergies[0].reaction, 'Anaphylaxis');
      expect(summary.allergies[1].reaction, '');
    });

    test('returns empty strings when optional string fields are absent', () {
      final summary = NfcTriagePayload.fromPayload(<String, dynamic>{});

      expect(summary.firstName, '');
      expect(summary.lastName, '');
      expect(summary.dob, '');
      expect(summary.biologicalSex, '');
      expect(summary.bloodType, '');
      expect(summary.documentType, '');
      expect(summary.documentNumber, '');
      expect(summary.guardianPhone, '');
      expect(summary.guardianDeviceUid, '');
      expect(summary.guardian2DeviceUid, null);
      expect(summary.chronicConditions, '');
      expect(summary.vidaCode, null);
      expect(summary.allergies, isEmpty);
      expect(summary.bloodTypeCertified, isFalse);
    });

    test('ignores non-Map entries inside alg list', () {
      final payload = <String, dynamic>{
        'alg': ['not-a-map', 42, null],
      };
      final summary = NfcTriagePayload.fromPayload(payload);

      expect(summary.allergies, isEmpty);
    });

    test('handles alg field that is not a List gracefully', () {
      final payload = <String, dynamic>{'alg': 'bad-value'};
      final summary = NfcTriagePayload.fromPayload(payload);

      expect(summary.allergies, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Blood-type certification, written and read back through the chip codec
  // -------------------------------------------------------------------------
  group('blood-type certification on the patient device —', () {
    final codec = NfcPayloadCodec.fromKeyring(
      keyring: NfcKeyring.single('ab' * 32),
    );

    Future<PatientFullRecord> writeAndRead(PatientFullRecord record) async {
      final bytes = await codec.encode(
        NfcTriagePayload.buildPatientPayload(record: record),
      );
      final decoded = await codec.decode(bytes);
      return NfcGuardianPayload.reconstructFromTriage(
        NfcTriagePayload.fromPayload(decoded!),
      );
    }

    test('a certified blood type is still certified after the read', () async {
      final rebuilt = await writeAndRead(
        _fullRecord(bloodType: 'B+', isBloodTypeCertified: true),
      );

      expect(rebuilt.patientInfo.bloodType, 'B+');
      expect(rebuilt.patientInfo.isBloodTypeCertified, isTrue);
    });

    test('a reported blood type stays reported', () async {
      final rebuilt = await writeAndRead(_fullRecord(bloodType: 'B+'));

      expect(rebuilt.patientInfo.bloodType, 'B+');
      expect(rebuilt.patientInfo.isBloodTypeCertified, isFalse);
    });

    test('no blood type means nothing to certify', () {
      const triage = TriageSummary(
        firstName: 'Ana',
        lastName: 'García',
        dob: '2015-03-10',
        biologicalSex: 'F',
        bloodType: '',
        bloodTypeCertified: true,
        documentType: 'DNI',
        documentNumber: '12345678',
        guardianPhone: '',
        guardianDeviceUid: '',
        chronicConditions: '',
        allergies: <TriageAllergy>[],
      );

      final rebuilt = NfcGuardianPayload.reconstructFromTriage(triage);

      expect(rebuilt.patientInfo.bloodType, isNull);
      expect(rebuilt.patientInfo.isBloodTypeCertified, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TriageSummary
  // -------------------------------------------------------------------------
  group('TriageSummary —', () {
    TriageSummary buildSummary({
      String guardianDeviceUid = 'uid-g1',
      String? guardian2DeviceUid,
    }) => TriageSummary(
      firstName: 'Ana',
      lastName: 'García',
      dob: '2015-03-10',
      biologicalSex: 'F',
      bloodType: 'O+',
      documentType: 'DNI',
      documentNumber: '12345678',
      guardianPhone: '+50688887777',
      guardianDeviceUid: guardianDeviceUid,
      guardian2DeviceUid: guardian2DeviceUid,
      chronicConditions: '',
      allergies: [],
    );

    test('fullName concatenates firstName and lastName', () {
      final summary = buildSummary();
      expect(summary.fullName, 'Ana García');
    });

    test('isGuardianMatch returns true for guardian 1 UID', () {
      final summary = buildSummary(guardianDeviceUid: 'uid-g1');
      expect(summary.isGuardianMatch('uid-g1'), isTrue);
    });

    test('isGuardianMatch returns true for guardian 2 UID', () {
      final summary = buildSummary(
        guardianDeviceUid: 'uid-g1',
        guardian2DeviceUid: 'uid-g2',
      );
      expect(summary.isGuardianMatch('uid-g2'), isTrue);
    });

    test('isGuardianMatch returns false for unknown UID', () {
      final summary = buildSummary(guardianDeviceUid: 'uid-g1');
      expect(summary.isGuardianMatch('uid-unknown'), isFalse);
    });

    test(
      'isGuardianMatch returns false when guardian2DeviceUid is null and UID does not match g1',
      () {
        final summary = buildSummary(
          guardianDeviceUid: 'uid-g1',
          guardian2DeviceUid: null,
        );
        expect(summary.isGuardianMatch('uid-g2'), isFalse);
      },
    );
  });

  // -------------------------------------------------------------------------
  // TriageAllergy
  // -------------------------------------------------------------------------
  group('TriageAllergy —', () {
    test('toString returns "category: allergen → reaction"', () {
      const allergy = TriageAllergy(
        category: 'Food',
        allergen: 'Peanuts',
        reaction: 'Anaphylaxis',
      );
      expect(allergy.toString(), 'Food: Peanuts → Anaphylaxis');
    });
  });
}
