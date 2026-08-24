// test/widget/step4_background_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step4_background.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';

// ─── Helper ────────────────────────────────────────────────────────────────

Widget _buildStep4({
  required RegisterDraft draft,
  VoidCallback? onBack,
  VoidCallback? onContinue,
  String locale = 'es',
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: Step4Background(
          draft: draft,
          onBack: onBack ?? () {},
          onContinue: onContinue ?? () {},
        ),
      ),
    ),
  );
}

RegisterDraft _emptyDraft() => RegisterDraft();

RegisterDraft _draftWithAll() {
  final d = RegisterDraft()
    ..chronicConditions = [ChronicConditionItem(chronicDescription: 'Diabetes')]
    ..medications = [
      MedicationStatementItem(
        medicationName: 'Ibuprofeno',
        status: 'active',
        dosage: '400mg',
      ),
    ]
    ..familyHistory = [
      FamilyHistoryItem(
        conditionDescription: 'Hipertensión',
        relationship: '01',
      ),
    ]
    ..allergies = [
      AllergyInfo(
        category: '01',
        allergen: 'Penicilina',
        reaction: 'Urticaria',
      ),
    ]
    ..personalHistory = 'Cirugía 2020';
  return d;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  void resizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
  }

  group('Step4Background — renderizado con listas vacías (ES)', () {
    testWidgets('muestra _EmptyCard para condiciones crónicas', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      expect(
        find.text('Sin condiciones crónicas. Toque "Agregar".'),
        findsOneWidget,
      );
    });

    testWidgets('muestra _EmptyCard para medicamentos', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      expect(
        find.text('Sin medicamentos registrados. Toque "Agregar".'),
        findsOneWidget,
      );
    });

    testWidgets('muestra _EmptyCard para antecedentes familiares', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      expect(
        find.text('Sin antecedentes familiares. Toque "Agregar".'),
        findsOneWidget,
      );
    });

    testWidgets('no muestra ningún _ItemCard con listas vacías', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  group('Step4Background — renderizado con listas vacías (EN)', () {
    testWidgets('muestra _EmptyCard EN para condiciones crónicas', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      expect(find.text('No chronic conditions. Tap "Add".'), findsOneWidget);
    });

    testWidgets('muestra _EmptyCard EN para medicamentos', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      expect(
        find.text('No medications registered. Tap "Add".'),
        findsOneWidget,
      );
    });

    testWidgets('muestra _EmptyCard EN para antecedentes familiares', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      expect(
        find.text('No family history entries yet. Tap "Add".'),
        findsOneWidget,
      );
    });

    testWidgets('muestra _EmptyCard EN para allergies', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      expect(find.text('No allergies registered. Tap "Add".'), findsOneWidget);
    });
  });

  group('Step4Background — _ItemCard con ítems pre-poblados', () {
    testWidgets('muestra título de condición crónica', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.text('Diabetes'), findsOneWidget);
    });

    testWidgets('muestra nombre de medicamento', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.text('Ibuprofeno'), findsOneWidget);
    });

    testWidgets('muestra subtitle de medicamento con dosage', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.textContaining('400mg'), findsOneWidget);
    });

    testWidgets('muestra descripción de antecedente familiar', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.text('Hipertensión'), findsOneWidget);
    });

    testWidgets('muestra alergeno', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.text('Penicilina'), findsOneWidget);
    });

    testWidgets('muestra subtitle de alergia con reaction', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Urticaria'), findsOneWidget);
    });

    testWidgets('hay 4 botones delete (uno por sección)', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(4));
    });

    testWidgets('personalHistory pre-poblado aparece en el VoiceTextArea', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _draftWithAll()));
      await tester.pumpAndSettle();
      expect(find.text('Cirugía 2020'), findsOneWidget);
    });
  });

  group('Step4Background — eliminación de ítems', () {
    testWidgets(
      'eliminar condición crónica → lista vacía → _EmptyCard visible',
      (tester) async {
        resizeViewport(tester);
        final draft = RegisterDraft()
          ..chronicConditions = [
            ChronicConditionItem(chronicDescription: 'Asma'),
          ];
        await tester.pumpWidget(_buildStep4(draft: draft));
        await tester.pumpAndSettle();

        expect(find.text('Asma'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();

        expect(find.text('Asma'), findsNothing);
        expect(
          find.text('Sin condiciones crónicas. Toque "Agregar".'),
          findsOneWidget,
        );
        expect(draft.chronicConditions, isEmpty);
      },
    );

    testWidgets('eliminar medicamento → lista vacía → _EmptyCard visible', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..medications = [
          MedicationStatementItem(medicationName: 'Aspirina', status: 'active'),
        ];
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(draft.medications, isEmpty);
      expect(
        find.text('Sin medicamentos registrados. Toque "Agregar".'),
        findsOneWidget,
      );
    });

    testWidgets('eliminar antecedente familiar → lista vacía', (tester) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..familyHistory = [
          FamilyHistoryItem(conditionDescription: 'Cáncer', relationship: '02'),
        ];
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(draft.familyHistory, isEmpty);
    });

    testWidgets('eliminar alergia → lista vacía', (tester) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..allergies = [AllergyInfo(category: '02', allergen: 'Maní')];
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(draft.allergies, isEmpty);
    });
  });

  group('Step4Background — _save()', () {
    testWidgets('pulsar Continuar llama a onContinue', (tester) async {
      resizeViewport(tester);
      bool called = false;
      await tester.pumpWidget(
        _buildStep4(draft: _emptyDraft(), onContinue: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('personalHistory vacío → null en el draft', (tester) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(draft.personalHistory, isNull);
    });

    testWidgets('personalHistory con texto → guardado con trim', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '  Cirugía 2019  ');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(draft.personalHistory, 'Cirugía 2019');
    });
  });

  group('Step4Background — onBack', () {
    testWidgets('pulsar Atrás llama al callback onBack', (tester) async {
      resizeViewport(tester);
      bool called = false;
      await tester.pumpWidget(
        _buildStep4(draft: _emptyDraft(), onBack: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  group('_AddChronicConditionSheet — canConfirm y flow', () {
    Future<void> openChronicSheet(WidgetTester tester) async {
      final addButtons = find.text('Agregar');
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();
    }

    testWidgets('sheet se abre al tocar Agregar', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openChronicSheet(tester);

      expect(find.text('Agregar condición crónica'), findsOneWidget);
    });

    testWidgets('botón confirmar deshabilitado con campo vacío', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openChronicSheet(tester);

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('botón confirmar habilitado al escribir texto', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openChronicSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Diabetes');
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('confirmar condición la agrega al draft', (tester) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();
      await openChronicSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Artritis');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(draft.chronicConditions, hasLength(1));
      expect(draft.chronicConditions.first.chronicDescription, 'Artritis');
    });

    testWidgets('botón close de _Sheet cierra sin agregar ítem', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();
      await openChronicSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Algo');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(draft.chronicConditions, isEmpty);
    });
  });

  group('_AddMedicationSheet — flow', () {
    Future<void> openMedSheet(WidgetTester tester) async {
      final addBtns = find.text('Agregar');
      await tester.tap(addBtns.at(1));
      await tester.pumpAndSettle();
    }

    testWidgets('botón confirmar deshabilitado con nombre vacío', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openMedSheet(tester);

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(btn.onPressed, isNull);
    });
  });

  group('_AddFamilyHistorySheet — flow', () {
    Future<void> openFHSheet(WidgetTester tester) async {
      final addBtns = find.text('Agregar');
      await tester.tap(addBtns.at(2));
      await tester.pumpAndSettle();
    }

    testWidgets('sheet se abre', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openFHSheet(tester);

      expect(find.text('Agregar antecedente familiar'), findsOneWidget);
    });

    testWidgets('confirmar antecedente familiar lo agrega al draft', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();
      await openFHSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Cáncer de colon');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(draft.familyHistory, hasLength(1));
      expect(draft.familyHistory.first.conditionDescription, 'Cáncer de colon');
    });

    testWidgets('relationship default al confirmar es 01', (tester) async {
      resizeViewport(tester);
      final draft = _emptyDraft();
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();
      await openFHSheet(tester);

      await tester.enterText(find.byType(TextField).last, 'Diabetes');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(draft.familyHistory.first.relationship, '01');
    });
  });

  group('_AddAllergySheet — flow', () {
    Future<void> openAllergySheet(WidgetTester tester) async {
      final addBtns = find.text('Agregar');
      await tester.tap(addBtns.last);
      await tester.pumpAndSettle();
    }

    testWidgets('botón confirmar deshabilitado con alergeno vacío', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();
      await openAllergySheet(tester);

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(btn.onPressed, isNull);
    });
  });

  group('_EmptyCard — estilos', () {
    testWidgets('texto tiene fontSize 12 y color textSecondary', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(
        find.text('Sin condiciones crónicas. Toque "Agregar".'),
      );
      expect(text.style?.fontSize, 12);
      expect(text.style?.color, AppColors.textSecondary);
    });
  });

  group('_ItemCard — estilos', () {
    testWidgets('título tiene fontSize 13 y fontWeight w600', (tester) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..chronicConditions = [
          ChronicConditionItem(chronicDescription: 'Asma'),
        ];
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Asma'));
      expect(titleText.style?.fontSize, 13);
      expect(titleText.style?.fontWeight, FontWeight.w600);
    });
  });

  group('Step4Background — locale EN', () {
    testWidgets('continueBtn en inglés está presente', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('back en inglés está presente', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('subtítulo de personalHistory section en EN', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft(), locale: 'en'));
      await tester.pumpAndSettle();
      expect(
        find.text('Surgical history, hospitalizations, etc.'),
        findsOneWidget,
      );
    });
  });

  group('Step4Background — dispose', () {
    testWidgets('no lanza excepciones al desmontar el widget', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(_buildStep4(draft: _emptyDraft()));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    });
  });

  group('_Step4State — inicialización de _personal controller', () {
    testWidgets('personalHistory previo pre-popula el VoiceTextArea', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..personalHistory = 'Apendicectomía 2018';
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Apendicectomía 2018'), findsOneWidget);
    });

    testWidgets('personalHistory null → VoiceTextArea vacío', (tester) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..personalHistory = null;
      await tester.pumpWidget(_buildStep4(draft: draft));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final ctrlTexts = textFields
          .where((tf) => tf.controller?.text.isNotEmpty == true)
          .toList();
      expect(ctrlTexts, isEmpty);
    });
  });
}
