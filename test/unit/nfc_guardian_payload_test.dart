// test/unit/nfc_guardian_payload_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

MedicalHistoryItem _consultation(String startDateTime) {
  return MedicalHistoryItem(
    startDateTime: startDateTime,
    clinicalEvaluation: ClinicalEvaluation(
      historyOfCurrentIllness: 'note $startDateTime',
    ),
  );
}

VaccinationRecordItem _vaccine(String date) {
  return VaccinationRecordItem(
    date: date,
    vaccineName: 'Vacuna $date',
    vaccineCode: '03',
    dose: 1,
    administratedBy: 'Nurse',
    administratedAt: 'Clinic',
  );
}

PatientFullRecord _record({
  List<MedicalHistoryItem> history = const <MedicalHistoryItem>[],
  List<VaccinationRecordItem> vaccines = const <VaccinationRecordItem>[],
  List<AllergyInfo> allergies = const <AllergyInfo>[],
  GuardianInfo? guardian,
  GuardianInfo? guardian2,
}) {
  return PatientFullRecord(
    patientId: 'patient-uuid-1',
    deviceUid: 'PATIENT:UID',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '123',
      ),
      firstLastName: 'Pérez',
      firstName: 'Ana',
      dob: '2010-05-04',
      biologicalSex: 'F',
      address: Address(city: 'Cúcuta', state: 'NSA'),
      bloodType: 'O+',
    ),
    guardianInfo:
        guardian ??
        GuardianInfo(
          name: 'María Pérez',
          relationship: 'Madre',
          phone: '3001234567',
          deviceUid: 'GUARDIAN:UID',
        ),
    guardian2Info: guardian2,
    allergies: allergies,
    medicalHistory: history,
    vaccinationRecord: vaccines,
  );
}

void main() {
  group('buildGuardianPayload bounding', () {
    test('keeps only the most recent N consultations, newest first', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-03-15T09:00:00'),
          _consultation('2025-12-01T09:00:00'),
          _consultation('2026-02-20T09:00:00'),
          _consultation('2026-04-01T09:00:00'),
        ],
      );

      final payload = NfcGuardianPayload.buildGuardianPayload(
        record: record,
        maxConsultations: 3,
        maxVaccines: 3,
      );

      final history = payload['medicalHistory'] as List<dynamic>;
      expect(history.length, 3);
      final dates = history
          .map((dynamic e) => (e as Map)['startDateTime'] as String)
          .toList();
      expect(dates, <String>[
        '2026-04-01T09:00:00',
        '2026-03-15T09:00:00',
        '2026-02-20T09:00:00',
      ]);
    });

    test('keeps only the most recent M vaccines', () {
      final record = _record(
        vaccines: <VaccinationRecordItem>[
          _vaccine('2024-01-01'),
          _vaccine('2026-06-01'),
          _vaccine('2025-05-05'),
        ],
      );

      final payload = NfcGuardianPayload.buildGuardianPayload(
        record: record,
        maxVaccines: 2,
      );

      final vaccines = payload['vaccinationRecord'] as List<dynamic>;
      expect(vaccines.length, 2);
      final dates = vaccines
          .map((dynamic e) => (e as Map)['date'] as String)
          .toList();
      expect(dates, <String>['2026-06-01', '2025-05-05']);
    });

    test('does not mutate the original record', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-03-15T09:00:00'),
        ],
      );

      NfcGuardianPayload.buildGuardianPayload(
        record: record,
        maxConsultations: 1,
      );

      expect(record.medicalHistory.length, 2);
    });
  });

  group('signature stripping', () {
    test('removes signatureBase64 but keeps other consent fields', () {
      final record = _record(
        guardian: GuardianInfo(
          name: 'María',
          relationship: 'Madre',
          phone: '3001234567',
          deviceUid: 'GUARDIAN:UID',
          consent: GuardianConsent(
            accepted: true,
            acceptedAt: '2026-01-01T00:00:00Z',
            email: 'm@example.com',
            signatureBase64: 'AAAABBBBCCCC',
          ),
        ),
      );

      final payload = NfcGuardianPayload.buildGuardianPayload(record: record);

      final guardian = payload['guardianInfo'] as Map<String, dynamic>;
      final consent = guardian['consent'] as Map;
      expect(consent.containsKey('signatureBase64'), isFalse);
      expect(consent['accepted'], isTrue);
      expect(consent['email'], 'm@example.com');
    });
  });

  group('aliased write path round-trip', () {
    // The real guardian-write path: buildWithinCapacity produces the aliased
    // payload that gets written, and reconstructFromGuardian must rebuild the
    // record from exactly that. A break here is offline data corruption.
    test(
      'buildWithinCapacity payload reconstructs to an equivalent record',
      () {
        final record = _record(
          history: <MedicalHistoryItem>[
            _consultation('2026-01-10T09:00:00'),
            _consultation('2026-03-15T09:00:00'),
          ],
          vaccines: <VaccinationRecordItem>[_vaccine('2026-06-01')],
          allergies: <AllergyInfo>[
            AllergyInfo(
              category: '01',
              allergen: 'Penicilina',
              reaction: 'Rash',
            ),
          ],
        );

        final fit = NfcGuardianPayload.buildWithinCapacity(
          record: record,
          capacityBytes: 1000000,
          estimateSize: (Map<String, dynamic> m) => 0, // ample: no trimming
        );
        // fit.payload is aliased (has the schema marker).
        expect(fit.payload[kAliasSchemaKey], kAliasSchemaVersion);

        final rebuilt = NfcGuardianPayload.reconstructFromGuardian(fit.payload);

        expect(rebuilt.patientId, 'patient-uuid-1');
        expect(rebuilt.deviceUid, 'PATIENT:UID');
        expect(rebuilt.patientInfo.fullName, 'Ana Pérez');
        expect(rebuilt.patientInfo.bloodType, 'O+');
        expect(rebuilt.guardianInfo.deviceUid, 'GUARDIAN:UID');
        expect(rebuilt.allergies.first.allergen, 'Penicilina');
        expect(rebuilt.medicalHistory.length, 2);
        expect(rebuilt.vaccinationRecord.length, 1);
      },
    );

    test('dropped-history counts are reported on the fit', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-02-10T09:00:00'),
          _consultation('2026-03-10T09:00:00'),
        ],
        vaccines: <VaccinationRecordItem>[_vaccine('2026-01-01')],
      );

      // Force keeping only 1 consultation via a tiny estimate that exceeds the
      // budget until n+m is small.
      var call = 0;
      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: 100,
        // First estimates are "too big", shrinking as entries drop.
        estimateSize: (Map<String, dynamic> m) => 200 - (call++ * 40),
      );

      expect(fit.isPartial, isTrue);
      expect(
        fit.droppedConsultations + fit.droppedVaccines,
        fit.totalConsultations +
            fit.totalVaccines -
            fit.includedConsultations -
            fit.includedVaccines,
      );
    });
  });

  group('reconstructFromGuardian round-trip', () {
    test('rebuilds an equivalent PatientFullRecord', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-03-15T09:00:00'),
          _consultation('2026-02-20T09:00:00'),
          _consultation('2026-04-01T09:00:00'),
        ],
        vaccines: <VaccinationRecordItem>[_vaccine('2026-06-01')],
        allergies: <AllergyInfo>[
          AllergyInfo(category: '01', allergen: 'Penicilina', reaction: 'Rash'),
        ],
      );

      final payload = NfcGuardianPayload.buildGuardianPayload(
        record: record,
        maxConsultations: 3,
      );
      final rebuilt = NfcGuardianPayload.reconstructFromGuardian(payload);

      expect(rebuilt.patientId, 'patient-uuid-1');
      expect(rebuilt.deviceUid, 'PATIENT:UID');
      expect(rebuilt.patientInfo.fullName, 'Ana Pérez');
      expect(rebuilt.patientInfo.bloodType, 'O+');
      expect(rebuilt.guardianInfo.deviceUid, 'GUARDIAN:UID');
      expect(rebuilt.allergies.length, 1);
      expect(rebuilt.allergies.first.allergen, 'Penicilina');
      expect(rebuilt.medicalHistory.length, 3);
    });
  });

  group('reconstructFromTriage', () {
    test('maps chronic conditions and allergies into a partial record', () {
      const triage = TriageSummary(
        firstName: 'Ana',
        lastName: 'Pérez',
        dob: '2010-05-04',
        biologicalSex: 'F',
        bloodType: 'O+',
        documentType: 'TI',
        documentNumber: '999',
        guardianPhone: '3001234567',
        guardianDeviceUid: 'GUARDIAN:UID',
        guardian2DeviceUid: null,
        chronicConditions: 'Asma; Diabetes',
        allergies: <TriageAllergy>[
          TriageAllergy(
            category: '01',
            allergen: 'Penicilina',
            reaction: 'Rash',
          ),
        ],
        vidaCode: null,
      );

      final record = NfcGuardianPayload.reconstructFromTriage(
        triage,
        deviceUid: 'PATIENT:UID',
      );

      expect(record.deviceUid, 'PATIENT:UID');
      expect(record.patientInfo.fullName, 'Ana Pérez');
      expect(record.patientInfo.bloodType, 'O+');
      expect(record.patientInfo.identification.documentType, 'TI');
      expect(record.guardianInfo.phone, '3001234567');
      expect(record.guardianInfo.deviceUid, 'GUARDIAN:UID');
      expect(record.backgroundHistory?.chronicConditions.length, 2);
      expect(
        record.backgroundHistory?.chronicConditions
            .map((ChronicConditionItem c) => c.chronicDescription)
            .toList(),
        <String>['Asma', 'Diabetes'],
      );
      expect(record.allergies.length, 1);
      expect(record.medicalHistory, isEmpty);
    });
  });

  group('buildWithinCapacity', () {
    int jsonSize(Map<String, dynamic> m) => jsonEncode(m).length;

    test('keeps everything when capacity is ample', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-02-10T09:00:00'),
          _consultation('2026-03-10T09:00:00'),
        ],
        vaccines: <VaccinationRecordItem>[
          _vaccine('2026-01-01'),
          _vaccine('2026-02-01'),
          _vaccine('2026-03-01'),
        ],
      );

      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: 1000000,
        estimateSize: jsonSize,
      );

      expect(fit.fits, isTrue);
      expect(fit.includedConsultations, 3);
      expect(fit.includedVaccines, 3);
    });

    test('drops oldest entries until the payload fits', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-02-10T09:00:00'),
          _consultation('2026-03-10T09:00:00'),
        ],
        vaccines: <VaccinationRecordItem>[
          _vaccine('2026-01-01'),
          _vaccine('2026-02-01'),
          _vaccine('2026-03-01'),
        ],
      );

      // buildWithinCapacity measures the aliased payload (what actually gets
      // written), so the budget reference must be the aliased size too.
      final full = aliasGuardianPayload(
        NfcGuardianPayload.buildGuardianPayload(record: record),
      );
      final fullSize = jsonSize(full);
      final budget = fullSize - 1;

      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: budget,
        estimateSize: jsonSize,
      );

      expect(fit.fits, isTrue);
      expect(fit.estimatedBytes, lessThanOrEqualTo(budget));
      expect(fit.includedConsultations + fit.includedVaccines, lessThan(6));
    });
  });

  group('reconstruct dispatcher', () {
    test('prefers the guardian record when both sources are present', () {
      final record = _record();
      final guardianPayload = NfcGuardianPayload.buildGuardianPayload(
        record: record,
      );

      const triage = TriageSummary(
        firstName: 'Otro',
        lastName: 'Nombre',
        dob: '2000-01-01',
        biologicalSex: 'M',
        bloodType: 'A-',
        documentType: 'CC',
        documentNumber: '000',
        guardianPhone: '',
        guardianDeviceUid: '',
        chronicConditions: '',
        allergies: <TriageAllergy>[],
      );

      final rebuilt = NfcGuardianPayload.reconstruct(
        triage: triage,
        guardianRecord: guardianPayload,
      );

      // Guardian wins: name comes from the full record, not the triage.
      expect(rebuilt.patientInfo.fullName, 'Ana Pérez');
    });

    test('throws when neither source is provided', () {
      expect(NfcGuardianPayload.reconstruct, throwsArgumentError);
    });
  });

  group('guardianFitBuilder', () {
    // El adaptador que ambas pantallas usan para atar record+codec al
    // presupuesto real del chip. Antes era una closure duplicada en dos
    // pantallas, alcanzable solo manejando la UI completa.
    final codec = NfcPayloadCodec(hexKey: 'a' * 64);

    test('con presupuesto amplio no recorta nada', () {
      final record = _record(
        history: <MedicalHistoryItem>[_consultation('2026-01-10T09:00:00')],
      );
      final fit = guardianFitBuilder(record: record, codec: codec)(100000);

      expect(fit.fits, isTrue);
      expect(fit.isPartial, isFalse);
      expect(fit.includedConsultations, 1);
    });

    test('con presupuesto diminuto recorta el historial', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-02-10T09:00:00'),
        ],
      );
      final fit = guardianFitBuilder(record: record, codec: codec)(1);

      expect(fit.includedConsultations, 0);
      expect(fit.droppedConsultations, 2);
      expect(fit.isPartial, isTrue);
    });

    test('el presupuesto recibido es el que se aplica', () {
      final record = _record(
        history: <MedicalHistoryItem>[_consultation('2026-01-10T09:00:00')],
      );
      final builder = guardianFitBuilder(record: record, codec: codec);
      expect(
        builder(1).includedConsultations,
        lessThanOrEqualTo(builder(100000).includedConsultations),
      );
    });
  });
}
