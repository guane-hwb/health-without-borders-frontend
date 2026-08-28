// test/widget/locale_switcher_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/locale_switcher.dart';

void main() {
  testWidgets('el conmutador cambia el idioma al tocar la opción', (
    tester,
  ) async {
    var locale = 'es';
    await tester.pumpWidget(
      AppLocale(
        locale: locale,
        setLocale: (l) => locale = l,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: LocaleSwitcher())),
        ),
      ),
    );

    expect(find.text('ES'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    await tester.tap(find.text('EN'));
    expect(locale, 'en');
  });
}
