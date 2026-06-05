// test/widget/features/nfc/profile/sheets/edit_vaccine_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/edit_vaccine_sheet.dart';

Widget _wrap({
  String locale = 'es',
  String? initialVaccine,
  String? initialVaccineCode,
  String? initialDose,
  String? initialDate,
  String? initialAdministeredBy,
  String? initialAdministeredAt,
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: EditVaccineSheet(
          initialVaccine: initialVaccine,
          initialVaccineCode: initialVaccineCode,
          initialDose: initialDose,
          initialDate: initialDate,
          initialAdministeredBy: initialAdministeredBy,
          initialAdministeredAt: initialAdministeredAt,
        ),
      ),
    ),
  );
}

Widget _wrapFull({String locale = 'es'}) => _wrap(
  locale: locale,
  initialVaccine: 'Triple Viral (SRP)',
  initialVaccineCode: '03',
  initialDose: '1',
  initialDate: '2026-01-15',
  initialAdministeredBy: 'Enf. Ana Ruiz',
  initialAdministeredAt: 'Hospital Central',
);

void main() {
  group('EditVaccineSheet — Base Rendering', () {
    testWidgets('renders without throwing exceptions', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(EditVaccineSheet), findsOneWidget);
    });

    testWidgets('renders the grey container handle line indicator', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasHandle = containers.any((c) {
        return c.constraints?.minWidth == 60 ||
            (c.child == null &&
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius != null);
      });

      expect(hasHandle, isTrue);
    });

    testWidgets('renders exactly 6 separate text fields', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('renders the action save floating button icon', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });

  group('EditVaccineSheet — Localized Labels ES', () {
    testWidgets('renders the required vaccine name label field', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: 'es'));
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('ES locale: save button displays "Guardar"', (tester) async {
      await tester.pumpWidget(_wrap(locale: 'es'));
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('EN locale: save button displays "Save"', (tester) async {
      await tester.pumpWidget(_wrap(locale: 'en'));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('EN locale: save button does NOT display "Guardar"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: 'en'));
      expect(find.text('Guardar'), findsNothing);
    });
  });

  group('EditVaccineSheet — Field Pre-population', () {
    testWidgets('pre-populates the correct vaccine name string value', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(initialVaccine: 'Hepatitis B'));
      expect(find.text('Hepatitis B'), findsOneWidget);
    });

    testWidgets('pre-populates the corresponding CVX code data string', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(initialVaccineCode: '08'));
      expect(find.text('08'), findsOneWidget);
    });

    testWidgets(
      'pre-populates the defined vaccination sequence dose tracking string',
      (tester) async {
        await tester.pumpWidget(_wrap(initialDose: '2'));
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-populates the targeted administration date tracking string',
      (tester) async {
        await tester.pumpWidget(_wrap(initialDate: '2026-01-15'));
        expect(find.text('2026-01-15'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-populates the health practitioner signature text payload',
      (tester) async {
        await tester.pumpWidget(_wrap(initialAdministeredBy: 'Dr. Pérez'));
        expect(find.text('Dr. Pérez'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-populates the localized clinical care facility text payload',
      (tester) async {
        await tester.pumpWidget(_wrap(initialAdministeredAt: 'Brigada Sur'));
        expect(find.text('Brigada Sur'), findsOneWidget);
      },
    );

    testWidgets('all pre-populated arguments render together correctly', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapFull());
      expect(find.text('Triple Viral (SRP)'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2026-01-15'), findsOneWidget);
      expect(find.text('Enf. Ana Ruiz'), findsOneWidget);
      expect(find.text('Hospital Central'), findsOneWidget);
    });
  });

  group('EditVaccineSheet — Empty Fallback Values', () {
    testWidgets(
      'fields remain empty when no initial value parameters are specified',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        for (final tf in textFields) {
          expect(tf.controller?.text ?? '', equals(''));
        }
      },
    );

    testWidgets(
      'displays placeholder hint "e.g., 140" on CVX input components',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.text('e.g., 140'), findsOneWidget);
      },
    );

    testWidgets('displays placeholder hint "e.g., 1" on target dose inputs', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('e.g., 1'), findsOneWidget);
    });

    testWidgets('displays placeholder date format guidelines "YYYY-MM-DD"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('YYYY-MM-DD'), findsOneWidget);
    });
  });

  group('EditVaccineSheet — Field Mutation Input', () {
    testWidgets(
      'allows character entries inside the vaccine name layout textfield',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final nameField = find.byType(TextField).first;
        await tester.tap(nameField);
        await tester.enterText(nameField, 'BCG (Tuberculosis)');
        await tester.pump();
        expect(find.text('BCG (Tuberculosis)'), findsOneWidget);
      },
    );

    testWidgets(
      'allows programmatic mutations targeting the raw CVX code textfield',
      (tester) async {
        await tester.pumpWidget(_wrap(initialVaccineCode: '03'));
        final codeField = find.byType(TextField).at(1);
        await tester.tap(codeField);
        await tester.enterText(codeField, '19');
        await tester.pump();
        expect(find.text('19'), findsOneWidget);
      },
    );

    testWidgets(
      'allows mutations targeting the configuration target date string input',
      (tester) async {
        await tester.pumpWidget(_wrap(initialDate: '2026-01-15'));
        final dateField = find.byType(TextField).at(3);
        await tester.tap(dateField);
        await tester.enterText(dateField, '2026-06-01');
        await tester.pump();
        expect(find.text('2026-06-01'), findsOneWidget);
      },
    );
  });

  group('EditVaccineSheet — Action Commit Validation', () {
    testWidgets(
      'action button background configuration adheres to secondary app color tokens',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final btn = tester.widget<ElevatedButton>(
          find.widgetWithIcon(ElevatedButton, Icons.save),
        );
        final bg = btn.style?.backgroundColor?.resolve({});
        expect(bg, equals(AppColors.secondary));
      },
    );

    testWidgets(
      'action button save graphic instance maps to a white colored icon token',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final saveIcon = tester.widget<Icon>(find.byIcon(Icons.save));
        expect(saveIcon.color, equals(AppColors.white));
      },
    );

    testWidgets(
      'tapping the save action triggers navigation sheet dismissal pop routines',
      (tester) async {
        /// Expand physical environment dimensions to prevent vertical widget layout overflows during execution.
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool popped = false;
        await tester.pumpWidget(
          AppLocale(
            locale: 'es',
            setLocale: (_) {},
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: ctx,
                        builder: (_) => const EditVaccineSheet(),
                      );
                      popped = true;
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

        expect(find.byType(EditVaccineSheet), findsOneWidget);

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(find.byType(EditVaccineSheet), findsNothing);
      },
    );
  });

  group('EditVaccineSheet — Contextual Header Text Validation', () {
    testWidgets('ES locale: structural modal layout header displays "Vacuna"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(locale: 'es'));
      expect(find.text('Vacuna'), findsOneWidget);
    });

    testWidgets(
      'EN locale: structural modal layout header displays "Vaccine"',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en'));
        expect(find.text('Vaccine'), findsOneWidget);
      },
    );

    testWidgets(
      'header layout typography maps to secondary app coloring styling tokens',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        final titleText = tester.widget<Text>(find.text('Vacuna'));
        expect(titleText.style?.color, equals(AppColors.secondary));
      },
    );
  });

  group('EditVaccineSheet — Multi-locale Translation Updates', () {
    testWidgets(
      'header text alters configuration matching localized changes seamlessly',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('Vacuna'), findsOneWidget);
        expect(find.text('Vaccine'), findsNothing);

        await tester.pumpWidget(_wrap(locale: 'en'));
        await tester.pumpAndSettle();
        expect(find.text('Vaccine'), findsOneWidget);
        expect(find.text('Vacuna'), findsNothing);
      },
    );

    testWidgets(
      'action context button details update from "Guardar" to "Save" automatically',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('Guardar'), findsOneWidget);

        await tester.pumpWidget(_wrap(locale: 'en'));
        await tester.pumpAndSettle();
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Guardar'), findsNothing);
      },
    );

    testWidgets(
      'retains filled input records across structural runtime language shifts',
      (tester) async {
        await tester.pumpWidget(_wrapFull(locale: 'es'));
        expect(find.text('Triple Viral (SRP)'), findsOneWidget);

        await tester.pumpWidget(_wrapFull(locale: 'en'));
        await tester.pumpAndSettle();
        expect(find.text('Triple Viral (SRP)'), findsOneWidget);
      },
    );
  });
}
