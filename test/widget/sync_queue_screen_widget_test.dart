// test/widget/sync_queue_screen_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/sync/presentation/sync_queue_screen.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/screen_bottom_handle.dart';

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

LocalPatientEntry makeEntry({
  String patientId = 'p-001',
  String deviceUid = 'device-001',
  String patientName = 'Juan Diaz',
  String recordJson = '{"patientId":"p-001"}',
  bool isSynced = false,
  String? syncError,
  int? syncErrorCode,
  String createdAt = '2024-05-01T10:00:00',
}) => LocalPatientEntry(
  patientId: patientId,
  deviceUid: deviceUid,
  patientName: patientName,
  recordJson: recordJson,
  isSynced: isSynced,
  syncError: syncError,
  syncErrorCode: syncErrorCode,
  createdAt: createdAt,
);

Widget buildTestApp({
  required Widget child,
  required MockLocalDatabase db,
  required MockSyncEngine syncEngine,
  String locale = 'es',
}) {
  return MaterialApp(
    home: _LocaleWrapper(
      locale: locale,
      child: AppScope(
        authRepository: MockAuthRepository(),
        userRepository: MockUserRepository(),
        patientRepository: MockPatientRepository(),
        localDatabase: db,
        syncEngine: syncEngine,
        statsRepository: StatsRepository(
          apiClient: ApiClient(baseUrl: 'http://localhost'),
          authRepository: MockAuthRepository(),
        ),
        child: child,
      ),
    ),
  );
}

class _LocaleWrapper extends StatefulWidget {
  const _LocaleWrapper({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_LocaleWrapper> createState() => _LocaleWrapperState();
}

class _LocaleWrapperState extends State<_LocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (l) => setState(() => _locale = l),
      child: widget.child,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalDatabase db;
  late MockSyncEngine syncEngine;

  setUp(() {
    db = MockLocalDatabase();
    syncEngine = MockSyncEngine();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'check') {
              return <String>['wifi'];
            }
            return null;
          },
        );

    when(() => syncEngine.refreshPendingCount()).thenAnswer((_) async {});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          null,
        );
  });

  group('SyncQueueScreen – estado vacío', () {
    testWidgets('muestra ícono cloud_done cuando no hay registros pendientes', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('muestra texto allSynced cuando la lista está vacía', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todo sincronizado'), findsOneWidget);
    });

    testWidgets('muestra texto noRecordsPending cuando la lista está vacía', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay registros pendientes.'), findsOneWidget);
    });

    testWidgets('el botón Sync All NO se muestra cuando no hay entradas', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byIcon(Icons.cloud_upload),
          matching: find.byType(ElevatedButton),
        ),
        findsNothing,
      );
    });
  });

  group('SyncQueueScreen – estado de carga', () {
    testWidgets('muestra CircularProgressIndicator mientras carga', (
      tester,
    ) async {
      final completer = Completer<List<LocalPatientEntry>>();
      when(() => db.getUnsyncedRecords()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('SyncQueueScreen – con entradas', () {
    testWidgets('renderiza una _SyncCard por entrada', (tester) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [
          makeEntry(patientId: 'p-1', patientName: 'Ana Avila'),
          makeEntry(patientId: 'p-2', patientName: 'Bruno Blanco'),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana A.'), findsOneWidget);
      expect(find.text('Bruno B.'), findsOneWidget);
    });

    testWidgets('el botón Sync All es visible cuando hay entradas', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sincronizar todo'), findsOneWidget);
    });

    testWidgets('tocar Sync All invoca syncEngine.syncAll', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sincronizar todo'));
      await tester.pumpAndSettle();

      verify(() => syncEngine.syncAll()).called(1);
    });

    testWidgets('tras syncAll se vuelve a llamar a getUnsyncedRecords', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sincronizar todo'));
      await tester.pumpAndSettle();

      verify(() => db.getUnsyncedRecords()).called(greaterThanOrEqualTo(2));
    });
  });

  group('_SyncCard – estado pendiente', () {
    testWidgets('muestra el maskedName correcto', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientName: 'Teresa Torres')]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Teresa T.'), findsOneWidget);
    });

    testWidgets('muestra la parte de fecha antes de T', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(createdAt: '2024-07-04T12:00:00')]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2024-07-04'), findsOneWidget);
    });

    testWidgets('muestra la fecha tal cual cuando no tiene T', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(createdAt: '2024-07-04')]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2024-07-04'), findsOneWidget);
    });

    testWidgets('muestra badge "Pendiente" cuando no hay error', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(syncError: null)]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('NO muestra texto de error cuando syncError es null', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(syncError: null)]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsNothing);
    });

    testWidgets('botón Sync Now está presente por cada card', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync ahora'), findsOneWidget);
    });

    testWidgets('un conflicto 409 muestra el estado de manilla duplicada', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [
          makeEntry(
            syncError: 'A patient is already registered with this device tag.',
            syncErrorCode: 409,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duplicado'), findsOneWidget);
      expect(
        find.textContaining('ya está registrada para otro paciente'),
        findsOneWidget,
      );
    });

    testWidgets('un conflicto 409 oculta el botón Sync ahora', (tester) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [makeEntry(syncError: 'conflict', syncErrorCode: 409)],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync ahora'), findsNothing);
      expect(find.text('Revisar'), findsOneWidget);
    });

    testWidgets(
      'un error no-409 conserva el estado pendiente y el botón Sync ahora',
      (tester) async {
        when(() => db.getUnsyncedRecords()).thenAnswer(
          (_) async => [
            makeEntry(syncError: 'error de servidor', syncErrorCode: 500),
          ],
        );

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text('Sync ahora'), findsOneWidget);
      },
    );

    testWidgets('botón Review está presente por cada card', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revisar'), findsOneWidget);
    });

    testWidgets('botón Delete (ícono) está presente por cada card', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('_SyncCard – estado de error', () {
    testWidgets('muestra badge "Duplicado" cuando hay conflicto 409', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [
          makeEntry(
            syncError: 'A patient is already registered with this device tag.',
            syncErrorCode: 409,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duplicado'), findsOneWidget);
    });

    testWidgets('la card tiene borde cuando hay error de conflicto', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [
          makeEntry(
            syncError: 'A patient is already registered with this device tag.',
            syncErrorCode: 409,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBorder = containers.any((c) {
        final deco = c.decoration as BoxDecoration?;
        return deco?.border != null;
      });
      expect(hasBorder, isTrue);
    });
  });

  group('_SyncCard – Sync Now', () {
    testWidgets('tocar Sync Now llama syncOne con el id correcto', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientId: 'target-id')]);
      when(() => syncEngine.syncOne('target-id')).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      verify(() => syncEngine.syncOne('target-id')).called(1);
    });

    testWidgets('SnackBar de éxito se muestra cuando syncOne retorna true', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncOne(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sincronizado correctamente'), findsOneWidget);
    });

    testWidgets('SnackBar de error se muestra cuando syncOne retorna false', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncOne(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Sincronización fallida — se reintentará'),
        findsOneWidget,
      );
    });
  });

  group('_SyncCard – flujo de eliminación', () {
    testWidgets('tocar el ícono de eliminar abre el AlertDialog', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('el diálogo muestra el maskedName en su contenido', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientName: 'Xavier Ybarra')]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Xavier Y.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirmar eliminar llama db.deleteRecord con el id correcto', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientId: 'del-me')]);
      when(() => db.deleteRecord('del-me')).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(() => db.deleteRecord('del-me')).called(1);
    });

    testWidgets('cancelar eliminar NO llama a db.deleteRecord', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => db.deleteRecord(any()));
    });
  });

  group('SyncQueueScreen – ScreenBottomHandle', () {
    testWidgets('ScreenBottomHandle siempre se renderiza', (tester) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScreenBottomHandle), findsOneWidget);
    });
  });

  group('SyncQueueScreen – navegación', () {
    testWidgets('el botón back hace pop de la pantalla', (tester) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: _LocaleWrapper(
            locale: 'es',
            child: AppScope(
              authRepository: MockAuthRepository(),
              userRepository: MockUserRepository(),
              patientRepository: MockPatientRepository(),
              localDatabase: db,
              syncEngine: syncEngine,
              statsRepository: StatsRepository(
                apiClient: ApiClient(baseUrl: 'http://localhost'),
                authRepository: MockAuthRepository(),
              ),
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => AppScope(
                        authRepository: MockAuthRepository(),
                        userRepository: MockUserRepository(),
                        patientRepository: MockPatientRepository(),
                        localDatabase: db,
                        syncEngine: syncEngine,
                        statsRepository: StatsRepository(
                          apiClient: ApiClient(baseUrl: 'http://localhost'),
                          authRepository: MockAuthRepository(),
                        ),
                        child: const _LocaleWrapper(
                          locale: 'es',
                          child: SyncQueueScreen(),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(SyncQueueScreen), findsOneWidget);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(SyncQueueScreen), findsNothing);
    });

    testWidgets(
      'alternar el idioma de ES a EN actualiza los componentes textuales de forma reactiva',
      (tester) async {
        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(SyncQueueScreen),
        );
        final sEs = AppStrings.of(context);

        expect(find.text(sEs.allSynced), findsOneWidget);

        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        final BuildContext contextEn = tester.element(
          find.byType(SyncQueueScreen),
        );
        final sEn = AppStrings.of(contextEn);

        expect(find.text(sEn.allSynced), findsOneWidget);
        expect(find.text(sEs.allSynced), findsNothing);
      },
    );
  });
}
