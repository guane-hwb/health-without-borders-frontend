// test/widget/features/nfc/profile/tabs/profile_tab_allergies_widget_test.dart
//
// Widget testing for ProfileTabAllergies.
// Covers what the Flutter widget tree DOES require:
//   • Empty state — text "No allergies registered."
//   • Allergy counter in the header (ALLERGIES · N)
//   • Correct rendering of each AllergyCard
//   • Visibility of the REACTION section based on null/present reaction
//   • "Add Allergy" button — visible and functional
//   • Delete button — triggers onRemove with the correct index
//   • List with multiple items — all rendered

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_allergies.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
AllergyInfo _allergy({
  required String category,
  required String allergen,
  String? reaction,
}) => AllergyInfo(category: category, allergen: allergen, reaction: reaction);

PatientFullRecord _record(List<AllergyInfo> allergies) => PatientFullRecord(
  patientId: 'p-001',
  deviceUid: 'dev-001',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'TI',
      documentNumber: '1234',
    ),
    firstName: 'Test',
    firstLastName: 'Patient',
    dob: '2010-01-01',
    biologicalSex: 'F',
    address: Address(city: 'Bogotá', state: 'Cundinamarca'),
  ),
  guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
  allergies: allergies,
);

/// Wrap the widget with AppLocale to make AppStrings.of(context) work.
Widget _wrap({
  required PatientFullRecord record,
  String locale = 'es',
  VoidCallback? onAdd,
  void Function(int)? onRemove,
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: ProfileTabAllergies(
          draft: record,
          onAdd: onAdd ?? () {},
          onRemove: onRemove ?? (_) {},
        ),
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
    testWidgets('ES: muestra "Sin alergias registradas."', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      expect(find.text('Sin alergias registradas.'), findsOneWidget);
    });

    testWidgets('EN: muestra "No allergies registered."', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      expect(find.text('No allergies registered.'), findsOneWidget);
    });

    testWidgets('ES: NO muestra botón de eliminar con lista vacía', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('botón Agregar es visible en estado vacío', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ── Group 2: Header with count ────────────────────────────────────────
  group('ProfileTabAllergies — encabezado con conteo', () {
    testWidgets('ES: muestra "ALERGIAS · 0" con lista vacía', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      expect(find.text('ALERGIAS · 0'), findsOneWidget);
    });

    testWidgets('EN: muestra "ALLERGIES · 0" con lista vacía', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      expect(find.text('ALLERGIES · 0'), findsOneWidget);
    });

    testWidgets('ES: muestra "ALERGIAS · 1" con un ítem', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('ALERGIAS · 1'), findsOneWidget);
    });

    testWidgets('EN: muestra "ALLERGIES · 1" con un ítem', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicillin'),
      ]);
      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      expect(find.text('ALLERGIES · 1'), findsOneWidget);
    });

    testWidgets('ES: muestra "ALERGIAS · 3" con tres ítems', (tester) async {
      final record = _record([
        _allergy(category: '01', allergen: 'Penicilina'),
        _allergy(category: '02', allergen: 'Maní'),
        _allergy(category: '05', allergen: 'Abeja'),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('ALERGIAS · 3'), findsOneWidget);
    });

    testWidgets('encabezado tiene ícono warning_amber_rounded', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
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

  // ── Group 3: _AllergyCard — rendering ───────────────────────────────────
  group('_AllergyCard — renderizado', () {
    testWidgets('muestra el nombre del alérgeno', (tester) async {
      final record = _record([_allergy(category: '01', allergen: 'Aspirina')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Aspirina'), findsOneWidget);
    });

    testWidgets('muestra la etiqueta de categoría correcta', (tester) async {
      final record = _record([_allergy(category: '02', allergen: 'Maní')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Alimento'), findsOneWidget);
    });

    testWidgets('ES: categoría 01 → "Medicamento"', (tester) async {
      final record = _record([_allergy(category: '01', allergen: 'X')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Medicamento'), findsOneWidget);
    });

    testWidgets('EN: categoría 01 → "Medication"', (tester) async {
      final record = _record([_allergy(category: '01', allergen: 'X')]);
      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      expect(find.text('Medication'), findsOneWidget);
    });

    testWidgets('ES: categoría 02 → "Alimento"', (tester) async {
      final record = _record([_allergy(category: '02', allergen: 'Maní')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Alimento'), findsOneWidget);
    });

    testWidgets('EN: categoría 02 → "Food"', (tester) async {
      final record = _record([_allergy(category: '02', allergen: 'Peanut')]);
      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('ES: categoría 03 → "Sust. ambiente"', (tester) async {
      final record = _record([_allergy(category: '03', allergen: 'Polen')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Sust. ambiente'), findsOneWidget);
    });

    testWidgets('ES: categoría 04 → "Sust. piel"', (tester) async {
      final record = _record([_allergy(category: '04', allergen: 'Látex')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Sust. piel'), findsOneWidget);
    });

    testWidgets('ES: categoría 05 → "Picadura"', (tester) async {
      final record = _record([_allergy(category: '05', allergen: 'Abeja')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Picadura'), findsOneWidget);
    });

    testWidgets('ES: categoría 06 → "Otra"', (tester) async {
      final record = _record([_allergy(category: '06', allergen: 'X')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Otra'), findsOneWidget);
    });

    testWidgets('muestra botón eliminar por cada ítem', (tester) async {
      final record = _record([_allergy(category: '01', allergen: 'Aspirina')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  // ── Group 4: REACTION Section─────────────────────────────────────────────
  group('_AllergyCard — sección REACCIÓN', () {
    testWidgets('ES: NO muestra "REACCIÓN" cuando reaction es null', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: null),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets('ES: NO muestra "REACCIÓN" cuando reaction es vacío', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: ''),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets(
      'ES: SÍ muestra "REACCIÓN" y su texto cuando reaction tiene valor',
      (tester) async {
        final record = _record([
          _allergy(category: '01', allergen: 'X', reaction: 'Urticaria'),
        ]);
        await tester.pumpWidget(_wrap(record: record));
        expect(find.text('REACCIÓN'), findsOneWidget);
        expect(find.text('Urticaria'), findsOneWidget);
      },
    );

    testWidgets('EN: muestra "REACTION" cuando reaction tiene valor', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: 'Urticaria'),
      ]);
      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      expect(find.text('REACTION'), findsOneWidget);
      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets(
      'ítem con reaction y otro sin reaction: solo uno muestra la sección',
      (tester) async {
        final record = _record([
          _allergy(category: '01', allergen: 'A', reaction: 'Anafilaxia'),
          _allergy(category: '02', allergen: 'B', reaction: null),
        ]);
        await tester.pumpWidget(_wrap(record: record));
        expect(find.text('REACCIÓN'), findsOneWidget);
        expect(find.text('Anafilaxia'), findsOneWidget);
      },
    );
  });

  // ── Group 5: Add Button ────────────────────────────────────────────────
  group('ProfileTabAllergies — botón Agregar', () {
    testWidgets('ES: muestra "Agregar alergia"', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      expect(find.text('Agregar alergia'), findsOneWidget);
    });

    testWidgets('EN: muestra "Add allergy"', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      expect(find.text('Add allergy'), findsOneWidget);
    });

    testWidgets('tap en el botón llama onAdd una vez', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(record: _record([]), onAdd: () => callCount++),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(callCount, equals(1));
    });

    testWidgets('tap doble llama onAdd dos veces', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(record: _record([]), onAdd: () => callCount++),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(callCount, equals(2));
    });

    testWidgets('el botón tiene fondo AppColors.primary', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([])));
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithIcon(ElevatedButton, Icons.add),
      );
      final bg = btn.style?.backgroundColor?.resolve({});
      expect(bg, equals(AppColors.primary));
    });
  });

  // ── Group 6: Delete Button ────────────────────────────────────────────────
  group('ProfileTabAllergies — botón Eliminar', () {
    testWidgets('tap en eliminar llama onRemove con índice 0', (tester) async {
      int? removed;
      final record = _record([_allergy(category: '01', allergen: 'A')]);
      await tester.pumpWidget(
        _wrap(record: record, onRemove: (i) => removed = i),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(removed, equals(0));
    });

    testWidgets('tap en segundo eliminar llama onRemove con índice 1', (
      tester,
    ) async {
      int? removed;
      final record = _record([
        _allergy(category: '01', allergen: 'Primero'),
        _allergy(category: '02', allergen: 'Segundo'),
      ]);
      await tester.pumpWidget(
        _wrap(record: record, onRemove: (i) => removed = i),
      );
      final btns = find.byIcon(Icons.delete_outline);
      await tester.tap(btns.at(1));
      await tester.pumpAndSettle();
      expect(removed, equals(1));
    });
  });

  // ── Group 7: Multiple items ──────────────────────────────────────────────
  group('ProfileTabAllergies — múltiples ítems', () {
    testWidgets('todos los alérgenos se renderizan', (tester) async {
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

    testWidgets('hay exactamente N botones eliminar para N ítems', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A'),
        _allergy(category: '02', allergen: 'B'),
        _allergy(category: '03', allergen: 'C'),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('NO muestra texto de lista vacía cuando hay ítems', (
      tester,
    ) async {
      final record = _record([_allergy(category: '01', allergen: 'A')]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Sin alergias registradas.'), findsNothing);
    });

    testWidgets('ítem con reaction visible + ítem sin reaction', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A', reaction: 'Anafilaxia'),
        _allergy(category: '02', allergen: 'B', reaction: null),
      ]);
      await tester.pumpWidget(_wrap(record: record));

      expect(find.text('REACCIÓN'), findsOneWidget);
      expect(find.text('Anafilaxia'), findsOneWidget);
    });

    testWidgets('categorías distintas se muestran correctamente en ES', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'A'),
        _allergy(category: '06', allergen: 'B'),
      ]);
      await tester.pumpWidget(_wrap(record: record));
      expect(find.text('Medicamento'), findsOneWidget);
      expect(find.text('Otra'), findsOneWidget);
    });
  });

  // ── Group 8: Language change ES ↔ EN ─────────────────────────────────────
  group('ProfileTabAllergies — cambio de idioma', () {
    testWidgets('botón ES: "Agregar alergia", EN: "Add allergy"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'es'));
      expect(find.text('Agregar alergia'), findsOneWidget);
      expect(find.text('Add allergy'), findsNothing);

      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Add allergy'), findsOneWidget);
      expect(find.text('Agregar alergia'), findsNothing);
    });

    testWidgets('encabezado ES: "ALERGIAS · 0", EN: "ALLERGIES · 0"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'es'));
      expect(find.text('ALERGIAS · 0'), findsOneWidget);

      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('ALLERGIES · 0'), findsOneWidget);
    });

    testWidgets('texto vacío ES / EN cambia correctamente', (tester) async {
      await tester.pumpWidget(_wrap(record: _record([]), locale: 'es'));
      expect(find.text('Sin alergias registradas.'), findsOneWidget);

      await tester.pumpWidget(_wrap(record: _record([]), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('No allergies registered.'), findsOneWidget);
    });

    testWidgets('sección reacción ES: "REACCIÓN", EN: "REACTION"', (
      tester,
    ) async {
      final record = _record([
        _allergy(category: '01', allergen: 'X', reaction: 'Urticaria'),
      ]);

      await tester.pumpWidget(_wrap(record: record, locale: 'es'));
      expect(find.text('REACCIÓN'), findsOneWidget);
      expect(find.text('REACTION'), findsNothing);

      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('REACTION'), findsOneWidget);
      expect(find.text('REACCIÓN'), findsNothing);
    });

    testWidgets('categoría 01 ES: "Medicamento", EN: "Medication"', (
      tester,
    ) async {
      final record = _record([_allergy(category: '01', allergen: 'X')]);

      await tester.pumpWidget(_wrap(record: record, locale: 'es'));
      expect(find.text('Medicamento'), findsOneWidget);

      await tester.pumpWidget(_wrap(record: record, locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Medication'), findsOneWidget);
    });
  });
}
