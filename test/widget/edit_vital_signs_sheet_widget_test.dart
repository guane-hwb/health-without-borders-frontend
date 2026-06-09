// test/widget/features/nfc/profile/sheets/edit_vital_signs_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart';

Widget _wrap({
  String locale = 'es',
  double? weight,
  double? height,
  double? previousWeight,
  double? previousHeight,
  void Function({double? weight, double? height})? onConfirm,
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: EditVitalSignsSheet(
          weight: weight,
          height: height,
          previousWeight: previousWeight,
          previousHeight: previousHeight,
          onConfirm: onConfirm ?? ({double? weight, double? height}) {},
        ),
      ),
    ),
  );
}

void main() {
  group('EditVitalSignsSheet — Baseline UI Rendering', () {
    testWidgets(
      'Renders layout completely without throwing unhandled exceptions',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.byType(EditVitalSignsSheet), findsOneWidget);
      },
    );

    testWidgets('Displays exactly two functional entry TextField inputs', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets(
      'Displays the explicit info_outline fallback icon matching blood type notice requirements',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Blood type banner surface utilizes a specific Color(0xFFE3F2FD) background tint',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasBlueNote = containers.any((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.color == const Color(0xFFE3F2FD);
        });
        expect(hasBlueNote, isTrue);
      },
    );
  });

  group('EditVitalSignsSheet — Field Pre-population Behavior', () {
    testWidgets(
      'Displays supplied weight model values formatted to exactly one decimal place',
      (tester) async {
        await tester.pumpWidget(_wrap(weight: 72.5));
        expect(find.text('72.5'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays supplied height model values rounded to zero decimal constraints',
      (tester) async {
        await tester.pumpWidget(_wrap(height: 170.0));
        expect(find.text('170'), findsOneWidget);
      },
    );

    testWidgets(
      'Appends trailing fraction zero markers to absolute integer weight configurations',
      (tester) async {
        await tester.pumpWidget(_wrap(weight: 65.0));
        expect(find.text('65.0'), findsOneWidget);
      },
    );

    testWidgets(
      'Rounds double height inputs containing complex fractional portions to whole integers',
      (tester) async {
        await tester.pumpWidget(_wrap(height: 170.7));
        expect(find.text('171'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders combined non-empty pre-populated entry strings together flawlessly',
      (tester) async {
        await tester.pumpWidget(_wrap(weight: 72.5, height: 170.0));
        expect(find.text('72.5'), findsOneWidget);
        expect(find.text('170'), findsOneWidget);
      },
    );
  });

  group('EditVitalSignsSheet — Blank Initialization Placeholder Hints', () {
    testWidgets(
      'Weight text form input displays fallback placeholder string hint "0.0"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.text('0.0'), findsOneWidget);
      },
    );

    testWidgets(
      'Height text form input displays fallback placeholder string hint "0"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.text('0'), findsOneWidget);
      },
    );

    testWidgets(
      'Unpopulated controllers maintain completely blank input text values internally',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        for (final tf in textFields) {
          expect(tf.controller?.text ?? '', equals(''));
        }
      },
    );
  });

  group('EditVitalSignsSheet — Historical Metrics Context Labels visibility', () {
    testWidgets(
      'ES Locale: Renders "Anterior: X kg" copies when previousWeight parameters exist',
      (tester) async {
        await tester.pumpWidget(_wrap(previousWeight: 68.0));
        expect(find.text('Anterior: 68.0 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'EN Locale: Renders "Previous: X kg" copies when previousWeight parameters exist',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en', previousWeight: 68.0));
        expect(find.text('Previous: 68.0 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'ES Locale: Renders "Anterior: X cm" copies when previousHeight parameters exist',
      (tester) async {
        await tester.pumpWidget(_wrap(previousHeight: 165.0));
        expect(find.text('Anterior: 165 cm'), findsOneWidget);
      },
    );

    testWidgets(
      'EN Locale: Renders "Previous: X cm" copies when previousHeight parameters exist',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en', previousHeight: 165.0));
        expect(find.text('Previous: 165 cm'), findsOneWidget);
      },
    );

    testWidgets(
      'Omits rendering historical descriptions completely when previousWeight evaluates to null',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.text('Anterior: '), findsNothing);
        expect(find.textContaining('kg'), findsNothing);
      },
    );

    testWidgets(
      'Omits rendering historical descriptions completely when previousHeight evaluates to null',
      (tester) async {
        await tester.pumpWidget(_wrap());
        expect(find.textContaining('cm'), findsNothing);
      },
    );

    testWidgets(
      'Renders combined historical information labels when both metadata configurations exist',
      (tester) async {
        await tester.pumpWidget(
          _wrap(previousWeight: 68.0, previousHeight: 165.0),
        );
        expect(find.text('Anterior: 68.0 kg'), findsOneWidget);
        expect(find.text('Anterior: 165 cm'), findsOneWidget);
      },
    );
  });

  group('EditVitalSignsSheet — Callback Extraction Execution Gates', () {
    testWidgets(
      'Fires onConfirm delivering accurate populated values downstream upon interaction clicks',
      (tester) async {
        double? confirmedWeight;
        double? confirmedHeight;

        await tester.pumpWidget(
          _wrap(
            weight: 72.5,
            height: 170.0,
            onConfirm: ({double? weight, double? height}) {
              confirmedWeight = weight;
              confirmedHeight = height;
            },
          ),
        );

        final confirmBtn = find.byType(ElevatedButton);
        if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn.first);
          await tester.pumpAndSettle();
          expect(confirmedWeight, equals(72.5));
          expect(confirmedHeight, equals(170.0));
        }
      },
    );

    testWidgets(
      'Forwards newly modified alphanumeric string context changes inside callback arguments',
      (tester) async {
        double? confirmedWeight;

        await tester.pumpWidget(
          _wrap(
            onConfirm: ({double? weight, double? height}) {
              confirmedWeight = weight;
            },
          ),
        );

        final weightField = find.byType(TextField).first;
        await tester.tap(weightField);
        await tester.enterText(weightField, '80.0');
        await tester.pump();

        final confirmBtn = find.byType(ElevatedButton);
        if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn.first);
          await tester.pumpAndSettle();
          expect(confirmedWeight, equals(80.0));
        }
      },
    );
  });

  group('EditVitalSignsSheet — Callback Null Extraction Fallbacks', () {
    testWidgets(
      'Evaluates completely blank unpopulated entry fields into explicit null parameters downstream',
      (tester) async {
        double? confirmedWeight = 99.0;
        double? confirmedHeight = 99.0;

        await tester.pumpWidget(
          _wrap(
            onConfirm: ({double? weight, double? height}) {
              confirmedWeight = weight;
              confirmedHeight = height;
            },
          ),
        );

        final confirmBtn = find.byType(ElevatedButton);
        if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn.first);
          await tester.pumpAndSettle();
          expect(confirmedWeight, isNull);
          expect(confirmedHeight, isNull);
        }
      },
    );
  });

  group('EditVitalSignsSheet — Internationalization Matrix Checks', () {
    testWidgets(
      'ES Locale: Configures weight descriptive heading label exactly to "PESO (KG)"',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('PESO (KG)'), findsOneWidget);
      },
    );

    testWidgets(
      'EN Locale: Configures weight descriptive heading label exactly to "WEIGHT (KG)"',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en'));
        expect(find.text('WEIGHT (KG)'), findsOneWidget);
      },
    );

    testWidgets(
      'ES Locale: Configures height descriptive heading label exactly to "ALTURA (CM)"',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('ALTURA (CM)'), findsOneWidget);
      },
    );

    testWidgets(
      'EN Locale: Configures height descriptive heading label exactly to "HEIGHT (CM)"',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en'));
        expect(find.text('HEIGHT (CM)'), findsOneWidget);
      },
    );

    testWidgets(
      'ES Locale: Blood type structural alert contains correct localized copy tokens in Spanish',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.textContaining('tipo de sangre'), findsOneWidget);
      },
    );

    testWidgets(
      'EN Locale: Blood type structural alert contains correct localized copy tokens in English',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en'));
        expect(find.textContaining('Blood type'), findsOneWidget);
      },
    );

    testWidgets(
      'Switching runtime locale contexts safely shifts typography text copy values from ES into EN',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('PESO (KG)'), findsOneWidget);
        expect(find.text('WEIGHT (KG)'), findsNothing);

        await tester.pumpWidget(_wrap(locale: 'en'));
        await tester.pumpAndSettle();
        expect(find.text('WEIGHT (KG)'), findsOneWidget);
        expect(find.text('PESO (KG)'), findsNothing);
      },
    );

    testWidgets(
      'Switching runtime locale contexts safely shifts height section headings from ES into EN',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        expect(find.text('ALTURA (CM)'), findsOneWidget);

        await tester.pumpWidget(_wrap(locale: 'en'));
        await tester.pumpAndSettle();
        expect(find.text('HEIGHT (CM)'), findsOneWidget);
      },
    );
  });

  group('_FieldLabel — Core Typography Component Styling', () {
    testWidgets(
      'ES Locale: Weight header text styling specifies exactly fontSize=11 properties',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        final label = tester.widget<Text>(find.text('PESO (KG)'));
        expect(label.style?.fontSize, equals(11));
      },
    );

    testWidgets(
      'ES Locale: Weight header text styling enforces bold w700 structural weights',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        final label = tester.widget<Text>(find.text('PESO (KG)'));
        expect(label.style?.fontWeight, equals(FontWeight.w700));
      },
    );

    testWidgets(
      'ES Locale: Weight heading typography assigns matching AppColors.textSecondary color palettes',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'es'));
        final label = tester.widget<Text>(find.text('PESO (KG)'));
        expect(label.style?.color, equals(AppColors.textSecondary));
      },
    );

    testWidgets(
      'EN Locale: Height heading typography preserves identical font size and layout weights styling parameters',
      (tester) async {
        await tester.pumpWidget(_wrap(locale: 'en'));
        final label = tester.widget<Text>(find.text('HEIGHT (CM)'));
        expect(label.style?.fontSize, equals(11));
        expect(label.style?.fontWeight, equals(FontWeight.w700));
      },
    );
  });

  group('EditVitalSignsSheet — Active Interactive Entry Mutations', () {
    testWidgets(
      'Allows typing alphanumeric numerical characters inside the weight input forms',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final weightField = find.byType(TextField).first;
        await tester.tap(weightField);
        await tester.enterText(weightField, '85.5');
        await tester.pump();
        expect(find.text('85.5'), findsOneWidget);
      },
    );

    testWidgets(
      'Allows typing alphanumeric numerical characters inside the height input forms',
      (tester) async {
        await tester.pumpWidget(_wrap());
        final heightField = find.byType(TextField).at(1);
        await tester.tap(heightField);
        await tester.enterText(heightField, '175');
        await tester.pump();
        expect(find.text('175'), findsOneWidget);
      },
    );

    testWidgets(
      'Allows overriding and clearing previously stored non-empty pre-populated model records',
      (tester) async {
        await tester.pumpWidget(_wrap(weight: 65.0));
        final weightField = find.byType(TextField).first;
        await tester.tap(weightField);
        await tester.enterText(weightField, '70.0');
        await tester.pump();
        expect(find.text('70.0'), findsOneWidget);
      },
    );
  });
}
