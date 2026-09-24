// test/widget/reassign_device_dialog_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

Widget _wrapWithButton({
  required bool isEs,
  required bool hasG1,
  required bool hasG2,
  required ValueChanged<ReassignSelection?> onResult,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final res = await showReassignDeviceDialog(
              context,
              isEs: isEs,
              hasG1: hasG1,
              hasG2: hasG2,
            );
            onResult(res);
          },
          child: const Text('Show Dialog'),
        ),
      ),
    ),
  );
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

  group('ReassignDeviceDialog — Layout & Localization Rendering', () {
    testWidgets(
      'renders dialog elements correctly in Spanish (es) with G1 & G2',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithButton(
            isEs: true,
            hasG1: true,
            hasG2: true,
            onResult: (_) {},
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Reasignar dispositivo'), findsOneWidget);
        expect(
          find.text('¿Qué dispositivo deseas reemplazar?'),
          findsOneWidget,
        );
        expect(find.text('Dispositivo del paciente'), findsOneWidget);
        expect(find.text('Dispositivo guardián 1'), findsOneWidget);
        expect(find.text('Dispositivo guardián 2'), findsOneWidget);
        expect(find.text('Motivo del reemplazo'), findsOneWidget);
        expect(find.text('Pérdida'), findsOneWidget);
        expect(find.text('Dañada'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Continuar'), findsOneWidget);
      },
    );

    testWidgets(
      'renders dialog elements correctly in English (en) with single G1',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithButton(
            isEs: false,
            hasG1: true,
            hasG2: false,
            onResult: (_) {},
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Reassign device'), findsOneWidget);
        expect(
          find.text('Which device do you want to replace?'),
          findsOneWidget,
        );
        expect(find.text('Patient device'), findsOneWidget);
        expect(find.text('Guardian'), findsOneWidget);
        expect(find.text('Guardian 2'), findsNothing);
        expect(find.text('Reason for replacement'), findsOneWidget);
        expect(find.text('Lost'), findsOneWidget);
        expect(find.text('Damaged'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'renders dialog elements correctly in English (en) with dual guardians (hasG1 & hasG2)',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithButton(
            isEs: false,
            hasG1: true,
            hasG2: true,
            onResult: (_) {},
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Guardian 1'), findsOneWidget);
        expect(find.text('Guardian 2'), findsOneWidget);
      },
    );
  });

  group('ReassignDeviceDialog — Selection & State Mutations', () {
    testWidgets('allows selecting multiple targets and changing reason chips', (
      tester,
    ) async {
      ReassignSelection? result;

      await tester.pumpWidget(
        _wrapWithButton(
          isEs: true,
          hasG1: true,
          hasG2: true,
          onResult: (res) => result = res,
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Select Guardian 2 card
      await tester.tap(find.text('Dispositivo guardián 2'));
      await tester.pumpAndSettle();

      // Change reason to Damaged ('Dañada')
      await tester.tap(find.text('Dañada'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.reason, equals('damaged'));
      expect(
        result!.targets,
        equals([ReassignTarget.patient, ReassignTarget.guardian2]),
      );
    });

    testWidgets('prevents deselecting the only selected target card', (
      tester,
    ) async {
      ReassignSelection? result;

      await tester.pumpWidget(
        _wrapWithButton(
          isEs: true,
          hasG1: true,
          hasG2: false,
          onResult: (res) => result = res,
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Patient is selected by default. Tap it again to attempt deselecting
      await tester.tap(find.text('Dispositivo del paciente'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.targets, equals([ReassignTarget.patient]));
    });

    testWidgets(
      'allows toggling selected cards on and off when multiple are selected',
      (tester) async {
        ReassignSelection? result;

        await tester.pumpWidget(
          _wrapWithButton(
            isEs: true,
            hasG1: true,
            hasG2: false,
            onResult: (res) => result = res,
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Add Guardian 1
        await tester.tap(find.text('Dispositivo guardián'));
        await tester.pumpAndSettle();

        // Remove Patient
        await tester.tap(find.text('Dispositivo del paciente'));
        await tester.pumpAndSettle();

        // Confirm
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.targets, equals([ReassignTarget.guardian1]));
      },
    );

    testWidgets('returns null when Cancel button is tapped', (tester) async {
      ReassignSelection? result = const ReassignSelection(
        targets: [ReassignTarget.patient],
        reason: 'lost',
      );

      await tester.pumpWidget(
        _wrapWithButton(
          isEs: true,
          hasG1: false,
          hasG2: false,
          onResult: (res) => result = res,
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
