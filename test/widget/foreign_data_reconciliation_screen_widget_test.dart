// test/widget/foreign_data_reconciliation_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/foreign_data_reconciliation_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLocalPatientEntry extends Mock implements LocalPatientEntry {}

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
        expect(find.textContaining('usuario usr-previo-123'), findsOneWidget);
        expect(find.text('Pacientes pendientes'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Accesos de emergencia pendientes'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        expect(
          find.text('Volver e iniciar sesión como el usuario anterior'),
          findsOneWidget,
        );
        expect(
          find.text('Exportar / revisar antes de decidir'),
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
      'Exportar / revisar abre la pantalla _PendingDataExportScreen con datos',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockRecord1 = MockLocalPatientEntry();
        when(() => mockRecord1.patientId).thenReturn('p-001');
        when(() => mockRecord1.maskedName).thenReturn('Ana G.');
        when(
          () => mockRecord1.createdAt,
        ).thenReturn('2026-09-01T10:00:00.000Z');
        when(() => mockRecord1.revision).thenReturn(1);
        when(() => mockRecord1.ownerUserId).thenReturn('usr-previo-123');

        final mockRecord2 = MockLocalPatientEntry();
        when(() => mockRecord2.patientId).thenReturn('p-002');
        when(() => mockRecord2.maskedName).thenReturn('Carlos R.');
        when(
          () => mockRecord2.createdAt,
        ).thenReturn('2026-09-02T11:00:00.000Z');
        when(() => mockRecord2.revision).thenReturn(0);
        when(() => mockRecord2.ownerUserId).thenReturn(null);

        final logs = <Map<String, Object?>>[
          {
            'id': 101,
            'patient_uid': '04:AA:BB',
            'reason': 'guardian_absent_offline',
            'occurred_at': '2026-09-03T12:00:00.000Z',
            'owner_user_id': 'usr-previo-123',
          },
          {
            'id': 102,
            'patient_uid': '04:CC:DD',
            'reason': 'emergency_access',
            'occurred_at': '2026-09-04T13:00:00.000Z',
            'owner_user_id': null,
          },
        ];

        when(
          () => mockAuthRepository.pendingForeignRecordsForReview(),
        ).thenAnswer((_) async => [mockRecord1, mockRecord2]);

        when(
          () => mockAuthRepository.pendingForeignEmergencyLogsForReview(),
        ).thenAnswer((_) async => logs);

        await tester.pumpWidget(buildTestableWidget());

        await tester.tap(find.text('Exportar / revisar antes de decidir'));
        await tester.pumpAndSettle();

        expect(find.text('Revisión de datos pendientes'), findsOneWidget);
        expect(
          find.textContaining('=== Pacientes pendientes (2) ==='),
          findsOneWidget,
        );
        expect(
          find.textContaining('=== Accesos de emergencia pendientes (2) ==='),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '- p-001 | Ana G. | creado 2026-09-01T10:00:00.000Z | revisión 1 | dueño: usr-previo-123',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '- p-002 | Carlos R. | creado 2026-09-02T11:00:00.000Z | revisión 0 | dueño: (sin dueño)',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '- id 101 | paciente 04:AA:BB | motivo guardian_absent_offline | ocurrió 2026-09-03T12:00:00.000Z | dueño: usr-previo-123',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '- id 102 | paciente 04:CC:DD | motivo emergency_access | ocurrió 2026-09-04T13:00:00.000Z | dueño: (sin dueño)',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'botón copiar al portapapeles en _PendingDataExportScreen guarda texto y muestra SnackBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(
          () => mockAuthRepository.pendingForeignRecordsForReview(),
        ).thenAnswer((_) async => []);

        when(
          () => mockAuthRepository.pendingForeignEmergencyLogsForReview(),
        ).thenAnswer((_) async => []);

        final List<String> clipboardLog = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'Clipboard.setData') {
                final args = methodCall.arguments as Map<dynamic, dynamic>;
                clipboardLog.add(args['text'] as String);
              }
              return null;
            });

        await tester.pumpWidget(buildTestableWidget());

        await tester.tap(find.text('Exportar / revisar antes de decidir'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.copy_all_outlined));
        await tester.pumpAndSettle();

        expect(clipboardLog, hasLength(1));
        expect(
          clipboardLog.first,
          contains('=== Pacientes pendientes (0) ==='),
        );
        expect(find.text('Copiado al portapapeles.'), findsOneWidget);
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
      'pantalla de revisión abre correctamente cuando no hay registros ni logs',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(
          () => mockAuthRepository.pendingForeignRecordsForReview(),
        ).thenAnswer((_) async => []);

        when(
          () => mockAuthRepository.pendingForeignEmergencyLogsForReview(),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(buildTestableWidget());

        await tester.tap(find.text('Exportar / revisar antes de decidir'));
        await tester.pumpAndSettle();

        expect(find.text('Revisión de datos pendientes'), findsOneWidget);
        expect(
          find.textContaining('=== Pacientes pendientes (0) ==='),
          findsOneWidget,
        );
        expect(
          find.textContaining('=== Accesos de emergencia pendientes (0) ==='),
          findsOneWidget,
        );
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
