// test/unit/register_draft_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';

void main() {
  group('RegisterDraft', () {
    test('inicializa todos los campos por defecto correctamente', () {
      final draft = RegisterDraft();

      expect(draft.deviceUid, isNull);
      expect(draft.documentType, 'TI');
      expect(draft.documentNumber, '');
      expect(draft.firstName, '');
      expect(draft.secondName, isNull);
      expect(draft.firstLastName, '');
      expect(draft.secondLastName, isNull);
      expect(draft.dob, isNull);
      expect(draft.biologicalSex, 'F');
      expect(draft.genderIdentity, isNull);
      expect(draft.nationalityCode, 'COL');
      expect(draft.nationalityName, 'Colombia');
      expect(draft.ethnicity, isNull);
      expect(draft.ethnicCommunity, isNull);
      expect(draft.disabilityCategory, isNull);
      expect(draft.bloodType, isNull);
      expect(draft.isBloodTypeCertified, isFalse);
      expect(draft.weight, isNull);
      expect(draft.height, isNull);
      expect(draft.muac, isNull);
      expect(draft.street, isNull);
      expect(draft.addressCity, '');
      expect(draft.cityCode, isNull);
      expect(draft.addressState, '');
      expect(draft.zone, isNull);
      expect(draft.guardianName, isNull);
      expect(draft.guardianRelationship, isNull);
      expect(draft.guardianRelationshipOther, isNull);
      expect(draft.guardianPhone, isNull);
      expect(draft.guardianDeviceUid, isNull);
      expect(draft.guardianDocType, isNull);
      expect(draft.guardianDocNumber, isNull);
      expect(draft.guardianAuthAccepted, isNull);
      expect(draft.guardianEmail, isNull);
      expect(draft.guardianSignatureBase64, isNull);
      expect(draft.guardianSignatureStrokes, isEmpty);
      expect(draft.guardian2Name, isNull);
      expect(draft.guardian2Relationship, isNull);
      expect(draft.guardian2RelationshipOther, isNull);
      expect(draft.guardian2Phone, isNull);
      expect(draft.guardian2DeviceUid, isNull);
      expect(draft.guardian2DocType, isNull);
      expect(draft.guardian2DocNumber, isNull);
      expect(draft.guardian2AuthAccepted, isNull);
      expect(draft.guardian2Email, isNull);
      expect(draft.guardian2SignatureBase64, isNull);
      expect(draft.guardian2SignatureStrokes, isEmpty);
      expect(draft.chronicConditions, isEmpty);
      expect(draft.personalHistory, isNull);
      expect(draft.familyHistory, isEmpty);
      expect(draft.medications, isEmpty);
      expect(draft.allergies, isEmpty);
    });

    group('toRecord()', () {
      test(
        'construye un PatientFullRecord mínimo con valores por defecto y nulos',
        () {
          final draft = RegisterDraft()
            ..isBloodTypeCertified = true; // sin bloodType debe quedar en false

          final record = draft.toRecord();

          expect(record.patientId, isNotEmpty);
          expect(record.deviceUid, '');
          expect(record.patientInfo.identification.documentType, 'TI');
          expect(record.patientInfo.identification.documentNumber, '');
          expect(record.patientInfo.firstName, '');
          expect(record.patientInfo.secondName, isNull);
          expect(record.patientInfo.firstLastName, '');
          expect(record.patientInfo.secondLastName, isNull);
          expect(record.patientInfo.dob, '');
          expect(record.patientInfo.nationalityCode, 'COL');
          expect(record.patientInfo.nationalityName, 'Colombia');
          expect(record.patientInfo.biologicalSex, 'F');
          expect(record.patientInfo.genderIdentity, isNull);
          expect(record.patientInfo.ethnicity, isNull);
          expect(record.patientInfo.ethnicCommunity, isNull);
          expect(record.patientInfo.disabilityCategory, isNull);
          expect(record.patientInfo.address.street, isNull);
          expect(record.patientInfo.address.city, '');
          expect(record.patientInfo.address.cityCode, isNull);
          expect(record.patientInfo.address.state, '');
          expect(record.patientInfo.address.country, 'COL');
          expect(record.patientInfo.address.countryName, 'Colombia');
          expect(record.patientInfo.address.zone, isNull);
          expect(record.patientInfo.bloodType, isNull);
          expect(record.patientInfo.isBloodTypeCertified, isFalse);
          expect(record.patientInfo.weight, isNull);
          expect(record.patientInfo.height, isNull);
          expect(record.patientInfo.muac, isNull);

          expect(record.guardianInfo.name, '');
          expect(record.guardianInfo.relationship, '01');
          expect(record.guardianInfo.relationshipOther, isNull);
          expect(record.guardianInfo.phone, '');
          expect(record.guardianInfo.deviceUid, isNull);
          expect(record.guardianInfo.documentType, isNull);
          expect(record.guardianInfo.documentNumber, isNull);
          expect(record.guardianInfo.consent, isNull);

          expect(record.guardian2Info, isNull);
          expect(record.backgroundHistory!.chronicConditions, isEmpty);
          expect(record.backgroundHistory!.personalHistory, isNull);
          expect(record.backgroundHistory!.familyHistory, isEmpty);
          expect(record.backgroundHistory!.medications, isEmpty);
          expect(record.allergies, isEmpty);
          expect(record.medicalHistory, isEmpty);
          expect(record.vaccinationRecord, isEmpty);
        },
      );

      test(
        'mapea todos los campos completos, formateo de fecha, consentimientos y segundo cuidador',
        () {
          final condition = ChronicConditionItem(chronicDescription: 'Asma');
          final family = FamilyHistoryItem(
            relationship: 'Madre',
            conditionDescription: 'Hipertensión',
          );
          final medication = MedicationStatementItem(
            medicationName: 'Salbutamol',
            dosage: '100 mcg',
          );
          final allergy = AllergyInfo(
            category: '01',
            allergen: 'Penicilina',
            reaction: 'Urticaria',
          );

          final draft = RegisterDraft()
            ..deviceUid = '04:A1:B2:C3'
            ..documentType = 'RC'
            ..documentNumber = '1098765432'
            ..firstName = 'Valentina'
            ..secondName = 'Sofía'
            ..firstLastName = 'Rodríguez'
            ..secondLastName = 'Pérez'
            ..dob = DateTime(2018, 4, 7)
            ..biologicalSex = 'F'
            ..genderIdentity = 'Femenino'
            ..nationalityCode = 'VEN'
            ..nationalityName = 'Venezuela'
            ..ethnicity = '01'
            ..ethnicCommunity = 'Wayuu'
            ..disabilityCategory = '02'
            ..bloodType = 'O+'
            ..isBloodTypeCertified = true
            ..weight = 18.5
            ..height = 105.0
            ..muac = 16.2
            ..street = 'Calle 10 # 5-20'
            ..addressCity = 'Cúcuta'
            ..cityCode = '54001'
            ..addressState = 'Norte de Santander'
            ..zone = 'U'
            ..guardianName = 'María Pérez'
            ..guardianRelationship = '05'
            ..guardianRelationshipOther = 'Tía materna'
            ..guardianPhone = '3001234567'
            ..guardianDeviceUid = '04:11:22:33'
            ..guardianDocType = 'CC'
            ..guardianDocNumber = '60123456'
            ..guardianAuthAccepted = true
            ..guardianEmail = 'maria@correo.com'
            ..guardianSignatureBase64 = 'base64-sig-1'
            ..guardianSignatureStrokes = <List<Offset>>[
              <Offset>[const Offset(0, 0), const Offset(10, 10)],
            ]
            ..guardian2Name = 'Carlos Rodríguez'
            ..guardian2Relationship = '02'
            ..guardian2RelationshipOther = 'Ignorado en guardian2'
            ..guardian2Phone = '3107654321'
            ..guardian2DeviceUid = '04:44:55:66'
            ..guardian2DocType = 'CC'
            ..guardian2DocNumber = '13456789'
            ..guardian2AuthAccepted = true
            ..guardian2Email = 'carlos@correo.com'
            ..guardian2SignatureBase64 = 'base64-sig-2'
            ..guardian2SignatureStrokes = <List<Offset>>[
              <Offset>[const Offset(5, 5)],
            ]
            ..chronicConditions = <ChronicConditionItem>[condition]
            ..personalHistory = 'Hospitalización en 2021'
            ..familyHistory = <FamilyHistoryItem>[family]
            ..medications = <MedicationStatementItem>[medication]
            ..allergies = <AllergyInfo>[allergy];

          final record = draft.toRecord();

          expect(record.patientId, isNotEmpty);
          expect(record.deviceUid, '04:A1:B2:C3');
          expect(record.patientInfo.identification.documentType, 'RC');
          expect(
            record.patientInfo.identification.documentNumber,
            '1098765432',
          );
          expect(record.patientInfo.firstName, 'Valentina');
          expect(record.patientInfo.secondName, 'Sofía');
          expect(record.patientInfo.firstLastName, 'Rodríguez');
          expect(record.patientInfo.secondLastName, 'Pérez');
          expect(record.patientInfo.dob, '2018-04-07');
          expect(record.patientInfo.biologicalSex, 'F');
          expect(record.patientInfo.genderIdentity, 'Femenino');
          expect(record.patientInfo.nationalityCode, 'VEN');
          expect(record.patientInfo.nationalityName, 'Venezuela');
          expect(record.patientInfo.ethnicity, '01');
          expect(record.patientInfo.ethnicCommunity, 'Wayuu');
          expect(record.patientInfo.disabilityCategory, '02');
          expect(record.patientInfo.bloodType, 'O+');
          expect(record.patientInfo.isBloodTypeCertified, isTrue);
          expect(record.patientInfo.weight, 18.5);
          expect(record.patientInfo.height, 105.0);
          expect(record.patientInfo.muac, 16.2);
          expect(record.patientInfo.address.street, 'Calle 10 # 5-20');
          expect(record.patientInfo.address.city, 'Cúcuta');
          expect(record.patientInfo.address.cityCode, '54001');
          expect(record.patientInfo.address.state, 'Norte de Santander');
          expect(record.patientInfo.address.zone, 'U');

          expect(record.guardianInfo.name, 'María Pérez');
          expect(record.guardianInfo.relationship, '05');
          expect(record.guardianInfo.relationshipOther, 'Tía materna');
          expect(record.guardianInfo.phone, '3001234567');
          expect(record.guardianInfo.deviceUid, '04:11:22:33');
          expect(record.guardianInfo.documentType, 'CC');
          expect(record.guardianInfo.documentNumber, '60123456');
          expect(record.guardianInfo.consent, isNotNull);
          expect(record.guardianInfo.consent!.accepted, isTrue);
          expect(record.guardianInfo.consent!.acceptedAt, isNotEmpty);
          expect(record.guardianInfo.consent!.email, 'maria@correo.com');
          expect(record.guardianInfo.consent!.signatureBase64, 'base64-sig-1');

          expect(record.guardian2Info, isNotNull);
          expect(record.guardian2Info!.name, 'Carlos Rodríguez');
          expect(record.guardian2Info!.relationship, '02');
          expect(record.guardian2Info!.phone, '3107654321');
          expect(record.guardian2Info!.deviceUid, '04:44:55:66');
          expect(record.guardian2Info!.documentType, 'CC');
          expect(record.guardian2Info!.documentNumber, '13456789');
          expect(record.guardian2Info!.consent, isNotNull);
          expect(record.guardian2Info!.consent!.accepted, isTrue);
          expect(record.guardian2Info!.consent!.acceptedAt, isNotEmpty);
          expect(record.guardian2Info!.consent!.email, 'carlos@correo.com');
          expect(
            record.guardian2Info!.consent!.signatureBase64,
            'base64-sig-2',
          );

          expect(record.backgroundHistory!.chronicConditions, [condition]);
          expect(
            record.backgroundHistory!.personalHistory,
            'Hospitalización en 2021',
          );
          expect(record.backgroundHistory!.familyHistory, [family]);
          expect(record.backgroundHistory!.medications, [medication]);
          expect(record.allergies, [allergy]);
        },
      );

      test('ignora guardianRelationshipOther cuando relationship no es 05', () {
        final draft = RegisterDraft()
          ..guardianName = 'María Pérez'
          ..guardianRelationship = '01'
          ..guardianRelationshipOther = 'Texto que no debe pasar'
          ..guardianAuthAccepted = false;

        final record = draft.toRecord();

        expect(record.guardianInfo.relationship, '01');
        expect(record.guardianInfo.relationshipOther, isNull);
        expect(record.guardianInfo.consent, isNull);
      });

      test(
        'ignora guardian2Info cuando guardian2Name está vacío y deja consent null si no fue aceptado',
        () {
          final emptyNameDraft = RegisterDraft()..guardian2Name = '';
          expect(emptyNameDraft.toRecord().guardian2Info, isNull);

          final withoutConsentDraft = RegisterDraft()
            ..guardian2Name = 'Pedro López'
            ..guardian2AuthAccepted = false;
          final record = withoutConsentDraft.toRecord();

          expect(record.guardian2Info, isNotNull);
          expect(record.guardian2Info!.name, 'Pedro López');
          expect(record.guardian2Info!.relationship, '01');
          expect(record.guardian2Info!.phone, '');
          expect(record.guardian2Info!.consent, isNull);
        },
      );

      test('genera un patientId UUID distinto en cada invocación', () {
        final draft = RegisterDraft();
        final firstId = draft.toRecord().patientId;
        final secondId = draft.toRecord().patientId;

        expect(firstId, isNot(equals(secondId)));
      });
    });
  });
}
