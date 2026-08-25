// test/unit/locale_detection_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  testWidgets(
    'la detección de idioma no depende del texto de ninguna traducción',
    (tester) async {
      late String detectado;

      await tester.pumpWidget(
        AppLocale(
          locale: 'es',
          setLocale: (_) {},
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                detectado = AppLocale.of(context).locale;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(detectado, 'es');

      final s = AppStrings.of(tester.element(find.byType(SizedBox)));
      expect(
        s.save,
        isNotEmpty,
        reason: 'el valor concreto de s.save no debe influir en la detección',
      );
    },
  );
}
