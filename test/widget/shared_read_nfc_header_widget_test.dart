// test/widget/shared_read_nfc_header_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/shared_read_nfc_header.dart';

Widget _buildTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Column(children: [child])),
  );
}

void main() {
  group('SharedReadNfcHeader Widget Tests — 100% Cobertura', () {
    testWidgets('Should render title and initial logo when onBack is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          const SharedReadNfcHeader(title: 'Título de Prueba', onBack: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Título de Prueba'), findsOneWidget);

      /// When onBack callback is null, the back arrow button icon should not be rendered.
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets(
      'Should display the back button and trigger callback upon a tap gesture',
      (tester) async {
        bool backCalled = false;

        await tester.pumpWidget(
          _buildTestableWidget(
            SharedReadNfcHeader(
              title: 'Flujo NFC',
              onBack: () => backCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(backCalled, isTrue);
      },
    );

    testWidgets(
      'Should render the step progression indicator conditionally if stepText is provided',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            const SharedReadNfcHeader(
              title: 'Validación',
              onBack: null,
              stepText: 'Paso 1 de 2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Paso 1 de 2'), findsOneWidget);
      },
    );
  });
}
