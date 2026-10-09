// test/unit/patient_draft_controller_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/state/patient_draft_controller.dart';

PatientFullRecord _createSamplePatient({
  BackgroundHistory? backgroundHistory,
  List<AllergyInfo>? allergies,
  List<VaccinationRecordItem>? vaccinationRecord,
  List<MedicalHistoryItem>? medicalHistory,
}) {
  return PatientFullRecord(
    patientId: 'P-123',
    deviceUid: 'UID-123',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '12345678',
      ),
      firstName: 'Juan',
      firstLastName: 'Pérez',
      dob: '2000-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'DC'),
      weight: 70.0,
      height: 175.0,
      bloodType: 'O+',
    ),
    guardianInfo: GuardianInfo(
      name: 'María Pérez',
      relationship: 'Madre',
      phone: '3001234567',
    ),
    guardian2Info: GuardianInfo(
      name: 'Carlos Pérez',
      relationship: 'Padre',
      phone: '3007654321',
    ),
    backgroundHistory: backgroundHistory,
    allergies: allergies ?? const [],
    vaccinationRecord: vaccinationRecord ?? const [],
    medicalHistory: medicalHistory ?? const [],
  );
}

void main() {
  late PatientFullRecord initialPatient;
  late PatientDraftController controller;

  setUp(() {
    initialPatient = _createSamplePatient();
    controller = PatientDraftController(initialPatient);
  });

  group('PatientDraftController — Estado inicial y sincronización', () {
    test('getters draft y original retornan la instancia inicial', () {
      expect(controller.draft, equals(initialPatient));
      expect(controller.original, equals(initialPatient));
      expect(controller.hasUnsyncedChanges, isFalse);
    });

    test('reset toma el registro como borrador y como original', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.updateAddress(Address(city: 'Medellín', state: 'Antioquia'));

      final replacement = _createSamplePatient().copyWith(deviceUid: 'UID-9');
      controller.reset(replacement);

      expect(controller.draft, same(replacement));
      expect(controller.original, same(replacement));
      expect(controller.hasUnsyncedChanges, isFalse);
      expect(notified, isTrue);
    });
  });

  group('PatientDraftController — applySyncResult', () {
    // What the sync engine sends: the copy as it comes back from the local
    // queue, i.e. after a JSON round trip.
    PatientFullRecord fromQueue(PatientFullRecord r) =>
        PatientFullRecord.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
        );

    MedicalHistoryItem visit() => MedicalHistoryItem(
      type: 'Consultation',
      encounterIdentifier: 'enc-1',
      startDateTime: '2026-09-29T10:00:00-05:00',
      careModality: '01',
      serviceGroup: '01',
      careEnvironment: '05',
      clinicalEvaluation: ClinicalEvaluation(historyOfCurrentIllness: 'Tos'),
      diagnosis: const [],
      prescriptions: const [],
    );

    setUp(() {
      controller = PatientDraftController(
        _createSamplePatient(
          medicalHistory: [visit()],
        ).copyWith(recordVersion: 4),
      );
    });

    test('ignora el resultado de otro paciente', () {
      final other = _createSamplePatient().copyWith(patientId: 'P-999');
      final effect = controller.applySyncResult(
        RecordSyncResult(patientId: 'P-999', sent: other, recordVersion: 9),
      );

      expect(effect, SyncResultEffect.ignored);
      expect(controller.draft.recordVersion, 4);
    });

    test('el borrador enviado toma la versión nueva y queda sincronizado', () {
      controller.addAllergy(AllergyInfo(category: '01', allergen: 'Maní'));
      final effect = controller.applySyncResult(
        RecordSyncResult(
          patientId: 'P-123',
          sent: fromQueue(controller.draft),
          recordVersion: 5,
        ),
      );

      expect(effect, SyncResultEffect.synced);
      expect(controller.draft.recordVersion, 5);
      expect(controller.draft.toJson()['baseVersion'], 5);
      expect(controller.hasUnsyncedChanges, isFalse);
    });

    test('una edición hecha durante el envío toma la versión nueva y pide '
        're-guardar; el original es lo enviado', () {
      final sent = fromQueue(controller.draft);
      controller.addAllergy(AllergyInfo(category: '01', allergen: 'Maní'));

      final effect = controller.applySyncResult(
        RecordSyncResult(patientId: 'P-123', sent: sent, recordVersion: 5),
      );

      expect(effect, SyncResultEffect.resaveDraft);
      expect(controller.draft.recordVersion, 5);
      expect(controller.draft.allergies, hasLength(1));
      expect(controller.original.allergies, isEmpty);
      expect(controller.original.recordVersion, 5);
    });

    test('otra copia del paciente sin ediciones aquí no cambia la versión: '
        'la siguiente edición no debe pisar lo que esa copia subió', () {
      final other = fromQueue(
        controller.draft.copyWith(
          allergies: [AllergyInfo(category: '01', allergen: 'Látex')],
        ),
      );

      final effect = controller.applySyncResult(
        RecordSyncResult(patientId: 'P-123', sent: other, recordVersion: 5),
      );

      expect(effect, SyncResultEffect.ignored);
      expect(controller.draft.recordVersion, 4);
      expect(controller.draft.allergies, isEmpty);
    });

    test('sin record_version el borrador enviado queda sincronizado igual', () {
      final effect = controller.applySyncResult(
        RecordSyncResult(patientId: 'P-123', sent: fromQueue(controller.draft)),
      );

      expect(effect, SyncResultEffect.synced);
      expect(controller.draft.recordVersion, 4);
    });

    test(
      'con conflictos y registro del servidor, el borrador es el del servidor',
      () {
        final server = _createSamplePatient(
          allergies: [AllergyInfo(category: '01', allergen: 'Polen')],
        ).copyWith(recordVersion: 7);

        final effect = controller.applySyncResult(
          RecordSyncResult(
            patientId: 'P-123',
            sent: fromQueue(controller.draft),
            recordVersion: 7,
            conflicts: const ['stale_payload_base_version'],
            serverRecord: server,
          ),
        );

        expect(effect, SyncResultEffect.replacedByServer);
        expect(controller.draft, same(server));
        expect(controller.original, same(server));
      },
    );

    test(
      'con conflictos y sin registro del servidor, conserva la versión vieja',
      () {
        final effect = controller.applySyncResult(
          RecordSyncResult(
            patientId: 'P-123',
            sent: fromQueue(controller.draft),
            recordVersion: 7,
            conflicts: const ['stale_payload_base_version'],
          ),
        );

        expect(effect, SyncResultEffect.conflictsKept);
        expect(controller.draft.recordVersion, 4);
        expect(controller.hasUnsyncedChanges, isFalse);
      },
    );

    test('con conflictos y ediciones posteriores no reemplaza el borrador', () {
      final sent = fromQueue(controller.draft);
      controller.addAllergy(AllergyInfo(category: '01', allergen: 'Maní'));
      final server = _createSamplePatient().copyWith(recordVersion: 7);

      final effect = controller.applySyncResult(
        RecordSyncResult(
          patientId: 'P-123',
          sent: sent,
          recordVersion: 7,
          conflicts: const ['stale_payload_base_version'],
          serverRecord: server,
        ),
      );

      expect(effect, SyncResultEffect.conflictsKept);
      expect(controller.draft.allergies, hasLength(1));
      expect(controller.draft.recordVersion, 4);
      expect(controller.hasUnsyncedChanges, isTrue);
    });

    test('sameContent ignora la versión y compara por valor', () {
      final a = controller.draft;
      expect(
        PatientDraftController.sameContent(
          a,
          fromQueue(a).copyWith(recordVersion: 99),
        ),
        isTrue,
      );
      expect(
        PatientDraftController.sameContent(
          a,
          a.copyWith(
            allergies: [AllergyInfo(category: '01', allergen: 'X')],
          ),
        ),
        isFalse,
      );
    });
  });

  group('PatientDraftController — Signos vitales y Dirección', () {
    test('updateVitalSigns actualiza el peso, altura y tipo de sangre', () {
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.updateVitalSigns(weight: 75.5, height: 178.0, bloodType: 'A+');

      expect(controller.draft.patientInfo.weight, 75.5);
      expect(controller.draft.patientInfo.height, 178.0);
      expect(controller.draft.patientInfo.bloodType, 'A+');
      expect(controller.hasUnsyncedChanges, isTrue);
      expect(notified, isTrue);
    });

    test(
      'updateVitalSigns mantiene valores existentes si los argumentos son null',
      () {
        controller.updateVitalSigns(weight: null, height: null);

        expect(controller.draft.patientInfo.weight, 70.0);
        expect(controller.draft.patientInfo.height, 175.0);
      },
    );

    test('updateAddress reemplaza la dirección y notifica', () {
      final newAddress = Address(city: 'Cali', state: 'Valle');
      controller.updateAddress(newAddress);

      expect(controller.draft.patientInfo.address.city, 'Cali');
      expect(controller.hasUnsyncedChanges, isTrue);
    });
  });

  group('PatientDraftController — Guardianes', () {
    test('updateGuardian actualiza guardianInfo cuando guardianIndex es 1', () {
      final updatedGuardian = GuardianInfo(
        name: 'Ana Gómez',
        relationship: 'Tía',
        phone: '3110001122',
      );

      controller.updateGuardian(1, updatedGuardian);

      expect(controller.draft.guardianInfo.name, 'Ana Gómez');
      expect(controller.draft.guardian2Info?.name, 'Carlos Pérez');
    });

    test(
      'updateGuardian actualiza guardian2Info cuando guardianIndex es 2',
      () {
        final updatedGuardian2 = GuardianInfo(
          name: 'Pedro Gómez',
          relationship: 'Tío',
          phone: '3119998877',
        );

        controller.updateGuardian(2, updatedGuardian2);

        expect(controller.draft.guardianInfo.name, 'María Pérez');
        expect(controller.draft.guardian2Info?.name, 'Pedro Gómez');
      },
    );

    test('updateGuardian ignora índices diferentes de 1 o 2', () {
      final unusedGuardian = GuardianInfo(
        name: 'Nadie',
        relationship: 'Ninguna',
        phone: '000',
      );

      controller.updateGuardian(3, unusedGuardian);

      expect(controller.draft.guardianInfo.name, 'María Pérez');
      expect(controller.draft.guardian2Info?.name, 'Carlos Pérez');
    });
  });

  group('PatientDraftController — Antecedentes (BackgroundHistory)', () {
    test(
      'updateBackground maneja backgroundHistory nulo creando uno nuevo',
      () {
        final patientNoBg = _createSamplePatient(backgroundHistory: null);
        final ctrl = PatientDraftController(patientNoBg);

        ctrl.updateBackground(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Diabetes tipo 2'),
          ],
          personalHistory: 'Apendicectomía en 2018',
        );

        final bg = ctrl.draft.backgroundHistory;
        expect(bg, isNotNull);
        expect(bg!.chronicConditions, hasLength(1));
        expect(bg.personalHistory, 'Apendicectomía en 2018');
      },
    );

    test(
      'addChronicCondition y removeChronicCondition modifican la lista de condiciones crónicas',
      () {
        final condition1 = ChronicConditionItem(
          chronicDescription: 'Hipertensión',
        );
        final condition2 = ChronicConditionItem(chronicDescription: 'Diabetes');

        controller.addChronicCondition(condition1);
        controller.addChronicCondition(condition2);

        expect(
          controller.draft.backgroundHistory!.chronicConditions,
          hasLength(2),
        );
        expect(
          controller
              .draft
              .backgroundHistory!
              .chronicConditions
              .first
              .chronicDescription,
          'Hipertensión',
        );

        controller.removeChronicCondition(0);

        expect(
          controller.draft.backgroundHistory!.chronicConditions,
          hasLength(1),
        );
        expect(
          controller
              .draft
              .backgroundHistory!
              .chronicConditions
              .first
              .chronicDescription,
          'Diabetes',
        );
      },
    );

    test(
      'addMedication y removeMedication modifican la lista de medicamentos',
      () {
        final med = MedicationStatementItem(
          medicationName: 'Losartán 50mg',
          dosage: '1 tableta',
        );

        controller.addMedication(med);
        expect(controller.draft.backgroundHistory!.medications, hasLength(1));

        controller.removeMedication(0);
        expect(controller.draft.backgroundHistory!.medications, isEmpty);
      },
    );

    test(
      'addFamilyHistory y removeFamilyHistory modifican la lista de antecedentes familiares',
      () {
        final fam = FamilyHistoryItem(
          relationship: '1',
          conditionDescription: 'Diabetes tipo 2',
        );

        controller.addFamilyHistory(fam);
        expect(controller.draft.backgroundHistory!.familyHistory, hasLength(1));

        controller.removeFamilyHistory(0);
        expect(controller.draft.backgroundHistory!.familyHistory, isEmpty);
      },
    );
  });

  group('PatientDraftController — Alergias, Vacunas y Consultas', () {
    test('addAllergy y removeAllergy modifican la lista de alergias', () {
      final allergy = AllergyInfo(
        category: '01',
        allergen: 'Penicilina',
        reaction: 'Urticaria',
      );

      controller.addAllergy(allergy);
      expect(controller.draft.allergies, hasLength(1));
      expect(controller.draft.allergies.first.allergen, 'Penicilina');

      controller.removeAllergy(0);
      expect(controller.draft.allergies, isEmpty);
    });

    test('addVaccines agrega una lista de registros de vacunación', () {
      final vaccines = [
        VaccinationRecordItem(
          vaccineName: 'Influenza',
          vaccineCode: '101',
          dose: 1,
          date: '2023-05-10',
          administratedBy: 'Enfermería',
          administratedAt: 'Puesto de salud',
        ),
        VaccinationRecordItem(
          vaccineName: 'COVID-19',
          vaccineCode: '202',
          dose: 2,
          date: '2023-06-15',
          administratedBy: 'Enfermería',
          administratedAt: 'Puesto de salud',
        ),
      ];

      controller.addVaccines(vaccines);
      expect(controller.draft.vaccinationRecord, hasLength(2));
    });

    test('addConsultation agrega una consulta al historial médico', () {
      final consultation = MedicalHistoryItem(
        type: 'Consultation',
        startDateTime: '2026-09-29T10:00:00-05:00',
        careModality: '01',
        serviceGroup: '01',
        careEnvironment: '05',
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Cefalea',
        ),
        diagnosis: const [],
        prescriptions: const [],
      );

      controller.addConsultation(consultation);
      expect(controller.draft.medicalHistory, hasLength(1));
      expect(
        controller
            .draft
            .medicalHistory
            .first
            .clinicalEvaluation
            .historyOfCurrentIllness,
        'Cefalea',
      );
    });

    test(
      'updateBackground conserva personalHistory existente cuando el nuevo valor es null',
      () {
        final patientWithBg = _createSamplePatient(
          backgroundHistory: BackgroundHistory(
            personalHistory: 'Cirugía de rodilla previa',
            chronicConditions: const [],
          ),
        );
        final ctrl = PatientDraftController(patientWithBg);

        ctrl.updateBackground(
          chronicConditions: [ChronicConditionItem(chronicDescription: 'Asma')],
          personalHistory: null,
        );

        final bg = ctrl.draft.backgroundHistory;
        expect(bg, isNotNull);
        expect(bg!.personalHistory, 'Cirugía de rodilla previa');
        expect(bg.chronicConditions, hasLength(1));
        expect(bg.chronicConditions.first.chronicDescription, 'Asma');
      },
    );
  });
}
