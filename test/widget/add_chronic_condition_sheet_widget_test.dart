// test/widget/add_chronic_condition_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_chronic_condition_sheet.dart';

Widget _wrap(Widget child, {String locale = 'en'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _buildSubject({required ValueChanged<ChronicConditionItem> onAdd}) {
  return _wrap(AddChronicConditionSheet(onAdd: onAdd));
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

  group('AddChronicConditionSheet – Base Rendering', () {
    testWidgets(
      'renders layout safely without throwing runtime locale exceptions',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        expect(find.byType(AddChronicConditionSheet), findsOneWidget);
      },
    );

    testWidgets(
      'text input field area is present and renders completely empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        expect(
          tester.widget<TextField>(textField).controller?.text ?? '',
          isEmpty,
        );
      },
    );

    testWidgets(
      'action commit confirm button stays disabled while input text is empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        await tester.pump();

        final confirmButtonFinder = find.byWidgetPredicate(
          (widget) => widget is ElevatedButton && widget.onPressed == null,
        );
        expect(confirmButtonFinder, findsOneWidget);
      },
    );
  });

  group('AddChronicConditionSheet – VoiceTextArea Input Mutations', () {
    testWidgets(
      'writing alphanumeric characters refreshes internal visibility states',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Diabetes tipo 2');
        await tester.pump();

        expect(find.text('Diabetes tipo 2'), findsOneWidget);
      },
    );

    testWidgets(
      'submitting whitespace characters skips activating action buttons',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        final confirmButtons = find.byWidgetPredicate(
          (w) => w is ElevatedButton && w.onPressed != null,
        );
        expect(confirmButtons, findsNothing);
      },
    );

    testWidgets(
      'submitting populated criteria activates action buttons safely',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final activeButton = find.byWidgetPredicate(
          (w) => w is ElevatedButton && w.onPressed != null,
        );
        expect(activeButton, findsOneWidget);
      },
    );

    testWidgets('clearing a field triggers button inactivation layout cycles', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

      await tester.enterText(find.byType(TextField), 'Asma');
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final activeButton = find.byWidgetPredicate(
        (w) => w is ElevatedButton && w.onPressed != null,
      );
      expect(activeButton, findsNothing);
    });
  });

  group('AddChronicConditionSheet – onConfirm Pipeline Operations', () {
    testWidgets(
      'forwards structured trimmed entry records inside callbacks upon confirmation click',
      (tester) async {
        ChronicConditionItem? received;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), '  Lupus  ');
        await tester.pump();

        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ElevatedButton && w.onPressed != null,
          ),
        );
        await tester.pumpAndSettle();

        expect(received, isNotNull);
        expect(received!.chronicDescription, 'Lupus');
      },
    );

    testWidgets(
      'retains multiline strings keeping internal linebreaks intact during submission pipelines',
      (tester) async {
        ChronicConditionItem? received;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(
          find.byType(TextField),
          'Enfermedad de Crohn\nEstadio avanzado',
        );
        await tester.pump();

        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ElevatedButton && w.onPressed != null,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          received?.chronicDescription,
          'Enfermedad de Crohn\nEstadio avanzado',
        );
      },
    );

    testWidgets(
      'closes modal structure systematically after confirming text entries',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        _wrap(AddChronicConditionSheet(onAdd: (_) {})),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Fibromialgia');
        await tester.pump();

        await tester.tap(
          find
              .byWidgetPredicate(
                (w) => w is ElevatedButton && w.onPressed != null,
              )
              .last,
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );
  });

  group('AddChronicConditionSheet – Component Lifecycle Execution', () {
    testWidgets(
      'tears down instances and resources gracefully during standard unmount flows',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );
  });

  group('AddChronicConditionSheet – Operational Boundary Limits', () {
    testWidgets(
      'processes extremely long strings flawlessly without truncating boundaries',
      (tester) async {
        ChronicConditionItem? received;
        final longText = 'A' * 500;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), longText);
        await tester.pump();

        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ElevatedButton && w.onPressed != null,
          ),
        );
        await tester.pumpAndSettle();

        expect(received?.chronicDescription.length, 500);
      },
    );

    testWidgets(
      'retains customized accentuation modifiers and unique formatting markers',
      (tester) async {
        ChronicConditionItem? received;
        const special = 'Síndrome de Sjögren – afección crónica';

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), special);
        await tester.pump();

        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is ElevatedButton && w.onPressed != null,
          ),
        );
        await tester.pumpAndSettle();

        expect(received?.chronicDescription, special);
      },
    );
  });
}
