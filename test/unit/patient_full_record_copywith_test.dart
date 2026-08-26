// test/unit/patient_full_record_copywith_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

PatientFullRecord _rich() => PatientFullRecord(
  patientId: 'p-1',
  deviceUid: 'dev-1',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'TI',
      documentNumber: '1234567',
    ),
    firstLastName: 'García',
    firstName: 'Ana',
    dob: '2016-05-02',
    biologicalSex: 'F',
    address: Address(city: 'Cúcuta', state: 'N. Santander'),
    bloodType: 'O+',
  ),
  guardianInfo: GuardianInfo(
    name: 'María García',
    relationship: '01',
    phone: '3001234567',
  ),
  guardian2Info: GuardianInfo(
    name: 'Carlos Pérez',
    relationship: '05',
    phone: '3007654321',
  ),
  backgroundHistory: BackgroundHistory(personalHistory: 'Asma leve'),
  allergies: [AllergyInfo(category: '01', allergen: 'Penicilina')],
  vaccinationRecord: const [],
);

void main() {
  group('PatientFullRecord copyWith & equality', () {
    test('copyWith de un campo conserva TODOS los demás campos de toJson', () {
      final original = _rich();
      final copia = original.copyWith(deviceUid: 'dev-2');

      final aJson = Map<String, dynamic>.from(original.toJson())
        ..remove('device_uid');
      final bJson = Map<String, dynamic>.from(copia.toJson())
        ..remove('device_uid');

      // Comparar las claves detecta si un campo fue omitido en copyWith.
      expect(bJson.keys.toSet(), aJson.keys.toSet());
      expect(bJson.toString(), aJson.toString());
      expect(copia.deviceUid, 'dev-2');
    });

    test('== distingue expedientes con distinto contenido clínico', () {
      final a = _rich();
      final b = a.copyWith(allergies: const <AllergyInfo>[]);

      expect(a, equals(_rich()));
      expect(a, isNot(equals(b)));
      expect(a.hashCode, equals(_rich().hashCode));
    });
  });
}
