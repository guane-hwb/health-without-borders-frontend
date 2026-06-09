// test/widget/add_medication_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_medication_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

class _LocaleWrapper extends StatelessWidget {
  const _LocaleWrapper({required this.locale, required this.child});

  final String locale;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppLocale(locale: locale, setLocale: (_) {}, child: child);
}

Widget _buildDirect({
  required ValueChanged<MedicationStatementItem> onAdd,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(body: AddMedicationSheet(onAdd: onAdd)),
  ),
);

Widget _buildViaBottomSheet({
  required ValueChanged<MedicationStatementItem> onAdd,
  VoidCallback? onClosed,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => AddMedicationSheet(onAdd: onAdd),
            ).then((_) => onClosed?.call());
          },
          child: const Text('Abrir'),
        ),
      ),
    ),
  ),
);

Finder _confirmButton() => find.byWidgetPredicate(
  (widget) => widget is ElevatedButton && widget.child is! Text,
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  final sEs = AppStrings.forTesting('es');
  final sEn = AppStrings.forTesting('en');

  group('Initial Rendering', () {
    testWidgets('Displays the expected sheet header title', (tester) async {
      await tester.pumpWidget(_buildDirect(onAdd: (_) {}));
      expect(find.text(sEs.addMedicationTitle), findsOneWidget);
    });

    testWidgets('Displays the expected sheet header subtitle description', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDirect(onAdd: (_) {}));
      expect(find.text(sEs.addMedicationSubtitle), findsOneWidget);
    });

    testWidgets(
      'Displays form input label and associated placeholder hints for Medication names',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));
        expect(find.text(sEs.medicationLabel), findsOneWidget);
        expect(find.text(sEs.medicationHint), findsOneWidget);
      },
    );

    testWidgets(
      'Displays status configuration section label alongside all four tracking chips',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.ensureVisible(find.text(sEs.statusLabel));
        expect(find.text(sEs.statusLabel), findsOneWidget);
        expect(find.text(sEs.medStatusActive), findsOneWidget);
        expect(find.text(sEs.medStatusCompleted), findsOneWidget);
        expect(find.text(sEs.medStatusStopped), findsOneWidget);
        expect(find.text(sEs.medStatusUnknown), findsOneWidget);
      },
    );

    testWidgets('Displays dosage input labels and placeholder guidelines', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

      await tester.ensureVisible(find.text(sEs.dosageLabel));
      expect(find.text(sEs.dosageLabel), findsOneWidget);
      expect(find.text(sEs.dosageHint), findsOneWidget);
    });

    testWidgets(
      'Displays general notes section title labels and associated hints',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.ensureVisible(find.text(sEs.notesLabel));
        expect(find.text(sEs.notesLabel), findsOneWidget);
        expect(find.text(sEs.notesHint), findsOneWidget);
      },
    );

    testWidgets(
      'Commit action button initializes completely disabled by default',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets('Tree instantiates exactly three operational TextFields', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

      await tester.ensureVisible(find.text(sEs.notesHint));
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });

  group('Confirm Button — Validation triggers based on medication content', () {
    testWidgets(
      'Activates confirmation button when name strings are populated',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.enterText(
          find.byType(TextField).first,
          'Metformina 850mg',
        );
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets(
      'Retains disabled button state when inputs contain only whitespace parameters',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField).first, '   ');
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      'Reverts to a disabled button layout once text strings are cleared',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField).first, 'Aspirina');
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      'Button remains disabled if dosage parameters are filled without specifying a name',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.ensureVisible(find.text(sEs.dosageHint));
        await tester.enterText(find.byType(TextField).at(1), '1 tableta/día');
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      'Button remains disabled if notes are filled without specifying a name',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}));

        await tester.ensureVisible(find.text(sEs.notesHint));
        await tester.enterText(find.byType(TextField).at(2), 'Solo notas');
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(_confirmButton());
        expect(btn.onPressed, isNull);
      },
    );
  });

  group('Status Chips — Selection updates state properties correctly', () {
    Future<MedicationStatementItem?> selectStatusAndConfirm(
      WidgetTester tester,
      String chipText,
    ) async {
      MedicationStatementItem? captured;
      await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

      await tester.ensureVisible(find.text(chipText));
      await tester.tap(find.text(chipText));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'Medicamento');
      await tester.pump();

      await tester.tap(_confirmButton());
      await tester.pump();

      return captured;
    }

    testWidgets('Initial fallback properties default to "active"', (
      tester,
    ) async {
      MedicationStatementItem? captured;
      await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

      await tester.enterText(find.byType(TextField).first, 'Aspirina');
      await tester.pump();

      await tester.tap(_confirmButton());
      await tester.pump();

      expect(captured?.status, equals('active'));
    });

    testWidgets(
      "Selecting 'Completado' updates key property to status='completed'",
      (tester) async {
        final item = await selectStatusAndConfirm(
          tester,
          sEs.medStatusCompleted,
        );
        expect(item?.status, equals('completed'));
      },
    );

    testWidgets(
      "Selecting 'Suspendido' updates key property to status='stopped'",
      (tester) async {
        final item = await selectStatusAndConfirm(tester, sEs.medStatusStopped);
        expect(item?.status, equals('stopped'));
      },
    );

    testWidgets(
      "Selecting 'Desconocido' updates key property to status='unknown'",
      (tester) async {
        final item = await selectStatusAndConfirm(tester, sEs.medStatusUnknown);
        expect(item?.status, equals('unknown'));
      },
    );

    testWidgets(
      "Re-selecting 'Activo' retains status='active' mapping values unaltered",
      (tester) async {
        final item = await selectStatusAndConfirm(tester, sEs.medStatusActive);
        expect(item?.status, equals('active'));
      },
    );

    testWidgets(
      'Tapping consecutive choice chips updates current selections: Completado → Suspendido',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.ensureVisible(find.text(sEs.medStatusCompleted));
        await tester.tap(find.text(sEs.medStatusCompleted));
        await tester.pump();

        await tester.ensureVisible(find.text(sEs.medStatusStopped));
        await tester.tap(find.text(sEs.medStatusStopped));
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Ibuprofeno');
        await tester.pump();

        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.status, equals('stopped'));
      },
    );
  });

  group('Callback output validations for MedicationStatementItem records', () {
    testWidgets('Applies trim formatting to medicationName values cleanly', (
      tester,
    ) async {
      MedicationStatementItem? captured;
      await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

      await tester.enterText(
        find.byType(TextField).first,
        '  Metformina 850mg  ',
      );
      await tester.pump();
      await tester.tap(_confirmButton());
      await tester.pump();

      expect(captured?.medicationName, equals('Metformina 850mg'));
    });

    testWidgets(
      'Evaluates empty dosage input fields directly into null properties',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Paracetamol');
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.dosage, isNull);
      },
    );

    testWidgets(
      'Evaluates dosage fields filled with only blank whitespace parameters into null properties',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Paracetamol');
        await tester.pump();
        await tester.ensureVisible(find.text(sEs.dosageHint));
        await tester.enterText(find.byType(TextField).at(1), '   ');
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.dosage, isNull);
      },
    );

    testWidgets(
      'Forwards dosage value fields when input characters are supplied correctly',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Atorvastatina');
        await tester.pump();
        await tester.ensureVisible(find.text(sEs.dosageHint));
        await tester.enterText(
          find.byType(TextField).at(1),
          '1 tableta cada 24 horas',
        );
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.dosage, equals('1 tableta cada 24 horas'));
      },
    );

    testWidgets(
      'Evaluates empty notes input fields directly into null properties',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Losartan');
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.notes, isNull);
      },
    );

    testWidgets(
      'Evaluates notes fields filled with only blank whitespace parameters into null properties',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Losartan');
        await tester.pump();
        await tester.ensureVisible(find.text(sEs.notesHint));
        await tester.enterText(find.byType(TextField).at(2), '   ');
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.notes, isNull);
      },
    );

    testWidgets(
      'Forwards optional notes text metrics inside final callback values',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(find.byType(TextField).first, 'Losartan');
        await tester.pump();
        await tester.ensureVisible(find.text(sEs.notesHint));
        await tester.enterText(
          find.byType(TextField).at(2),
          'Tomar con comida',
        );
        await tester.pump();
        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.notes, equals('Tomar con comida'));
      },
    );

    testWidgets(
      'Forwards comprehensive fully populated form values correctly',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(_buildDirect(onAdd: (item) => captured = item));

        await tester.enterText(
          find.byType(TextField).first,
          'Metformina 850mg',
        );
        await tester.pump();

        await tester.ensureVisible(find.text(sEs.medStatusCompleted));
        await tester.tap(find.text(sEs.medStatusCompleted));
        await tester.pump();

        await tester.ensureVisible(find.text(sEs.dosageHint));
        await tester.enterText(
          find.byType(TextField).at(1),
          '1 tableta cada 12 horas',
        );
        await tester.pump();

        await tester.ensureVisible(find.text(sEs.notesHint));
        await tester.enterText(find.byType(TextField).at(2), 'Con el desayuno');
        await tester.pump();

        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.medicationName, equals('Metformina 850mg'));
        expect(captured?.status, equals('completed'));
        expect(captured?.dosage, equals('1 tableta cada 12 horas'));
        expect(captured?.notes, equals('Con el desayuno'));
      },
    );
  });

  group('Sheet Dismissal Pipeline — Save confirmation workflows', () {
    testWidgets(
      'Invokes onAdd callback and dismisses sheet layout elements synchronously from views',
      (tester) async {
        bool called = false;

        await tester.pumpWidget(
          _buildViaBottomSheet(onAdd: (_) => called = true),
        );
        await _openSheet(tester);

        await tester.enterText(find.byType(TextField).first, 'Aspirina');
        await tester.pump();

        await tester.tap(_confirmButton());
        await tester.pumpAndSettle();

        expect(called, isTrue);
        expect(find.byType(AddMedicationSheet), findsNothing);
      },
    );
  });

  group('Scaffold Close Triggers — Close chevron tracking tests', () {
    testWidgets(
      'Dismisses interactive sheet layout directly without firing callbacks',
      (tester) async {
        bool called = false;

        await tester.pumpWidget(
          _buildViaBottomSheet(onAdd: (_) => called = true),
        );
        await _openSheet(tester);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(called, isFalse);
        expect(find.byType(AddMedicationSheet), findsNothing);
      },
    );
  });

  group('Localization Matrix — English language string validations', () {
    testWidgets(
      'Displays completely matching textual parameters on English locales',
      (tester) async {
        await tester.pumpWidget(_buildDirect(onAdd: (_) {}, locale: 'en'));

        expect(find.text(sEn.addMedicationTitle), findsOneWidget);
        expect(find.text(sEn.addMedicationSubtitle), findsOneWidget);
        expect(find.text(sEn.medicationLabel), findsOneWidget);

        await tester.ensureVisible(find.text(sEn.statusLabel));
        expect(find.text(sEn.statusLabel), findsOneWidget);
        expect(find.text(sEn.medStatusActive), findsOneWidget);
        expect(find.text(sEn.medStatusCompleted), findsOneWidget);
        expect(find.text(sEn.medStatusStopped), findsOneWidget);
        expect(find.text(sEn.medStatusUnknown), findsOneWidget);
      },
    );

    testWidgets(
      'Saves valid structural fields matching target locale specifications',
      (tester) async {
        MedicationStatementItem? captured;
        await tester.pumpWidget(
          _buildDirect(onAdd: (item) => captured = item, locale: 'en'),
        );

        await tester.enterText(find.byType(TextField).first, 'Metformin 500mg');
        await tester.pump();

        await tester.ensureVisible(find.text(sEn.medStatusStopped));
        await tester.tap(find.text(sEn.medStatusStopped));
        await tester.pump();

        await tester.tap(_confirmButton());
        await tester.pump();

        expect(captured?.medicationName, equals('Metformin 500mg'));
        expect(captured?.status, equals('stopped'));
        expect(captured?.dosage, isNull);
        expect(captured?.notes, isNull);
      },
    );
  });
}
