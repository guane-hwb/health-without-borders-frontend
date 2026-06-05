// test/unit/show_vaccines_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/show_vaccines_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

void main() {
  group('ShowVaccinesScreen — Unit Tests de Constructor', () {
    test(
      'Debe mapear y mantener la integridad del objeto paciente asignado',
      () {
        final patient = PatientFullRecord(
          patientId: 'vaccine-unit-id',
          deviceUid: 'HWB-VACC-00',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'TI',
              documentNumber: '999',
            ),
            firstName: 'Carlos',
            firstLastName: 'Andrade',
            dob: '2018-12-12',
            biologicalSex: 'M',
            address: Address(city: 'Maicao', state: 'La Guajira'),
          ),
          guardianInfo: GuardianInfo(
            name: 'N/A',
            relationship: 'N/A',
            phone: 'N/A',
          ),
          allergies: [],
        );

        final screen = ShowVaccinesScreen(patient: patient);

        expect(screen.patient, equals(patient));
        expect(screen.patient.patientInfo.firstName, equals('Carlos'));
      },
    );
  });
}
