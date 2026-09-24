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

    test(
      'preserves the declarative fields an offline edit would sync back',
      () {
        // The offline guardian read opens the profile editable, and the server
        // takes declarative fields from whatever the device sends. Anything the
        // card stops carrying would therefore be blanked on the patient's
        // server record the first time someone edits offline. The bounded
        // lists are safe — the server merges those by identifier — so this is
        // the boundary that actually has to hold.
        final record = _record(
          history: <MedicalHistoryItem>[_consultation('2026-01-10T09:00:00')],
          vaccines: <VaccinationRecordItem>[_vaccine('2026-06-01')],
          allergies: <AllergyInfo>[
            AllergyInfo(category: '01', allergen: 'Penicilina'),
          ],
        );

        final rebuilt = NfcGuardianPayload.reconstructFromGuardian(
          NfcGuardianPayload.buildGuardianPayload(record: record),
        );

        expect(rebuilt.patientId, record.patientId);
        expect(rebuilt.deviceUid, record.deviceUid);
        expect(
          rebuilt.patientInfo.address.city,
          record.patientInfo.address.city,
        );
        expect(
          rebuilt.patientInfo.address.state,
          record.patientInfo.address.state,
        );
        expect(
          rebuilt.patientInfo.identification.documentNumber,
          record.patientInfo.identification.documentNumber,
        );
        expect(rebuilt.allergies.length, record.allergies.length);
      },
    );
  });

  group('reconstructFromTriage', () {
    test(
      'is partial, which is why the wristband-only read stays read-only',
      () {
        const triage = TriageSummary(
          firstName: 'Ana',
          lastName: 'Pérez',
          dob: '2015-01-01',
          biologicalSex: 'F',
          bloodType: 'O+',
          documentType: 'MS',
          documentNumber: '1234567890',
          guardianPhone: '3001234567',
          guardianDeviceUid: 'GUARDIAN:UID',
          chronicConditions: '',
          allergies: <TriageAllergy>[],
        );

        final record = NfcGuardianPayload.reconstructFromTriage(
          triage,
          deviceUid: 'PATIENT:UID',
        );

        // Syncing this back would create a second patient and blank the
        // address on the real one. Hence read-only until the sync can carry
        // only what changed.
        expect(record.patientId, isEmpty);
        expect(record.patientInfo.address.city, isEmpty);
        expect(record.patientInfo.address.state, isEmpty);
      },
    );

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

  TriageSummary triageWith({
    String firstName = 'Ana',
    String lastName = 'Pérez',
    String dob = '2010-05-04',
    String biologicalSex = 'F',
    String bloodType = 'O+',
    String documentType = 'TI',
    String documentNumber = '999',
    String guardianPhone = '3001234567',
    String guardianDeviceUid = 'GUARDIAN:UID',
    String? guardian2DeviceUid,
    String chronicConditions = '',
    List<TriageAllergy> allergies = const <TriageAllergy>[],
  }) {
    return TriageSummary(
      firstName: firstName,
      lastName: lastName,
      dob: dob,
      biologicalSex: biologicalSex,
      bloodType: bloodType,
      documentType: documentType,
      documentNumber: documentNumber,
      guardianPhone: guardianPhone,
      guardianDeviceUid: guardianDeviceUid,
      guardian2DeviceUid: guardian2DeviceUid,
      chronicConditions: chronicConditions,
      allergies: allergies,
    );
  }

  group('reconstructFromTriage - segundo acudiente', () {
    test('con guardian2DeviceUid no vacío arma guardian2Info', () {
      final record = NfcGuardianPayload.reconstructFromTriage(
        triageWith(guardian2DeviceUid: 'GUARDIAN2:UID'),
        deviceUid: 'PATIENT:UID',
      );

      expect(record.guardian2Info, isNotNull);
      expect(record.guardian2Info!.deviceUid, 'GUARDIAN2:UID');
      expect(record.guardian2Info!.name, isEmpty);
      expect(record.guardian2Info!.relationship, isEmpty);
      expect(record.guardian2Info!.phone, isEmpty);
      expect(record.guardianInfo.deviceUid, 'GUARDIAN:UID');
    });

    test('con guardian2DeviceUid vacío no arma guardian2Info', () {
      final record = NfcGuardianPayload.reconstructFromTriage(
        triageWith(guardian2DeviceUid: ''),
      );

      expect(record.guardian2Info, isNull);
    });

    test('con guardian2DeviceUid nulo no arma guardian2Info', () {
      final record = NfcGuardianPayload.reconstructFromTriage(
        triageWith(guardian2DeviceUid: null),
      );

      expect(record.guardian2Info, isNull);
    });
  });

  group('reconstructFromTriage - valores por defecto', () {
    test('campos vacíos del triage caen a los defaults del modelo', () {
      final record = NfcGuardianPayload.reconstructFromTriage(
        triageWith(
          documentType: '',
          biologicalSex: '',
          bloodType: '',
          guardianDeviceUid: '',
          chronicConditions: '',
          allergies: const <TriageAllergy>[
            TriageAllergy(category: '', allergen: 'Polen', reaction: ''),
          ],
        ),
      );

      expect(record.deviceUid, isEmpty);
      expect(record.patientInfo.identification.documentType, 'MS');
      expect(record.patientInfo.biologicalSex, 'I');
      expect(record.patientInfo.bloodType, isNull);
      expect(record.guardianInfo.deviceUid, isNull);
      expect(record.backgroundHistory, isNull);
      expect(record.allergies.length, 1);
      expect(record.allergies.first.category, '06');
      expect(record.allergies.first.allergen, 'Polen');
      expect(record.allergies.first.reaction, isNull);
    });

    test('ignora segmentos vacíos y espacios en las condiciones crónicas', () {
      final record = NfcGuardianPayload.reconstructFromTriage(
        triageWith(chronicConditions: ' Asma ; ;Diabetes;  '),
      );

      expect(
        record.backgroundHistory?.chronicConditions
            .map((ChronicConditionItem c) => c.chronicDescription)
            .toList(),
        <String>['Asma', 'Diabetes'],
      );
    });
  });

  group('reconstruct dispatcher - solo triage', () {
    test('sin guardianRecord reconstruye desde el triage', () {
      final rebuilt = NfcGuardianPayload.reconstruct(
        triage: triageWith(guardian2DeviceUid: 'GUARDIAN2:UID'),
        patientDeviceUid: 'PATIENT:UID',
      );

      expect(rebuilt.patientId, isEmpty);
      expect(rebuilt.deviceUid, 'PATIENT:UID');
      expect(rebuilt.patientInfo.fullName, 'Ana Pérez');
      expect(rebuilt.guardian2Info?.deviceUid, 'GUARDIAN2:UID');
      expect(rebuilt.medicalHistory, isEmpty);
    });

    test('patientDeviceUid es opcional y por defecto queda vacío', () {
      final rebuilt = NfcGuardianPayload.reconstruct(triage: triageWith());

      expect(rebuilt.deviceUid, isEmpty);
    });
  });

  group('signature stripping - segundo acudiente', () {
    test('también elimina signatureBase64 de guardian2Info', () {
      final record = _record(
        guardian2: GuardianInfo(
          name: 'Pedro Pérez',
          relationship: 'Padre',
          phone: '3009876543',
          deviceUid: 'GUARDIAN2:UID',
          consent: GuardianConsent(
            accepted: true,
            acceptedAt: '2026-01-01T00:00:00Z',
            email: 'p@example.com',
            signatureBase64: 'DDDDEEEEFFFF',
          ),
        ),
      );

      final payload = NfcGuardianPayload.buildGuardianPayload(record: record);

      final guardian2 = payload['guardian2Info'] as Map<String, dynamic>;
      final consent = guardian2['consent'] as Map;
      expect(consent.containsKey('signatureBase64'), isFalse);
      expect(consent['accepted'], isTrue);
      expect(consent['email'], 'p@example.com');
      expect(guardian2['device_uid'], 'GUARDIAN2:UID');
    });

    test('sin guardian2 ni consentimiento no falla', () {
      final record = _record();

      expect(
        () => NfcGuardianPayload.buildGuardianPayload(record: record),
        returnsNormally,
      );
    });
  });

  group('buildWithinCapacity - orden de recorte', () {
    int jsonSize(Map<String, dynamic> m) => jsonEncode(m).length;

    int lengthOf(Map<String, dynamic> m, String key) =>
        (m[key] as List<dynamic>?)?.length ?? 0;

    test('cuando hay más vacunas que consultas recorta vacunas (n < m)', () {
      final record = _record(
        vaccines: <VaccinationRecordItem>[
          _vaccine('2026-01-01'),
          _vaccine('2026-02-01'),
          _vaccine('2026-03-01'),
        ],
      );

      final full = aliasGuardianPayload(
        NfcGuardianPayload.buildGuardianPayload(record: record),
      );
      final budget = jsonSize(full) - 1;

      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: budget,
        estimateSize: jsonSize,
      );

      expect(fit.fits, isTrue);
      expect(fit.includedConsultations, 0);
      expect(fit.includedVaccines, lessThan(3));
      expect(fit.droppedVaccines, greaterThan(0));
      expect(fit.isPartial, isTrue);
    });

    test('recorta de la lista más grande y alterna en empates', () {
      final record = _record(
        history: <MedicalHistoryItem>[_consultation('2026-01-10T09:00:00')],
        vaccines: <VaccinationRecordItem>[
          _vaccine('2026-01-01'),
          _vaccine('2026-02-01'),
          _vaccine('2026-03-01'),
        ],
      );

      final seen = <List<int>>[];
      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: 1,
        estimateSize: (Map<String, dynamic> aliased) {
          final plain = unaliasGuardianPayload(aliased);
          seen.add(<int>[
            lengthOf(plain, 'medicalHistory'),
            lengthOf(plain, 'vaccinationRecord'),
          ]);
          return 1000;
        },
      );

      expect(seen, <List<int>>[
        <int>[1, 3],
        <int>[1, 2],
        <int>[1, 1],
        <int>[0, 1],
        <int>[0, 0],
      ]);
      expect(fit.includedConsultations, 0);
      expect(fit.includedVaccines, 0);
      expect(fit.droppedConsultations, 1);
      expect(fit.droppedVaccines, 3);
      expect(fit.estimatedBytes, 1000);
    });

    test('si ni la base cabe, fits es false y no queda historial', () {
      final record = _record(
        history: <MedicalHistoryItem>[
          _consultation('2026-01-10T09:00:00'),
          _consultation('2026-02-10T09:00:00'),
        ],
        vaccines: <VaccinationRecordItem>[_vaccine('2026-01-01')],
      );

      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: 1,
        estimateSize: jsonSize,
      );

      expect(fit.fits, isFalse);
      expect(fit.includedConsultations, 0);
      expect(fit.includedVaccines, 0);
      expect(fit.isPartial, isTrue);
    });

    test('límites negativos se tratan como cero', () {
      final record = _record(
        history: <MedicalHistoryItem>[_consultation('2026-01-10T09:00:00')],
        vaccines: <VaccinationRecordItem>[_vaccine('2026-01-01')],
      );

      final fit = NfcGuardianPayload.buildWithinCapacity(
        record: record,
        capacityBytes: 1000000,
        estimateSize: jsonSize,
        maxConsultations: -5,
        maxVaccines: -5,
      );

      expect(fit.includedConsultations, 0);
      expect(fit.includedVaccines, 0);
      expect(fit.fits, isTrue);
      expect(fit.totalConsultations, 1);
      expect(fit.totalVaccines, 1);
    });
  });
}
