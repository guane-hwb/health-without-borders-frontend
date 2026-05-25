// test/widget/features/nfc/profile/tabs/profile_tab_allergies_widget_test.dart
//
// Widget testing for ProfileTabAllergies.
// Covers what the Flutter widget tree DOES require:
// • Empty state — text "No allergies registered."
// • Allergy counter in the header (ALLERGIES · N)
// • Correct rendering of each AllergyCard
// • Visibility of the REACTION section based on null/present reaction
// • "Add Allergy" button — visible and functional
// • Delete button — triggers onRemove with the correct index
// • List with multiple items — all rendered

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_allergies.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
AllergyInfo _allergy({
  required String category,
  required String allergen,
  String? reaction,
}) =>
    AllergyInfo(category: category, allergen: allergen, reaction: reaction);

/// Build a minimal [PatientFullRecord] with the given allergies.
PatientFullRecord _record(List<AllergyInfo> allergies) => PatientFullRecord(
      patientId: 'p-001',
      deviceUid: 'dev-001',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123456789',
        ),
        firstLastName: 'Test',
        firstName: 'Paciente',
        dob: '1990-01-01',
        biologicalSex: 'M',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
      backgroundHistory: BackgroundHistory(),
      allergies: allergies,
      medicalHistory: const [],
      vaccinationRecord: const [],
    );

/// Wrap [ProfileTabAllergies] in the minimal widget tree needed.
Widget _wrap({
  required PatientFullRecord record,
  VoidCallback? onAdd,
  void Function(int)? onRemove,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProfileTabAllergies(
        draft: record,
        onAdd: onAdd ?? () {},
        onRemove: onRemove ?? (_) {},
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {

  // ── Group 1: Empty state ──────────────────────────────────────────────────
  group('ProfileTabAllergies — estado vacío', () {
    testWidgets('muestra "Sin alergias registradas." cuando la lista está vacía',
        (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      expect(find.text('Sin alergias registradas.'), findsOneWidget);
    });

    testWidgets('encabezado muestra "ALERGIAS · 0" con lista vacía',
        (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      expect(find.text('ALERGIAS · 0'), findsOneWidget);
    });

    testWidgets('NO muestra ningún _AllergyCard con lista vacía',
        (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      // El ícono de eliminar solo aparece en AllergyCards
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('botón "Agregar alergia" está visible en estado vacío',
        (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      expect(find.text('Agregar alergia'), findsOneWidget);
    });
  });

  // ── Group 2: Header — dynamic counter ────────────────────────────────
  group('ProfileTabAllergies — encabezado', () {
    testWidgets('muestra "ALERGIAS · 1" con un ítem', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('ALERGIAS · 1'), findsOneWidget);
    });

    testWidgets('muestra "ALERGIAS · 3" con tres ítems', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
        _allergy(category: '02', allergen: 'Maní'),
        _allergy(category: '05', allergen: 'Abeja'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('ALERGIAS · 3'), findsOneWidget);
    });

    testWidgets('el encabezado tiene ícono warning_amber_rounded', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      // There is at least one warning icon in the header
      expect(find.byIcon(Icons.warning_amber_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('el encabezado usa color AppColors.error', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      final errorTexts = find.byWidgetPredicate(
        (w) => w is Text && w.style?.color == AppColors.error,
      );
      expect(errorTexts, findsAtLeastNWidgets(1));
    });
  });

  // ── Group 3: AllergyCard — rendered with one item ────────────────────────
  group('_AllergyCard — renderizado', () {
    testWidgets('muestra el nombre del alérgeno', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Aspirina'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('Aspirina'), findsOneWidget);
    });

    testWidgets('muestra la etiqueta de categoría correcta', (tester) async {
      final record = _record([
        _allergy(category: '02', allergen: 'Maní'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('Alimento'), findsOneWidget);
    });

    testWidgets('muestra botón eliminar por cada ítem', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Aspirina'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('NO muestra sección REACCIÓN cuando reaction es null',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: null),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets('NO muestra sección REACCIÓN cuando reaction está vacía',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: ''),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets('SÍ muestra sección REACCIÓN cuando reaction tiene texto',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: 'Urticaria'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('REACCIÓN'), findsOneWidget);
      expect(find.text('Urticaria'), findsOneWidget);
    });
  });

  // ── Group 4: Interaction — Add button ───────────────────────────────────
  group('ProfileTabAllergies — botón Agregar', () {
    testWidgets('tap en "Agregar alergia" llama onAdd una vez', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(_wrap(
        record: _record([]),
        onAdd: () => callCount++,
      ));

      await tester.tap(find.text('Agregar alergia'));
      await tester.pumpAndSettle();

      expect(callCount, equals(1));
    });

    testWidgets('tap doble en "Agregar alergia" llama onAdd dos veces',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(_wrap(
        record: _record([]),
        onAdd: () => callCount++,
      ));

      await tester.tap(find.text('Agregar alergia'));
      await tester.tap(find.text('Agregar alergia'));
      await tester.pumpAndSettle();

      expect(callCount, equals(2));
    });

    testWidgets('el botón tiene fondo AppColors.primary', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));

      final elevatedBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Agregar alergia'),
      );
      final style = elevatedBtn.style?.backgroundColor?.resolve({});
      expect(style, equals(AppColors.primary));
    });
  });

  // ── Group 5: Interaction — Delete button ─────────────────────────────────
  group('ProfileTabAllergies — botón Eliminar', () {
    testWidgets('tap en eliminar llama onRemove con índice 0', (tester) async {
      int? removedIndex;
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
      ]);
      await tester.pumpWidget(_wrap(
        record: record,
        onRemove: (i) => removedIndex = i,
      ));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(removedIndex, equals(0));
    });

    testWidgets('tap en segundo eliminar llama onRemove con índice 1',
        (tester) async {
      int? removedIndex;
      final record = _record([
        _allergy(category: '01', allergen: 'Primero'),
        _allergy(category: '02', allergen: 'Segundo'),
      ]);
      await tester.pumpWidget(_wrap(
        record: record,
        onRemove: (i) => removedIndex = i,
      ));

      final deleteButtons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtons.at(1));
      await tester.pumpAndSettle();

      expect(removedIndex, equals(1));
    });
  });

  // ── Group 6: List with multiple items ────────────────────────────────────
  group('ProfileTabAllergies — múltiples ítems', () {
    testWidgets('renderiza todos los alérgenos de la lista', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
        _allergy(category: '02', allergen: 'Maní'),
        _allergy(category: '05', allergen: 'Abeja'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('Penicilina'), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
      expect(find.text('Abeja'), findsOneWidget);
    });

    testWidgets('hay exactamente N botones de eliminar para N ítems',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A'),
        _allergy(category: '02', allergen: 'B'),
        _allergy(category: '03', allergen: 'C'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('NO muestra "Sin alergias registradas." con ítems', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('Sin alergias registradas.'), findsNothing);
    });

    testWidgets('ítem con reaction visible + ítem sin reaction',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A', reaction: 'Anafilaxia'),
        _allergy(category: '02', allergen: 'B', reaction: null),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('REACCIÓN'), findsOneWidget);
      expect(find.text('Anafilaxia'), findsOneWidget);
    });

    testWidgets('categorías de cada ítem se muestran correctamente',
        (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A'),
        _allergy(category: '06', allergen: 'B'),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('Medicamento'), findsOneWidget);
      expect(find.text('Otra'), findsOneWidget);
    });
  });
}