// test/unit/profile_nfc_actions_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

void main() {
  group('ProfileNfcActions – Logic & Model Verification', () {
    test('ReassignTarget enum values match expectations', () {
      expect(ReassignTarget.values.length, 3);
      expect(ReassignTarget.patient, isNotNull);
      expect(ReassignTarget.guardian1, isNotNull);
      expect(ReassignTarget.guardian2, isNotNull);
    });

    test(
      'PatientFullRecord copyWith correctly updates patient deviceUid for reassign',
      () {
        final record = PatientFullRecord(
          patientId: 'p-1',
          deviceUid: 'OLD-UID',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'CC',
              documentNumber: '123',
            ),
            firstName: 'Juan',
            firstLastName: 'Pérez',
            dob: '2000-01-01',
            biologicalSex: 'M',
            address: Address(city: 'Bogotá', state: 'Bogotá'),
          ),
          guardianInfo: GuardianInfo(
            name: 'G1',
            relationship: '01',
            phone: '123',
          ),
        );

        final updated = record.copyWith(deviceUid: 'NEW-UID');

        expect(updated.deviceUid, equals('NEW-UID'));
        expect(updated.patientId, equals('p-1'));
      },
    );

    test(
      'PatientFullRecord copyWith correctly updates guardian1 deviceUid for reassign',
      () {
        final record = PatientFullRecord(
          patientId: 'p-1',
          deviceUid: 'P-UID',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'CC',
              documentNumber: '123',
            ),
            firstName: 'Juan',
            firstLastName: 'Pérez',
            dob: '2000-01-01',
            biologicalSex: 'M',
            address: Address(city: 'Bogotá', state: 'Bogotá'),
          ),
          guardianInfo: GuardianInfo(
            name: 'G1',
            relationship: '01',
            phone: '123',
            deviceUid: 'G1-OLD',
          ),
        );

        final updated = record.copyWith(
          guardianInfo: record.guardianInfo.copyWith(deviceUid: 'G1-NEW'),
        );

        expect(updated.guardianInfo.deviceUid, equals('G1-NEW'));
        expect(updated.deviceUid, equals('P-UID'));
      },
    );

    test(
      'PatientFullRecord copyWith correctly updates guardian2 deviceUid for reassign',
      () {
        final record = PatientFullRecord(
          patientId: 'p-1',
          deviceUid: 'P-UID',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'CC',
              documentNumber: '123',
            ),
            firstName: 'Juan',
            firstLastName: 'Pérez',
            dob: '2000-01-01',
            biologicalSex: 'M',
            address: Address(city: 'Bogotá', state: 'Bogotá'),
          ),
          guardianInfo: GuardianInfo(
            name: 'G1',
            relationship: '01',
            phone: '123',
          ),
          guardian2Info: GuardianInfo(
            name: 'G2',
            relationship: '02',
            phone: '456',
            deviceUid: 'G2-OLD',
          ),
        );

        final g2 = record.guardian2Info!;
        final updated = record.copyWith(
          guardian2Info: g2.copyWith(deviceUid: 'G2-NEW'),
        );

        expect(updated.guardian2Info?.deviceUid, equals('G2-NEW'));
      },
    );
  });
}
