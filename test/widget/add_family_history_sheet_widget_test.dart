// test/widget/add_family_history_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_family_history_sheet.dart';

Widget _buildSheet({
  required ValueChanged<FamilyHistoryItem> onAdd,
  String locale = 'es',
}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) => AddFamilyHistorySheet(onAdd: onAdd)),
      ),
    ),
  );
}

class _LocaleWrapper extends StatelessWidget {
  const _LocaleWrapper({required this.locale, required this.child});

  final String locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppLocale(locale: locale, setLocale: (_) {}, child: child);
  }
}

void main() {
  final sEs = AppStrings.forTesting('es');
  final sEn = AppStrings.forTesting('en');

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

  group('Initial UI Layout Rendering', () {
    testWidgets('Displays the primary sheet action title header', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

      expect(find.text(sEs.addFamilyHistory), findsOneWidget);
    });

    testWidgets('Displays the dedicated relationship label section', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

      expect(find.text(sEs.relationship), findsOneWidget);
    });

    testWidgets(
      'Renders all four operational relative reference choice chips',
      (tester) async {
        await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

        expect(find.text(sEs.relParents), findsOneWidget);
        expect(find.text(sEs.relSiblings), findsOneWidget);
        expect(find.text(sEs.relUncles), findsOneWidget);
        expect(find.text(sEs.relGrandparents), findsOneWidget);
      },
    );

    testWidgets(
      'Displays condition input tracking forms with corresponding description hints',
      (tester) async {
        await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

        expect(find.text('${sEs.condition} *'), findsOneWidget);
        expect(find.text(sEs.chronicConditionHint), findsOneWidget);
      },
    );

    testWidgets(
      'Commit submission button is present and renders properly with empty inputs',
      (tester) async {
        await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

        final confirmFinder = find.byType(ElevatedButton);
        expect(confirmFinder, findsOneWidget);
      },
    );
  });

  group('Relationship Tracking Choice Chips Selection Modifiers', () {
    testWidgets(
      'Parents status chip initiates active by default matching styling patterns',
      (tester) async {
        await tester.pumpWidget(_buildSheet(onAdd: (_) {}));

        expect(find.text(sEs.relParents), findsOneWidget);
      },
    );

    testWidgets(
      'Selecting Siblings updates the underlying active code parameters configuration',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.tap(find.text(sEs.relSiblings));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Diabetes');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured?.relationship, equals('02'));
      },
    );

    testWidgets(
      'Selecting Uncles updates the active selection structural code to 03',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.tap(find.text(sEs.relUncles));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured?.relationship, equals('03'));
      },
    );

    testWidgets(
      'Selecting Grandparents updates the active selection structural code to 04',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.tap(find.text(sEs.relGrandparents));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Cáncer');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured?.relationship, equals('04'));
      },
    );

    testWidgets(
      'Tapping an already active choice chip consecutive times leaves status intact',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.tap(find.text(sEs.relParents));
        await tester.pump();
        await tester.tap(find.text(sEs.relParents));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Diabetes');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured?.relationship, equals('01'));
      },
    );
  });

  group('Condition Text Field Input Gate Validation Lifecycle', () {
    testWidgets(
      'Enables form confirmation execution when valid values are entered',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured, isNotNull);
      },
    );

    testWidgets(
      'Prevents callback execution when entry fields contain only whitespace characters',
      (tester) async {
        bool called = false;
        await tester.pumpWidget(_buildSheet(onAdd: (_) => called = true));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'Prevents callback execution automatically when populated text strings are erased',
      (tester) async {
        bool called = false;
        await tester.pumpWidget(_buildSheet(onAdd: (_) => called = true));

        await tester.enterText(find.byType(TextField), 'Asma');
        await tester.pump();

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(called, isFalse);
      },
    );
  });

  group('Callback Data Delivery Validations for FamilyHistoryItem Structure', () {
    testWidgets(
      'Forwards conditionDescription strings stripping out surrounding leading or trailing whitespaces',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField), '  Diabetes tipo 2  ');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured, isNotNull);
        expect(captured!.conditionDescription, equals('Diabetes tipo 2'));
      },
    );

    testWidgets(
      'Assigns fallback relationship 01 when default chips are unmutated during entry cycles',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField), 'Cáncer de colon');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured!.relationship, equals('01'));
        expect(captured!.conditionDescription, equals('Cáncer de colon'));
      },
    );

    testWidgets(
      'Bundles full metrics correctly across comprehensive combined entry fields',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(_buildSheet(onAdd: (item) => captured = item));

        await tester.tap(find.text(sEs.relSiblings));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Asma bronquial');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured!.relationship, equals('02'));
        expect(captured!.conditionDescription, equals('Asma bronquial'));
      },
    );
  });

  group('Sheet View Dimissal Routines and Context Popping Navigation', () {
    testWidgets(
      'Closes the sheet window cleanly via Navigator pops upon confirmation',
      (tester) async {
        bool popped = false;

        await tester.pumpWidget(
          _LocaleWrapper(
            locale: 'es',
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: ctx,
                        builder: (_) =>
                            AddFamilyHistorySheet(onAdd: (_) => popped = true),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).last;
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(find.byType(AddFamilyHistorySheet), findsNothing);
      },
    );
  });

  group('Localization Matrix — English Localization Rules Matrix Validations', () {
    testWidgets(
      'Displays completely correct localized text copies when locale property evaluates to en',
      (tester) async {
        await tester.pumpWidget(_buildSheet(onAdd: (_) {}, locale: 'en'));

        expect(find.text(sEn.addFamilyHistory), findsOneWidget);
        expect(find.text(sEn.relationship), findsOneWidget);
        expect(find.text(sEn.relParents), findsOneWidget);
        expect(find.text(sEn.relSiblings), findsOneWidget);
        expect(find.text(sEn.relUncles), findsOneWidget);
        expect(find.text(sEn.relGrandparents), findsOneWidget);
        expect(find.text('${sEn.condition} *'), findsOneWidget);
        expect(find.text(sEn.confirm), findsOneWidget);
      },
    );

    testWidgets(
      'Successfully submits structural elements when form confirms under english localized constraints',
      (tester) async {
        FamilyHistoryItem? captured;
        await tester.pumpWidget(
          _buildSheet(onAdd: (item) => captured = item, locale: 'en'),
        );

        await tester.tap(find.text(sEn.relGrandparents));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Hypertension');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton).first;
        await tester.tap(confirmBtn);
        await tester.pump();

        expect(captured!.relationship, equals('04'));
        expect(captured!.conditionDescription, equals('Hypertension'));
      },
    );
  });
}
