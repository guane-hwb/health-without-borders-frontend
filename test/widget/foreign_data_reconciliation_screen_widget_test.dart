// test/widget/foreign_data_reconciliation_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/foreign_data_reconciliation_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late ForeignPendingDataException testException;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    testException = ForeignPendingDataException(
      previousOwnerUserId: 'usr-previo-123',
      newUserId: 'usr-nuevo-456',
      pendingPatients: 2,
      pendingEmergencyLogs: 1,
    );
  });

  Widget buildTestableWidget({Widget? child}) {
    return MaterialApp(
      home:
          child ??
          ForeignDataReconciliationScreen(
            authRepository: mockAuthRepository,
            exception: testException,
          ),
    );
  }

  group('ForeignDataReconciliationScreen Widget Tests', () {
    testWidgets(
      'renderiza correctamente todos los contadores e información inicial',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestableWidget());

        expect(find.text('Datos pendientes de otro usuario'), findsOneWidget);
        expect(
          find.textContaining(
            'Este dispositivo aún tiene datos sin sincronizar',
          ),
          findsOneWidget,
        );
        expect(find.text('Pacientes pendientes'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Accesos de emergencia pendientes'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        expect(
          find.text('Volver e iniciar sesión como el usuario anterior'),
          findsOneWidget,
        );
        expect(
          find.text('Descartar y continuar como usuario nuevo'),
          findsOneWidget,
        );
      },
    );

    testWidgets('botón Volver e iniciar sesión desapila la pantalla', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ForeignDataReconciliationScreen(
                    authRepository: mockAuthRepository,
                    exception: testException,
                  ),
                ),
              ),
              child: const Text('Ir a pantalla'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ir a pantalla'));
      await tester.pumpAndSettle();

      expect(find.byType(ForeignDataReconciliationScreen), findsOneWidget);

      await tester.tap(
        find.text('Volver e iniciar sesión como el usuario anterior'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForeignDataReconciliationScreen), findsNothing);
    });

    testWidgets('diálogo de descarte - opción Cancelar no realiza acciones', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Descartar y continuar como usuario nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar los datos pendientes?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar los datos pendientes?'), findsNothing);
      verifyNever(() => mockAuthRepository.discardForeignPendingData());
    });

    testWidgets(
      'diálogo de descarte - confirmación borra los datos y desapila la pantalla',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(() => mockAuthRepository.discardForeignPendingData()).thenAnswer(
          (_) async => Future.delayed(const Duration(milliseconds: 100)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ForeignDataReconciliationScreen(
                      authRepository: mockAuthRepository,
                      exception: testException,
                    ),
                  ),
                ),
                child: const Text('Navegar'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Navegar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Descartar y continuar como usuario nuevo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sí, descartar'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(AbsorbPointer), findsWidgets);

        await tester.pumpAndSettle();

        verify(() => mockAuthRepository.discardForeignPendingData()).called(1);
        expect(find.byType(ForeignDataReconciliationScreen), findsNothing);
      },
    );

    testWidgets(
      'diálogo de descarte - cerrar por toque fuera (null) no realiza acciones',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestableWidget());

        await tester.tap(find.text('Descartar y continuar como usuario nuevo'));
        await tester.pumpAndSettle();

        expect(find.text('¿Descartar los datos pendientes?'), findsOneWidget);

        tester.state<NavigatorState>(find.byType(Navigator).last).pop(null);
        await tester.pumpAndSettle();

        expect(find.text('¿Descartar los datos pendientes?'), findsNothing);
        verifyNever(() => mockAuthRepository.discardForeignPendingData());
      },
    );

    testWidgets(
      'flujo de confirmación de descarte ejecuta la limpieza en el repositorio',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(
          () => mockAuthRepository.discardForeignPendingData(),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ForeignDataReconciliationScreen(
                      authRepository: mockAuthRepository,
                      exception: testException,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Descartar y continuar como usuario nuevo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sí, descartar'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepository.discardForeignPendingData()).called(1);
        expect(find.byType(ForeignDataReconciliationScreen), findsNothing);
      },
    );
  });
}
