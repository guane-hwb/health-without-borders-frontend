// test/widget/edit_address_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_address_sheet.dart';

Widget _wrap(Widget child, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required Address address,
  required ValueChanged<Address> onConfirm,
  String locale = 'es',
}) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) =>
                EditAddressSheet(address: address, onConfirm: onConfirm),
          ),
          child: const Text('Open'),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  late Address baseAddress;

  setUp(() {
    baseAddress = Address(
      street: 'Calle 12 #14-55',
      city: 'Riohacha',
      cityCode: '44001',
      state: 'La Guajira',
      zipCode: '440001',
      country: 'COL',
      countryName: 'Colombia',
      zone: '01',
    );

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

  group('EditAddressSheet — Layout and Translation Verification', () {
    testWidgets(
      'renders all structured text titles matching Spanish i18n configurations',
      (tester) async {
        await _pumpSheet(
          tester,
          address: baseAddress,
          onConfirm: (_) {},
          locale: 'es',
        );

        expect(find.text('Editar residencia'), findsOneWidget);
        expect(find.text('Dirección y zona del paciente'), findsOneWidget);
        expect(find.text('Dirección'), findsOneWidget);
        expect(find.text('Municipio *'), findsOneWidget);
        expect(find.text('Departamento *'), findsOneWidget);
        expect(find.text('Zona'), findsOneWidget);
        expect(find.text('Urbana'), findsOneWidget);
        expect(find.text('Rural'), findsOneWidget);
      },
    );

    testWidgets(
      'renders all structured text titles matching English i18n configurations',
      (tester) async {
        await _pumpSheet(
          tester,
          address: baseAddress,
          onConfirm: (_) {},
          locale: 'en',
        );

        expect(find.text('Edit residence'), findsOneWidget);
        expect(find.text('Patient address and zone'), findsOneWidget);
        expect(find.text('Address'), findsOneWidget);
        expect(find.text('Municipality *'), findsOneWidget);
        expect(find.text('Department *'), findsOneWidget);
        expect(find.text('Zone'), findsOneWidget);
        expect(find.text('Urban'), findsOneWidget);
        expect(find.text('Rural'), findsOneWidget);
      },
    );

    testWidgets(
      'populates entry inputs using parameters supplied within core models',
      (tester) async {
        await _pumpSheet(tester, address: baseAddress, onConfirm: (_) {});

        expect(find.text('Calle 12 #14-55'), findsOneWidget);
        expect(find.text('Riohacha'), findsOneWidget);
        expect(find.text('La Guajira'), findsOneWidget);
      },
    );

    testWidgets(
      'displays matching structural placeholder strings on blank properties fields',
      (tester) async {
        final unpopulatedAddress = Address(
          city: '',
          state: '',
          street: null,
          zone: '01',
        );
        await _pumpSheet(
          tester,
          address: unpopulatedAddress,
          onConfirm: (_) {},
        );

        expect(find.text('ej: Cra. 18 #27-43'), findsOneWidget);
        expect(find.text('ej: Riohacha'), findsOneWidget);
        expect(find.text('ej: La Guajira'), findsOneWidget);
      },
    );
  });

  group('EditAddressSheet — Interactive Entry Forms Modification Flow', () {
    testWidgets('allows editing input fields text contexts seamlessly', (
      tester,
    ) async {
      await _pumpSheet(tester, address: baseAddress, onConfirm: (_) {});

      final streetFieldFinder = find.byType(TextField).at(0);
      final cityFieldFinder = find.byType(TextField).at(1);
      final stateFieldFinder = find.byType(TextField).at(2);

      await tester.enterText(streetFieldFinder, 'Calle Nueva 44');
      await tester.enterText(cityFieldFinder, 'Maicao');
      await tester.enterText(stateFieldFinder, 'Guajira Alta');
      await tester.pump();

      expect(find.text('Calle Nueva 44'), findsOneWidget);
      expect(find.text('Maicao'), findsOneWidget);
      expect(find.text('Guajira Alta'), findsOneWidget);
    });
  });

  group('EditAddressSheet — Confirmation and Navigation Mapping Lifecycle', () {
    testWidgets('forwards modified data downstream and closes sheet cleanly', (
      tester,
    ) async {
      Address? capturedAddress;

      await _pumpSheet(
        tester,
        address: baseAddress,
        onConfirm: (address) => capturedAddress = address,
      );

      final streetFieldFinder = find.byType(TextField).at(0);
      final cityFieldFinder = find.byType(TextField).at(1);
      final stateFieldFinder = find.byType(TextField).at(2);

      await tester.enterText(streetFieldFinder, '  Avenida Falsa 123  ');
      await tester.enterText(cityFieldFinder, ' Dibulla ');
      await tester.enterText(stateFieldFinder, ' Cesar ');
      await tester.pump();

      final confirmBtn = find.text('Confirmar cambios');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.byType(EditAddressSheet), findsNothing);
      expect(capturedAddress, isNotNull);
      expect(capturedAddress!.street, equals('Avenida Falsa 123'));
      expect(capturedAddress!.city, equals('Dibulla'));
      expect(capturedAddress!.state, equals('Cesar'));
    });

    testWidgets(
      'evaluates blank street values into null fields inside confirmation records',
      (tester) async {
        Address? capturedAddress;

        await _pumpSheet(
          tester,
          address: baseAddress,
          onConfirm: (address) => capturedAddress = address,
        );

        final streetFieldFinder = find.byType(TextField).at(0);
        await tester.enterText(streetFieldFinder, '   ');
        await tester.pump();

        await tester.tap(find.text('Confirmar cambios'));
        await tester.pumpAndSettle();

        expect(capturedAddress, isNotNull);
        expect(capturedAddress!.street, isNull);
      },
    );

    testWidgets(
      'tapping close icon dismisses modal window instantly without committing actions when unchanged',
      (tester) async {
        var confirmCalled = false;

        await _pumpSheet(
          tester,
          address: baseAddress,
          onConfirm: (_) => confirmCalled = true,
        );

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(EditAddressSheet), findsNothing);
        expect(confirmCalled, isFalse);
      },
    );
  });
}
