// test/unit/add_medication_label_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  /// Replicates the private _statusLabel() widget method for isolated pure logic tests.
  String statusLabel(AppStrings s, String code) => switch (code) {
    'active' => s.medStatusActive,
    'completed' => s.medStatusCompleted,
    'stopped' => s.medStatusStopped,
    'unknown' => s.medStatusUnknown,
    _ => code,
  };

  group('AppStrings.forTesting — Spanish locale validations (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('addMedicationTitle returns the correct value', () {
      expect(s.addMedicationTitle, equals('Agregar medicamento'));
    });

    test('addMedicationSubtitle returns the correct value', () {
      expect(
        s.addMedicationSubtitle,
        equals('Registrar medicamento actual del paciente'),
      );
    });

    test('medicationLabel returns the correct value', () {
      expect(s.medicationLabel, equals('Medicamento *'));
    });

    test('medicationHint returns the correct value', () {
      expect(s.medicationHint, equals('ej: Metformina 850mg'));
    });

    test('statusLabel returns the correct value', () {
      expect(s.statusLabel, equals('Estado'));
    });

    test('dosageLabel returns the correct value', () {
      expect(s.dosageLabel, equals('Posología'));
    });

    test('dosageHint returns the correct value', () {
      expect(s.dosageHint, equals('ej: 1 tableta cada 12 horas'));
    });

    test('notesLabel returns the correct value', () {
      expect(s.notesLabel, equals('Notas'));
    });

    test('notesHint returns the correct value', () {
      expect(s.notesHint, equals('Observaciones adicionales'));
    });

    test('confirm returns the correct value', () {
      expect(s.confirm, equals('Confirmar'));
    });

    test('medStatusActive returns the correct value', () {
      expect(s.medStatusActive, equals('Activo'));
    });

    test('medStatusCompleted returns the correct value', () {
      expect(s.medStatusCompleted, equals('Completado'));
    });

    test('medStatusStopped returns the correct value', () {
      expect(s.medStatusStopped, equals('Suspendido'));
    });

    test('medStatusUnknown returns the correct value', () {
      expect(s.medStatusUnknown, equals('Desconocido'));
    });
  });

  group('AppStrings.forTesting — English locale validations (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('addMedicationTitle returns the correct value', () {
      expect(s.addMedicationTitle, equals('Add medication'));
    });

    test('addMedicationSubtitle returns the correct value', () {
      expect(
        s.addMedicationSubtitle,
        equals("Register the patient's current medication"),
      );
    });

    test('medicationLabel returns the correct value', () {
      expect(s.medicationLabel, equals('Medication *'));
    });

    test('medicationHint returns the correct value', () {
      expect(s.medicationHint, equals('e.g. Metformin 850mg'));
    });

    test('statusLabel returns the correct value', () {
      expect(s.statusLabel, equals('Status'));
    });

    test('dosageLabel returns the correct value', () {
      expect(s.dosageLabel, equals('Dosage'));
    });

    test('dosageHint returns the correct value', () {
      expect(s.dosageHint, equals('e.g. 1 tablet every 12 hours'));
    });

    test('notesLabel returns the correct value', () {
      expect(s.notesLabel, equals('Notes'));
    });

    test('notesHint returns the correct value', () {
      expect(s.notesHint, equals('Additional observations'));
    });

    test('medStatusActive returns the correct value', () {
      expect(s.medStatusActive, equals('Active'));
    });

    test('medStatusCompleted returns the correct value', () {
      expect(s.medStatusCompleted, equals('Completed'));
    });

    test('medStatusStopped returns the correct value', () {
      expect(s.medStatusStopped, equals('Stopped'));
    });

    test('medStatusUnknown returns the correct value', () {
      expect(s.medStatusUnknown, equals('Unknown'));
    });
  });

  group('statusLabel() — mapping codes to labels (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test("'active' maps to Activo", () {
      expect(statusLabel(s, 'active'), equals('Activo'));
    });

    test("'completed' maps to Completado", () {
      expect(statusLabel(s, 'completed'), equals('Completado'));
    });

    test("'stopped' maps to Suspendido", () {
      expect(statusLabel(s, 'stopped'), equals('Suspendido'));
    });

    test("'unknown' maps to Desconocido", () {
      expect(statusLabel(s, 'unknown'), equals('Desconocido'));
    });

    test('unknown codes return the input code as a fallback strategy', () {
      expect(statusLabel(s, 'paused'), equals('paused'));
      expect(statusLabel(s, ''), equals(''));
      expect(statusLabel(s, 'XYZ'), equals('XYZ'));
    });
  });

  group('statusLabel() — mapping codes to labels (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test("'active' maps to Active", () {
      expect(statusLabel(s, 'active'), equals('Active'));
    });

    test("'completed' maps to Completed", () {
      expect(statusLabel(s, 'completed'), equals('Completed'));
    });

    test("'stopped' maps to Stopped", () {
      expect(statusLabel(s, 'stopped'), equals('Stopped'));
    });

    test("'unknown' maps to Unknown", () {
      expect(statusLabel(s, 'unknown'), equals('Unknown'));
    });

    test('unknown codes return the input code as a fallback strategy', () {
      expect(statusLabel(s, 'draft'), equals('draft'));
    });
  });
}
