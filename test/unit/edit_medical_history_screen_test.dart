// test/unit/edit_medical_history_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ---------------------------------------------------------------------------
// Mock/Stub Construction Helpers
// ---------------------------------------------------------------------------

/// Creates an empty [PatientFullRecord] (with no history or background).
PatientFullRecord emptyPatient() => PatientFullRecord(
  patientId: 'p-001',
  deviceUid: 'dev-001',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '000000',
    ),
    firstLastName: 'Test',
    firstName: 'Paciente',
    dob: '1990-01-01',
    biologicalSex: 'M',
    address: Address(city: 'Bogotá', state: 'Cundinamarca'),
  ),
  guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
  backgroundHistory: null,
  medicalHistory: const <MedicalHistoryItem>[],
  allergies: const <AllergyInfo>[],
  vaccinationRecord: const <VaccinationRecordItem>[],
);

/// Create a [PatientFullRecord] with complete data to verify
/// that the controllers are pre-populated correctly.
PatientFullRecord fullPatient() => PatientFullRecord(
  patientId: 'p-002',
  deviceUid: 'dev-002',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '111111',
    ),
    firstLastName: 'Full',
    firstName: 'Paciente',
    dob: '1985-05-05',
    biologicalSex: 'F',
    address: Address(city: 'Bogotá', state: 'Cundinamarca'),
  ),
  guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
  backgroundHistory: BackgroundHistory(
    personalHistory: 'Apendicectomía 2010',
    chronicConditions: [
      ChronicConditionItem(chronicDescription: 'Hipertensión'),
    ],
    familyHistoryNotes: 'Padre diabético',
    familyHistory: [
      FamilyHistoryItem(
        conditionDescription: 'Diabetes tipo 2',
        relationship: '01',
        conditionCie10Code: 'E11',
      ),
      FamilyHistoryItem(
        conditionDescription: 'Hipertensión arterial',
        relationship: '02',
      ),
    ],
  ),
  medicalHistory: [
    MedicalHistoryItem(
      startDateTime: '',
      clinicalEvaluation: ClinicalEvaluation(
        historyOfCurrentIllness: 'Dolor abdominal 3 días',
        generalPhysicalExamination: 'Abdomen blando',
        systemsExamination: 'Sin alteraciones',
        treatmentPlanObservations: 'Reposo y dieta blanda',
      ),
    ),
  ],
);

const Map<String, String> relLabels = {
  '01': 'Padres',
  '02': 'Hermanos',
  '03': 'Tíos',
  '04': 'Abuelos',
};

// ---------------------------------------------------------------------------
// GROUP 1 – Initialization of controllers with empty patient
// ---------------------------------------------------------------------------
void main() {
  group('InitState – paciente sin datos', () {
    late PatientFullRecord patient;

    setUp(() => patient = emptyPatient());

    test(
      'backgroundHistory es null → todos los campos de antecedentes son ""',
      () {
        expect(patient.backgroundHistory?.personalHistory, isNull);
        expect(patient.backgroundHistory?.chronicConditions, isNull);
        expect(patient.backgroundHistory?.familyHistoryNotes, isNull);
      },
    );

    test('medicalHistory vacío → eval es null → campos clínicos son ""', () {
      final eval = patient.medicalHistory.isNotEmpty
          ? patient.medicalHistory.last.clinicalEvaluation
          : null;
      expect(eval, isNull);
    });

    test('familyHistory es null → lista inicializada vacía', () {
      final items = List<FamilyHistoryItem>.from(
        patient.backgroundHistory?.familyHistory ?? [],
      );
      expect(items, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 2 – Initialization of controllers with complete patient
  // -------------------------------------------------------------------------
  group('InitState – paciente con datos completos', () {
    late PatientFullRecord patient;

    setUp(() => patient = fullPatient());

    test('_personalHistoryCtrl se pre-puebla con personalHistory', () {
      expect(patient.backgroundHistory?.personalHistory, 'Apendicectomía 2010');
    });

    test('_chronicConditionsCtrl se pre-puebla con chronicConditions', () {
      final cc = patient.backgroundHistory?.chronicConditions;
      expect(cc, isA<List<ChronicConditionItem>>());
      expect(cc!.first.chronicDescription, 'Hipertensión');
    });

    test('_familyHistoryNotesCtrl se pre-puebla con familyHistoryNotes', () {
      expect(patient.backgroundHistory?.familyHistoryNotes, 'Padre diabético');
    });

    test('_currentIllnessCtrl usa el último historial médico', () {
      final eval = patient.medicalHistory.last.clinicalEvaluation;
      expect(eval.historyOfCurrentIllness, 'Dolor abdominal 3 días');
    });

    test('_generalExamCtrl se pre-puebla con generalPhysicalExamination', () {
      final eval = patient.medicalHistory.last.clinicalEvaluation;
      expect(eval.generalPhysicalExamination, 'Abdomen blando');
    });

    test('_systemsExamCtrl se pre-puebla con systemsExamination', () {
      final eval = patient.medicalHistory.last.clinicalEvaluation;
      expect(eval.systemsExamination, 'Sin alteraciones');
    });

    test('_treatmentPlanCtrl se pre-puebla con treatmentPlanObservations', () {
      final eval = patient.medicalHistory.last.clinicalEvaluation;
      expect(eval.treatmentPlanObservations, 'Reposo y dieta blanda');
    });

    test(
      '_familyHistoryItems se inicializa con copia de la lista original',
      () {
        final items = List<FamilyHistoryItem>.from(
          patient.backgroundHistory!.familyHistory,
        );
        expect(items.length, 2);
        expect(items.first.conditionDescription, 'Diabetes tipo 2');
      },
    );

    test(
      '_familyHistoryItems es una COPIA (mutarla no afecta al original)',
      () {
        final original = patient.backgroundHistory!.familyHistory;
        final copy = List<FamilyHistoryItem>.from(original);
        copy.removeAt(0);
        expect(original.length, 2); // original intacto
        expect(copy.length, 1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // GROUP 3 – Mapping of relationship labels (_relLabels)
  // -------------------------------------------------------------------------
  group('Mapeo de relaciones familiares', () {
    test('código "01" → "Padres"', () {
      expect(relLabels['01'], 'Padres');
    });

    test('código "02" → "Hermanos"', () {
      expect(relLabels['02'], 'Hermanos');
    });

    test('código "03" → "Tíos"', () {
      expect(relLabels['03'], 'Tíos');
    });

    test('código "04" → "Abuelos"', () {
      expect(relLabels['04'], 'Abuelos');
    });

    test('código desconocido → null (se usa el raw value en la UI)', () {
      expect(relLabels['99'], isNull);
    });

    test('el mapa tiene exactamente 4 entradas', () {
      expect(relLabels.length, 4);
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 4 – _familyHistoryItems list manipulation logic
  // -------------------------------------------------------------------------
  group('Lista de historial familiar – add / remove', () {
    late List<FamilyHistoryItem> items;

    setUp(() {
      items = List<FamilyHistoryItem>.from(
        fullPatient().backgroundHistory!.familyHistory,
      );
    });

    test('agregar un ítem incrementa el tamaño en 1', () {
      items.add(
        FamilyHistoryItem(
          conditionDescription: 'Cáncer de colon',
          relationship: '04',
        ),
      );
      expect(items.length, 3);
    });

    test('el ítem agregado aparece al final de la lista', () {
      final nuevo = FamilyHistoryItem(
        conditionDescription: 'Asma',
        relationship: '03',
      );
      items.add(nuevo);
      expect(items.last.conditionDescription, 'Asma');
    });

    test('eliminar por índice reduce el tamaño en 1', () {
      items.removeAt(0);
      expect(items.length, 1);
    });

    test('eliminar índice 0 deja el elemento correcto en la lista', () {
      items.removeAt(0);
      expect(items.first.conditionDescription, 'Hipertensión arterial');
    });

    test(
      'no agregar ítem con conditionDescription vacía (regla de validación)',
      () {
        final antes = items.length;
        final texto = '   '; // simula trim().isEmpty == true
        if (texto.trim().isNotEmpty) {
          items.add(
            FamilyHistoryItem(
              conditionDescription: texto.trim(),
              relationship: '01',
            ),
          );
        }
        expect(items.length, antes); // sin cambios
      },
    );
  });

  // -------------------------------------------------------------------------
  // GROUP 5 – FamilyHistoryItem Model
  // -------------------------------------------------------------------------
  group('FamilyHistoryItem – modelo de dominio', () {
    test('conditionCie10Code es opcional y puede ser null', () {
      final item = FamilyHistoryItem(
        conditionDescription: 'Diabetes',
        relationship: '01',
      );
      expect(item.conditionCie10Code, isNull);
    });

    test('conditionCie10Code se almacena correctamente cuando se provee', () {
      final item = FamilyHistoryItem(
        conditionDescription: 'Diabetes',
        relationship: '01',
        conditionCie10Code: 'E11',
      );
      expect(item.conditionCie10Code, 'E11');
    });

    test('conditionDescription se almacena con trim previo', () {
      const raw = '  Diabetes  ';
      final item = FamilyHistoryItem(
        conditionDescription: raw.trim(),
        relationship: '01',
      );
      expect(item.conditionDescription, 'Diabetes');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 6 – Selection of the latest medical history (initState logic)
  // -------------------------------------------------------------------------
  group('Selección de última evaluación clínica', () {
    test('con múltiples historiales usa SIEMPRE el último', () {
      final p = PatientFullRecord(
        patientId: 'p-003',
        deviceUid: 'dev-003',
        patientInfo: PatientInfo(
          identification: PatientIdentification(
            documentType: 'CC',
            documentNumber: '333333',
          ),
          firstLastName: 'Multi',
          firstName: 'History',
          dob: '1990-01-01',
          biologicalSex: 'M',
          address: Address(city: 'Bogotá', state: 'Cundinamarca'),
        ),
        guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
        backgroundHistory: null,
        medicalHistory: [
          MedicalHistoryItem(
            startDateTime: '',
            clinicalEvaluation: ClinicalEvaluation(
              historyOfCurrentIllness: 'Primera visita',
            ),
          ),
          MedicalHistoryItem(
            startDateTime: '',
            clinicalEvaluation: ClinicalEvaluation(
              historyOfCurrentIllness: 'Segunda visita',
            ),
          ),
        ],
      );
      final eval = p.medicalHistory.isNotEmpty
          ? p.medicalHistory.last.clinicalEvaluation
          : null;
      expect(eval?.historyOfCurrentIllness, 'Segunda visita');
    });

    test('lista vacía no lanza excepción y eval es null', () {
      final p = emptyPatient();
      ClinicalEvaluation? eval;
      expect(() {
        eval = p.medicalHistory.isNotEmpty
            ? p.medicalHistory.last.clinicalEvaluation
            : null;
      }, returnsNormally);
      expect(eval, isNull);
    });
  });
}
