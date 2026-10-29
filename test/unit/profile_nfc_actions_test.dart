// test/unit/profile_nfc_actions_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_nfc_actions.dart';
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

    test(
      'guardian2Info nulo en ReassignTarget.guardian2 retorna el registro original sin cambios',
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
          guardian2Info: null,
        );

        final g2 = record.guardian2Info;
        final updated = g2 == null
            ? record
            : record.copyWith(guardian2Info: g2.copyWith(deviceUid: 'G2-NEW'));

        expect(updated.guardian2Info, isNull);
        expect(updated.deviceUid, equals('P-UID'));
      },
    );
  });

  group('devicesStaleAfterReassign', () {
    ({bool patient, bool guardian}) stale(
      List<ReassignTarget> done, {
      bool guardianDevice = true,
      bool twoGuardianDevices = false,
    }) => devicesStaleAfterReassign(
      done: done,
      hasGuardianDevice: guardianDevice,
      hasTwoGuardianDevices: twoGuardianDevices,
    );

    test('nuevo dispositivo del paciente: quedan los de los cuidadores', () {
      expect(stale([ReassignTarget.patient]), (patient: false, guardian: true));
    });

    test('nuevo dispositivo del paciente sin cuidadores: nada queda', () {
      expect(stale([ReassignTarget.patient], guardianDevice: false), (
        patient: false,
        guardian: false,
      ));
    });

    test('nuevo dispositivo del único cuidador: queda el del paciente', () {
      expect(stale([ReassignTarget.guardian1]), (
        patient: true,
        guardian: false,
      ));
    });

    test('con dos cuidadores, también el del otro cuidador', () {
      expect(stale([ReassignTarget.guardian2], twoGuardianDevices: true), (
        patient: true,
        guardian: true,
      ));
    });

    test('el del paciente grabado después del cuidador ya lo nombra', () {
      expect(stale([ReassignTarget.guardian1, ReassignTarget.patient]), (
        patient: false,
        guardian: true,
      ));
    });

    test('el del paciente grabado antes del cuidador sigue desactualizado', () {
      expect(stale([ReassignTarget.patient, ReassignTarget.guardian1]), (
        patient: true,
        guardian: true,
      ));
    });

    test('sin reasignaciones, nada queda', () {
      expect(stale([]), (patient: false, guardian: false));
    });
  });

  group('devicesReplacedByReassign', () {
    PatientFullRecord record({
      String patient = 'P-OLD',
      String? guardian1 = 'G1-OLD',
      String? guardian2,
    }) => PatientFullRecord(
      patientId: 'p-1',
      deviceUid: patient,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123',
        ),
        firstName: 'Juan',
        firstLastName: 'Pérez',
        dob: '2000-01-01',
        biologicalSex: 'M',
        address: Address(city: 'Bogotá', state: 'DC'),
      ),
      guardianInfo: GuardianInfo(
        name: 'Ana',
        relationship: '01',
        phone: '3000000000',
        deviceUid: guardian1,
      ),
      guardian2Info: guardian2 == null
          ? null
          : GuardianInfo(
              name: 'Luis',
              relationship: '02',
              phone: '3000000001',
              deviceUid: guardian2,
            ),
    );

    test('devuelve los UID que cambiaron, en cualquier ranura', () {
      expect(
        devicesReplacedByReassign(
          before: record(guardian2: 'G2-OLD'),
          after: record(patient: 'P-NEW', guardian2: 'G2-NEW'),
        ),
        <String>['P-OLD', 'G2-OLD'],
      );
      expect(
        devicesReplacedByReassign(
          before: record(),
          after: record(guardian1: 'G1-NEW'),
        ),
        <String>['G1-OLD'],
      );
    });

    test('sin cambios, o con una ranura que estaba vacía, nada', () {
      expect(
        devicesReplacedByReassign(before: record(), after: record()),
        isEmpty,
      );
      expect(
        devicesReplacedByReassign(
          before: record(guardian1: null),
          after: record(guardian1: 'G1-NEW'),
        ),
        isEmpty,
      );
      expect(
        devicesReplacedByReassign(
          before: record(patient: ' P-OLD '),
          after: record(),
        ),
        isEmpty,
      );
    });
  });
}
