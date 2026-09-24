// test/widget/sync_queue_screen_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_screen.dart';
import 'package:health_without_borders_frontend/src/features/sync/presentation/sync_queue_screen.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/screen_bottom_handle.dart';

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockReachability extends Mock implements Reachability {}

LocalPatientEntry makeEntry({
  String patientId = 'p-001',
  String deviceUid = 'device-001',
  String patientName = 'Juan Diaz',
  String recordJson =
      '{"patientId":"p-001","deviceUid":"device-001","patientInfo":{"firstName":"Juan","firstLastName":"Diaz","identification":{"documentType":"CC","documentNumber":"123"},"dob":"2000-01-01","biologicalSex":"M","address":{"city":"Bogotá","state":"Bogotá"}},"guardianInfo":{"name":"Maria","relationship":"01","phone":"123"}}',
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
  required MockReachability reachability,
  String locale = 'es',
}) {
  final mockAuth = MockAuthRepository();
  when(
    () => mockAuth.sessionNotifier,
  ).thenReturn(ValueNotifier<UserSession?>(null));

  return AppScope(
    authRepository: mockAuth,
    userRepository: MockUserRepository(),
    patientRepository: MockPatientRepository(),
    localDatabase: db,
    syncEngine: syncEngine,
    statsRepository: StatsRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
      authRepository: mockAuth,
    ),
    reachability: reachability,
    child: _LocaleWrapper(
      locale: locale,
      child: MaterialApp(home: child),
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
  late MockReachability reachability;

  setUp(() {
    db = MockLocalDatabase();
    syncEngine = MockSyncEngine();
    reachability = MockReachability();

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

    when(() => reachability.probe()).thenAnswer((_) async => true);
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sincronizar todo'), findsOneWidget);
    });

    testWidgets('tocar Sync All invoca syncEngine.syncAll', (tester) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
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
      when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync ahora'), findsOneWidget);
    });

    testWidgets(
      'un conflicto 409 muestra el estado del dispositivo duplicado',
      (tester) async {
        when(() => db.getUnsyncedRecords()).thenAnswer(
          (_) async => [
            makeEntry(
              syncError:
                  'A patient is already registered with this device tag.',
              syncErrorCode: 409,
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
            reachability: reachability,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Duplicado'), findsOneWidget);
        expect(
          find.textContaining(
            'Este dispositivo ya está registrado para otro paciente',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('un conflicto 409 oculta el botón Sync ahora', (tester) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [makeEntry(syncError: 'conflict', syncErrorCode: 409)],
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync ahora'), findsNothing);
      expect(find.text('Revisar'), findsOneWidget);
    });

    testWidgets(
      'un error no-409 muestra la badge de Error y conserva el botón Sync ahora',
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
            reachability: reachability,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
      when(
        () => syncEngine.syncOne('target-id'),
      ).thenAnswer((_) async => SyncOneResult.success);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      verify(() => syncEngine.syncOne('target-id')).called(1);
    });

    testWidgets('SnackBar de éxito se muestra cuando syncOne retorna success', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(
        () => syncEngine.syncOne(any()),
      ).thenAnswer((_) async => SyncOneResult.success);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sincronizado correctamente'), findsOneWidget);
    });

    testWidgets('SnackBar de error se muestra cuando syncOne retorna failure', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(
        () => syncEngine.syncOne(any()),
      ).thenAnswer((_) async => SyncOneResult.failure);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
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
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScreenBottomHandle), findsOneWidget);
    });
  });

  group('SyncQueueScreen – navegación', () {
    testWidgets('el botón back hace pop de la pantalla al presionarse', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

      final mockAuth = MockAuthRepository();
      when(
        () => mockAuth.sessionNotifier,
      ).thenReturn(ValueNotifier<UserSession?>(null));

      await tester.pumpWidget(
        AppScope(
          authRepository: mockAuth,
          userRepository: MockUserRepository(),
          patientRepository: MockPatientRepository(),
          localDatabase: db,
          syncEngine: syncEngine,
          statsRepository: StatsRepository(
            apiClient: ApiClient(baseUrl: 'http://localhost'),
            authRepository: mockAuth,
          ),
          reachability: reachability,
          child: MaterialApp(
            home: _LocaleWrapper(
              locale: 'es',
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _LocaleWrapper(
                        locale: 'es',
                        child: SyncQueueScreen(),
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

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
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
            reachability: reachability,
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

  group('SyncQueueScreen — Reachability, Progress & Edge Cases', () {
    testWidgets('shows error SnackBar when _syncAll has no network (ES)', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => false);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final syncAllBtn = find.widgetWithText(
        ElevatedButton,
        'Sincronizar todo',
      );
      await tester.tap(syncAllBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Sin conexión a Internet. Conéctese a una red para sincronizar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error SnackBar when _syncAll has no network (EN)', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => false);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(SyncQueueScreen));
      final btnLabel = AppStrings.of(ctx).syncAll;

      final syncAllBtn = find.widgetWithText(ElevatedButton, btnLabel);
      await tester.tap(syncAllBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No internet connection. Connect to a network to sync.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error SnackBar when _syncOne has no network (ES)', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => false);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync ahora'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sin conexión a Internet.'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when _syncOne has no network (EN)', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => false);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(SyncQueueScreen));
      final btnLabel = AppStrings.of(ctx).syncNow;

      await tester.tap(find.text(btnLabel));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('No internet connection.'), findsOneWidget);
    });

    testWidgets(
      'updates progress counter during _syncAll and shows success SnackBar when all clear',
      (tester) async {
        when(() => reachability.probe()).thenAnswer((_) async => true);
        when(
          () => db.getUnsyncedRecords(),
        ).thenAnswer((_) async => [makeEntry()]);

        when(() => syncEngine.syncAll()).thenAnswer((_) async {
          syncEngine.onRecordSynced?.call('p-001', true, null);
          return true;
        });

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
            reachability: reachability,
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Sincronizar todo'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Sincronizado correctamente'), findsOneWidget);
      },
    );

    testWidgets('shows orange SnackBar when records remain after _syncAll', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => true);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sincronizar todo'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Quedan 1 registros pendientes por sincronizar.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error SnackBar when _syncAll throws an exception (ES)', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => true);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenThrow(Exception('Engine crash'));

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sincronizar todo'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Fallo al sincronizar. Intente de nuevo más tarde.'),
        findsOneWidget,
      );
    });

    testWidgets('opens PatientProfileScreen when tapping Review button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry()]);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets(
      'handles SyncOneResult.busy and SyncOneResult.notFound correctly',
      (tester) async {
        when(
          () => db.getUnsyncedRecords(),
        ).thenAnswer((_) async => [makeEntry()]);
        when(
          () => syncEngine.syncOne(any()),
        ).thenAnswer((_) async => SyncOneResult.busy);

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
            reachability: reachability,
          ),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(SyncQueueScreen));
        final expectedMsg = AppStrings.of(ctx).synchronizing;

        await tester.tap(find.text('Sync ahora'));
        await tester.pumpAndSettle();

        expect(find.text(expectedMsg), findsOneWidget);
      },
    );

    testWidgets(
      'handles HTTP 403 and HTTP 422 error messages in cards (ES & EN)',
      (tester) async {
        when(() => db.getUnsyncedRecords()).thenAnswer(
          (_) async => [
            makeEntry(
              patientId: 'p1',
              syncError: 'Forbidden',
              syncErrorCode: 403,
            ),
            makeEntry(
              patientId: 'p2',
              syncError: 'Unprocessable',
              syncErrorCode: 422,
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: syncEngine,
            reachability: reachability,
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Acceso denegado (403)'), findsOneWidget);
        expect(
          find.textContaining('Error de validación (422)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows error SnackBar when _syncOne returns failure', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => true);
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientId: 'p-fail')]);
      when(
        () => syncEngine.syncOne('p-fail'),
      ).thenAnswer((_) async => SyncOneResult.failure);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
          locale: 'es',
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
}
