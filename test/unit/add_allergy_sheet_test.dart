// test/src/features/nfc/presentation/profile/sheets/add_allergy_sheet_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';

Widget _wrap(Widget child, {String locale = 'en'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required ValueChanged<AllergyInfo> onAdd,
}) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => AddAllergySheet(onAdd: onAdd),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1600,
      1200,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('AddAllergySheet — rendering', () {
    testWidgets('renders all six category chips', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      expect(find.text('Medication'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Environmental substance'), findsOneWidget);
      expect(find.text('Skin substance'), findsOneWidget);
      expect(find.text('Insect sting'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('renders allergen TextField with warning icon', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('confirm button is disabled when allergen is empty', (
      tester,
    ) async {
      await _pumpSheet(tester, onAdd: (_) {});

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithIcon(ElevatedButton, Icons.add),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('confirm button is enabled once allergen has text', (
      tester,
    ) async {
      await _pumpSheet(tester, onAdd: (_) {});

      await tester.enterText(find.byType(TextField).first, 'Penicillin');
      await tester.pump();

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithIcon(ElevatedButton, Icons.add),
      );
      expect(confirmBtn.onPressed, isNotNull);
    });
  });

  group('AddAllergySheet — category chip selection', () {
    testWidgets('first chip (Medication / 01) is selected by default', (
      tester,
    ) async {
      await _pumpSheet(tester, onAdd: (_) {});

      final selectedChipFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.error &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.text('Medication'),
                )
                .evaluate()
                .isNotEmpty,
      );

      expect(selectedChipFinder, findsWidgets);
    });

    testWidgets('tapping a chip deselects the previous one', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      await tester.tap(find.text('Food'));
      await tester.pump();

      final selectedFoodChipFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.error &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.text('Food'),
                )
                .evaluate()
                .isNotEmpty,
      );

      final unselectedMedChipFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.white &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.text('Medication'),
                )
                .evaluate()
                .isNotEmpty,
      );

      expect(selectedFoodChipFinder, findsWidgets);
      expect(unselectedMedChipFinder, findsWidgets);
    });

    for (final entry in {
      'Medication': '01',
      'Food': '02',
      'Environmental substance': '03',
      'Skin substance': '04',
      'Insect sting': '05',
      'Other': '06',
    }.entries) {
      testWidgets('tapping "${entry.key}" sets category to ${entry.value}', (
        tester,
      ) async {
        AllergyInfo? captured;

        await _pumpSheet(tester, onAdd: (info) => captured = info);

        await tester.tap(find.text(entry.key));
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Test');
        await tester.pump();

        await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
        await tester.pumpAndSettle();

        expect(captured?.category, entry.value);
      });
    }
  });

  group('AddAllergySheet — allergen field', () {
    testWidgets('trims whitespace before calling onAdd', (tester) async {
      AllergyInfo? captured;

      await _pumpSheet(tester, onAdd: (info) => captured = info);

      await tester.enterText(find.byType(TextField).first, '  Aspirin  ');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(captured?.allergen, 'Aspirin');
    });

    testWidgets('confirm button remains disabled for whitespace-only input', (
      tester,
    ) async {
      await _pumpSheet(tester, onAdd: (_) {});

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithIcon(ElevatedButton, Icons.add),
      );
      expect(confirmBtn.onPressed, isNull);
    });
  });

  group('AddAllergySheet — reaction field', () {
    testWidgets('reaction is null when field is left empty', (tester) async {
      AllergyInfo? captured;

      await _pumpSheet(tester, onAdd: (info) => captured = info);

      await tester.enterText(find.byType(TextField).first, 'Penicillin');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(captured?.reaction, isNull);
    });

    testWidgets('reaction is null when field contains only whitespace', (
      tester,
    ) async {
      AllergyInfo? captured;

      await _pumpSheet(tester, onAdd: (info) => captured = info);

      await tester.enterText(find.byType(TextField).first, 'Penicillin');
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(captured?.reaction, isNull);
    });

    testWidgets('reaction is passed trimmed when provided', (tester) async {
      AllergyInfo? captured;

      await _pumpSheet(tester, onAdd: (info) => captured = info);

      await tester.enterText(find.byType(TextField).first, 'Penicillin');
      await tester.enterText(find.byType(TextField).last, '  Hives and rash  ');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(captured?.reaction, 'Hives and rash');
    });

    testWidgets('reaction field accepts multiline text', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      final reactionField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(reactionField.maxLines, 3);
    });
  });

  group('AddAllergySheet — onAdd callback & navigation', () {
    testWidgets('onAdd is called exactly once on confirm', (tester) async {
      var callCount = 0;

      await _pumpSheet(tester, onAdd: (_) => callCount++);

      await tester.enterText(find.byType(TextField).first, 'Latex');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets('sheet is dismissed after confirm', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      await tester.enterText(find.byType(TextField).first, 'Latex');
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AddAllergySheet), findsNothing);
    });

    testWidgets(
      'full happy-path: category + allergen + reaction are forwarded correctly',
      (tester) async {
        AllergyInfo? captured;

        await _pumpSheet(tester, onAdd: (info) => captured = info);

        await tester.tap(find.text('Food'));
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Peanuts');
        await tester.enterText(find.byType(TextField).last, 'Anaphylaxis');
        await tester.pump();

        await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add));
        await tester.pumpAndSettle();

        expect(captured?.category, '02');
        expect(captured?.allergen, 'Peanuts');
        expect(captured?.reaction, 'Anaphylaxis');
      },
    );
  });

  group('AddAllergySheet — widget lifecycle', () {
    testWidgets('disposes controllers without errors', (tester) async {
      await _pumpSheet(tester, onAdd: (_) {});

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    });
  });
}
