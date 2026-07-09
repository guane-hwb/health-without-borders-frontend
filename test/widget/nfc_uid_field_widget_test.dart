// test/widget/nfc_uid_field_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/widgets/nfc_uid_field.dart';

Widget _wrap(Widget child, {String locale = 'es'}) {
  return MaterialApp(
    home: AppLocale(
      locale: locale,
      setLocale: (_) {},
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

Icon _prefixIcon(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField));
  return field.decoration!.prefixIcon! as Icon;
}

void main() {
  group('NfcUidField - empty value (hasValue == false)', () {
    testWidgets('shows default prefix icon, no suffix, no linked-device row', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Scan or type UID');
      expect(textField.decoration?.suffixIcon, isNull);

      final prefix = _prefixIcon(tester);
      expect(prefix.icon, Icons.contactless);
      expect(prefix.color, AppColors.textSecondary);

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.textContaining('vinculado'), findsNothing);
      expect(find.textContaining('Linked device'), findsNothing);
    });

    testWidgets('whitespace-only text still counts as empty (trim check)', (
      tester,
    ) async {
      final controller = TextEditingController(text: '   ');
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
      final prefix = _prefixIcon(tester);
      expect(prefix.color, AppColors.textSecondary);
    });

    testWidgets('a custom prefixIcon overrides the default', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
            prefixIcon: Icons.badge,
          ),
        ),
      );

      final prefix = _prefixIcon(tester);
      expect(prefix.icon, Icons.badge);
    });
  });

  group('NfcUidField - filled value (hasValue == true)', () {
    testWidgets('shows success-colored prefix icon, suffix check, '
        'and Spanish linked-device label', (tester) async {
      final controller = TextEditingController(text: 'ABC123');
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
          locale: 'es',
        ),
      );

      final prefix = _prefixIcon(tester);
      expect(prefix.color, AppColors.success);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.suffixIcon, isA<Icon>());

      expect(find.text('Dispositivo vinculado: ABC123'), findsOneWidget);
    });

    testWidgets('shows English linked-device label when locale is en', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'ABC123');
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
          locale: 'en',
        ),
      );

      expect(find.text('Linked device: ABC123'), findsOneWidget);
      expect(find.textContaining('vinculado'), findsNothing);
    });

    testWidgets('trims surrounding whitespace in the displayed UID', (
      tester,
    ) async {
      final controller = TextEditingController(text: '  XYZ789  ');
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () {},
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
        ),
      );

      expect(find.text('Dispositivo vinculado: XYZ789'), findsOneWidget);
    });
  });

  group('NfcUidField - scanning state', () {
    testWidgets('scanning == false shows the NFC icon and enables the button', (
      tester,
    ) async {
      final controller = TextEditingController();
      var scanTapped = false;
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: false,
            onScan: () => scanTapped = true,
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
        ),
      );

      expect(find.byIcon(Icons.nfc), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(scanTapped, isTrue);
    });

    testWidgets('scanning == true shows a spinner and disables the button', (
      tester,
    ) async {
      final controller = TextEditingController();
      var scanTapped = false;
      await tester.pumpWidget(
        _wrap(
          NfcUidField(
            controller: controller,
            scanning: true,
            onScan: () => scanTapped = true,
            onChanged: () {},
            hintText: 'Scan or type UID',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.nfc), findsNothing);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(scanTapped, isFalse);
    });
  });

  group('NfcUidField - text input', () {
    testWidgets(
      'editing the field invokes onChanged (value itself is ignored)',
      (tester) async {
        final controller = TextEditingController();
        var changedCount = 0;
        await tester.pumpWidget(
          _wrap(
            NfcUidField(
              controller: controller,
              scanning: false,
              onScan: () {},
              onChanged: () => changedCount++,
              hintText: 'Scan or type UID',
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'NEWUID1');
        expect(changedCount, 1);
        expect(controller.text, 'NEWUID1');
      },
    );
  });
}
