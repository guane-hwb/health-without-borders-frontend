// test/unit/show_allergens_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/show_allergens_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

void main() {
  group('ShowAllergensScreen — Unit Tests de Constructor', () {
    test(
      'Debe persistir y asignar correctamente el registro de paciente inyectado',
      () {
        final patient = PatientFullRecord(
          patientId: 'id-unitario',
          deviceUid: 'HWB-UID',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'CC',
              documentNumber: '11',
            ),
            firstName: 'Ana',
            firstLastName: 'Mendoza',
            dob: '1990-10-10',
            biologicalSex: 'F',
            address: Address(city: 'Medellín', state: 'Antioquia'),
          ),
          guardianInfo: GuardianInfo(
            name: 'N/A',
            relationship: 'N/A',
            phone: 'N/A',
          ),
          allergies: [],
        );

        final screen = ShowAllergensScreen(patient: patient);

        expect(screen.patient, equals(patient));
        expect(screen.patient.patientId, equals('id-unitario'));
      },
    );
  });
}
