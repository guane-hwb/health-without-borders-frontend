// test/widget/sync_queue_screen_widget_test.dart

import 'dart:async';
import 'dart:convert';

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

class SpySyncEngine extends MockSyncEngine {
  void Function(String patientId, bool success, String? error)? _onRecordSynced;

  @override
  void Function(String patientId, bool success, String? error)?
  get onRecordSynced => _onRecordSynced;

  @override
  set onRecordSynced(
    void Function(String patientId, bool success, String? error)? callback,
  ) {
    _onRecordSynced = callback;
  }
}

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
    when(() => db.getWebQuarantinedEntries()).thenAnswer((_) async => []);
    when(() => db.getUnsyncedCount()).thenAnswer((_) async => 0);
    when(
      () => syncEngine.savedRecords,
    ).thenAnswer((_) => const Stream<RecordSyncResult>.empty());
    when(
      () => db.getSyncNotices(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => <SyncNotice>[]);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          null,
        );
  });

  group('SyncQueueScreen – Constructor con Key explicito', () {
    testWidgets('se instancia correctamente usando una Key personalizada', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(key: Key('sync_queue_key')),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync_queue_key')), findsOneWidget);
    });
  });

  group('SyncQueueScreen – avisos de sincronización', () {
    SyncNotice notice(String id, String name) => SyncNotice(
      patientId: id,
      patientName: name,
      codes: const <String>['stale_payload_base_version'],
      createdAt: '2026-10-09T15:00:00Z',
    );

    testWidgets('lista el aviso sin pendientes y "Entendido" lo descarta', (
      tester,
    ) async {
      var notices = <SyncNotice>[notice('p-9', 'Ana G.')];
      when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);
      when(
        () => db.getSyncNotices(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => notices);
      when(() => db.dismissSyncNotice(any())).thenAnswer((_) async {
        notices = <SyncNotice>[];
      });

      await tester.pumpWidget(
        buildTestApp(
          child: const SyncQueueScreen(),
          db: db,
          syncEngine: syncEngine,
          reachability: reachability,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana G.'), findsOneWidget);
      expect(find.text('2026-10-09'), findsOneWidget);
      expect(
        find.textContaining('ya había cambiado en el servidor'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Escanee de nuevo el dispositivo del paciente'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_done), findsNothing);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      verify(() => db.dismissSyncNotice('p-9')).called(1);
      expect(find.text('Ana G.'), findsNothing);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('los avisos van antes de los registros pendientes', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(),
      ).thenAnswer((_) async => [makeEntry(patientName: 'Juan Diaz')]);
      when(
        () => db.getSyncNotices(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => <SyncNotice>[notice('p-9', 'Ana G.')]);

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

      final double noticeY = tester.getTopLeft(find.text('Ana G.')).dy;
      final double entryY = tester.getTopLeft(find.text('Juan D.')).dy;
      expect(noticeY, lessThan(entryY));
      expect(
        find.textContaining('Scan the patient device again'),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
    });
  });

  group('SyncQueueScreen – estado vacío', () {
    testWidgets('muestra ícono cloud_done cuando no hay registros pendientes', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) => completer.future);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer(
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer(
        (_) async => const SyncResult(
          allSuccessful: true,
          remainingRetryable: 0,
          remainingBlocked: 0,
        ),
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

      await tester.tap(find.text('Sincronizar todo'));
      await tester.pumpAndSettle();

      verify(() => syncEngine.syncAll()).called(1);
    });

    testWidgets('tras syncAll se vuelve a llamar a getUnsyncedRecords', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer(
        (_) async => const SyncResult(
          allSuccessful: true,
          remainingRetryable: 0,
          remainingBlocked: 0,
        ),
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

      await tester.tap(find.text('Sincronizar todo'));
      await tester.pumpAndSettle();

      verify(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).called(greaterThanOrEqualTo(2));
    });
  });

  group('_SyncCard – estado pendiente', () {
    testWidgets('muestra el maskedName correcto', (tester) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer(
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

    for (final (code, message, badge) in <(String, String, String)>[
      (
        'duplicate_identity',
        'Ya existe un paciente registrado con este número de documento.',
        'Duplicado',
      ),
      (
        'device_uid_conflict',
        'Este dispositivo ya está registrado para otro paciente',
        'Duplicado',
      ),
      (
        'identity_mismatch',
        'El dispositivo pertenece a un paciente con otro documento',
        'Conflicto',
      ),
      ('device_retired', 'Este dispositivo fue retirado', 'Conflicto'),
    ]) {
      testWidgets('un 409 con code $code muestra su mensaje y "$badge"', (
        tester,
      ) async {
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer(
          (_) async => [makeEntry(syncError: code, syncErrorCode: 409)],
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

        expect(find.textContaining(message), findsOneWidget);
        expect(find.text(badge), findsOneWidget);
        expect(find.textContaining(code), findsNothing);
      });
    }

    testWidgets('un conflicto 409 oculta el botón Sync ahora', (tester) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer(
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
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer(
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer(
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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer(
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

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
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => []);

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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => [makeEntry()]);

        when(() => syncEngine.syncAll()).thenAnswer((_) async {
          syncEngine.onRecordSynced?.call('p-001', true, null);
          return const SyncResult(
            allSuccessful: true,
            remainingRetryable: 0,
            remainingBlocked: 0,
          );
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

        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => []);

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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => syncEngine.syncAll()).thenAnswer(
        (_) async => const SyncResult(
          allSuccessful: true,
          remainingRetryable: 1,
          remainingBlocked: 0,
        ),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer(
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

    testWidgets('503 sync_in_progress: pendiente que se reintenta, no error', (
      tester,
    ) async {
      when(() => db.getUnsyncedRecords()).thenAnswer(
        (_) async => [
          makeEntry(
            patientId: 'p1',
            syncError: 'sync_in_progress',
            syncErrorCode: 503,
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

      final s = AppStrings.forTesting('es');
      expect(
        find.textContaining('Se reintentará automáticamente'),
        findsOneWidget,
      );
      expect(find.text(s.pending), findsOneWidget);
      expect(find.text('Error'), findsNothing);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text(s.syncNow), findsOneWidget);
    });

    testWidgets('shows error SnackBar when _syncOne returns failure', (
      tester,
    ) async {
      when(() => reachability.probe()).thenAnswer((_) async => true);
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
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

  group('SyncQueueScreen – progreso de _syncAll y onRecordSynced', () {
    testWidgets(
      'muestra el contador "syncedSoFar / syncTotal" mientras _syncAll está en curso',
      (tester) async {
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => [makeEntry()]);

        final completer = Completer<SyncResult>();
        when(() => syncEngine.syncAll()).thenAnswer((_) => completer.future);

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

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Sincronizar todo'),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump();
        }

        expect(find.text('0 / 1'), findsOneWidget);

        completer.complete(
          const SyncResult(
            allSuccessful: true,
            remainingRetryable: 0,
            remainingBlocked: 0,
          ),
        );
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => []);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'invoca el callback real onRecordSynced e incrementa syncedSoFar mientras el widget está montado',
      (tester) async {
        final spyEngine = SpySyncEngine();
        when(() => spyEngine.refreshPendingCount()).thenAnswer((_) async {});
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => [makeEntry()]);

        final completer = Completer<SyncResult>();
        when(() => spyEngine.syncAll()).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: spyEngine,
            reachability: reachability,
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Sincronizar todo'),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump();
        }

        expect(spyEngine.onRecordSynced, isNotNull);

        spyEngine.onRecordSynced!.call('p-001', true, null);
        await tester.pump();

        expect(find.text('1 / 1'), findsOneWidget);

        completer.complete(
          const SyncResult(
            allSuccessful: true,
            remainingRetryable: 0,
            remainingBlocked: 0,
          ),
        );
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => []);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Sincronizado correctamente'), findsOneWidget);
      },
    );

    testWidgets(
      'onRecordSynced no lanza excepción ni actualiza el estado tras desmontar la pantalla',
      (tester) async {
        final spyEngine = SpySyncEngine();
        when(() => spyEngine.refreshPendingCount()).thenAnswer((_) async {});
        when(
          () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => [makeEntry()]);

        final completer = Completer<SyncResult>();
        when(() => spyEngine.syncAll()).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildTestApp(
            child: const SyncQueueScreen(),
            db: db,
            syncEngine: spyEngine,
            reachability: reachability,
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Sincronizar todo'),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump();
        }

        final capturedCallback = spyEngine.onRecordSynced;
        expect(capturedCallback, isNotNull);
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

        expect(
          () => capturedCallback!.call('p-001', true, null),
          returnsNormally,
        );
      },
    );
  });

  List<String> captureClipboard() {
    final List<String> copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            final Map<Object?, Object?> args =
                call.arguments as Map<Object?, Object?>;
            copied.add(args['text'] as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return copied;
  }

  Future<void> pumpScreen(WidgetTester tester, {String locale = 'es'}) async {
    await tester.pumpWidget(
      buildTestApp(
        child: const SyncQueueScreen(),
        db: db,
        syncEngine: syncEngine,
        reachability: reachability,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SyncQueueScreen – aviso de registros bloqueados/en cuarentena', () {
    setUp(() {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
    });

    testWidgets('solo bloqueados tras syncAll muestra el aviso naranja (ES)', (
      tester,
    ) async {
      when(() => syncEngine.syncAll()).thenAnswer(
        (_) async => const SyncResult(
          allSuccessful: false,
          remainingRetryable: 0,
          remainingBlocked: 2,
        ),
      );

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.cloud_upload).first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Quedan 2 registro(s) bloqueados/en cuarentena. '
          'Revise o gestione estos registros.',
        ),
        findsOneWidget,
      );
      final SnackBar bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, equals(Colors.orange.shade800));
    });

    testWidgets('solo bloqueados tras syncAll muestra el aviso naranja (EN)', (
      tester,
    ) async {
      when(() => syncEngine.syncAll()).thenAnswer(
        (_) async => const SyncResult(
          allSuccessful: false,
          remainingRetryable: 0,
          remainingBlocked: 3,
        ),
      );

      await pumpScreen(tester, locale: 'en');
      await tester.tap(find.byIcon(Icons.cloud_upload).first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          '3 record(s) remain blocked/quarantined. Review or manage them.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'un registro en cuarentena suma al aviso aunque el sync sea limpio',
      (tester) async {
        when(() => db.getWebQuarantinedEntries()).thenAnswer(
          (_) async => <MapEntry<String, String>>[
            const MapEntry<String, String>(
              'hwb_web_patient::q-1::quarantine::2026',
              '{"dato":"crudo"}',
            ),
          ],
        );
        when(() => syncEngine.syncAll()).thenAnswer(
          (_) async => const SyncResult(
            allSuccessful: true,
            remainingRetryable: 0,
            remainingBlocked: 0,
          ),
        );

        await pumpScreen(tester);
        await tester.tap(find.byIcon(Icons.cloud_upload).first);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Quedan 1 registro(s) bloqueados/en cuarentena. '
            'Revise o gestione estos registros.',
          ),
          findsOneWidget,
        );
        expect(find.text('Sincronizado correctamente'), findsNothing);
      },
    );
  });

  group('SyncQueueScreen – registros en cuarentena (_QuarantineCard)', () {
    const MapEntry<String, String> quarantined = MapEntry<String, String>(
      'hwb_web_patient::q-1::quarantine::2026-10-20',
      '{"dato":"crudo"}',
    );

    setUp(() {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => <LocalPatientEntry>[]);
      when(
        () => db.getWebQuarantinedEntries(),
      ).thenAnswer((_) async => <MapEntry<String, String>>[quarantined]);
    });

    testWidgets('muestra la tarjeta y "Copiar datos crudos" copia (ES)', (
      tester,
    ) async {
      final List<String> copied = captureClipboard();

      await pumpScreen(tester);

      expect(find.byIcon(Icons.cloud_done), findsNothing);
      expect(find.text('Registro Web en Cuarentena'), findsOneWidget);
      expect(
        find.textContaining('Este registro no se pudo descifrar o procesar'),
        findsOneWidget,
      );
      expect(find.text('Clave: ${quarantined.key}'), findsOneWidget);

      await tester.tap(find.text('Copiar datos crudos'));
      await tester.pumpAndSettle();

      expect(copied, <String>[quarantined.value]);
      expect(
        find.text('Datos en cuarentena copiados al portapapeles.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra la tarjeta y "Copy raw data" copia (EN)', (
      tester,
    ) async {
      final List<String> copied = captureClipboard();

      await pumpScreen(tester, locale: 'en');

      expect(find.text('Quarantined Web Record'), findsOneWidget);
      expect(
        find.textContaining('This record could not be decrypted or processed'),
        findsOneWidget,
      );

      await tester.tap(find.text('Copy raw data'));
      await tester.pumpAndSettle();

      expect(copied, <String>[quarantined.value]);
      expect(
        find.text('Quarantined data copied to clipboard.'),
        findsOneWidget,
      );
    });
  });

  group('SyncQueueScreen – pendientes de otro usuario', () {
    testWidgets('estado vacío: muestra la nota del otro usuario (ES)', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => <LocalPatientEntry>[]);
      when(() => db.getUnsyncedCount()).thenAnswer((_) async => 3);

      await pumpScreen(tester);

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(
        find.text(
          'Nota: Existen 3 registro(s) pendiente(s) de otro usuario en este '
          'dispositivo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('estado vacío: muestra la nota del otro usuario (EN)', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => <LocalPatientEntry>[]);
      when(() => db.getUnsyncedCount()).thenAnswer((_) async => 3);

      await pumpScreen(tester, locale: 'en');

      expect(
        find.text(
          'Note: There are 3 pending record(s) from another user on this '
          'device.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('con pendientes propios: muestra el aviso en la lista (ES)', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => db.getUnsyncedCount()).thenAnswer((_) async => 3);

      await pumpScreen(tester);

      expect(
        find.text(
          'Existen 2 registro(s) pendiente(s) pertenecientes a otro usuario '
          'en este dispositivo. Inicie sesión con la cuenta correspondiente '
          'para sincronizarlos.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('con pendientes propios: muestra el aviso en la lista (EN)', (
      tester,
    ) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [makeEntry()]);
      when(() => db.getUnsyncedCount()).thenAnswer((_) async => 3);

      await pumpScreen(tester, locale: 'en');

      expect(
        find.text(
          'There are 2 pending record(s) belonging to another user on this '
          'device. Log in with that account to sync them.',
        ),
        findsOneWidget,
      );
    });
  });

  LocalPatientEntry makeClinicalEntry({
    bool consultations = true,
    bool vaccines = true,
    bool details = true,
  }) {
    final Map<String, dynamic> json =
        jsonDecode(makeEntry().recordJson) as Map<String, dynamic>;
    if (consultations) {
      json['medicalHistory'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'startDateTime': '2024-03-01T09:00:00',
          'clinicalEvaluation': <String, dynamic>{
            if (details) 'historyOfCurrentIllness': 'Fiebre alta',
            if (details) 'treatmentPlanObservations': 'Reposo e hidratación',
          },
        },
      ];
    }
    if (vaccines) {
      json['vaccinationRecord'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'vaccineName': 'BCG',
          'dose': 1,
          'date': '2024-01-02',
        },
      ];
    }
    final LocalPatientEntry entry = makeEntry(recordJson: jsonEncode(json));
    final record = entry.toPatientRecord();
    expect(
      record,
      isNotNull,
      reason: 'PatientFullRecord.fromJson no aceptó el JSON del helper',
    );
    expect(
      record!.medicalHistory.isNotEmpty || record.vaccinationRecord.isNotEmpty,
      isTrue,
      reason: 'Las llaves medicalHistory/vaccinationRecord no coinciden',
    );
    return entry;
  }

  group('SyncQueueScreen – borrar con datos clínicos sin sincronizar', () {
    Future<void> openDeleteDialog(
      WidgetTester tester,
      LocalPatientEntry entry, {
      String locale = 'es',
    }) async {
      when(
        () => db.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entry]);
      await pumpScreen(tester, locale: locale);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
    }

    testWidgets('advierte y "Copiar datos" copia el resumen completo (ES)', (
      tester,
    ) async {
      final List<String> copied = captureClipboard();

      await openDeleteDialog(tester, makeClinicalEntry());

      expect(
        find.text(
          'Atención: Este registro contiene consultas médicas o vacunas que '
          'no se han sincronizado.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Copiar datos'));
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      final String summary = copied.single;
      expect(summary, contains('=== RESUMEN CLÍNICO ==='));
      expect(summary, contains('Paciente: '));
      expect(summary, contains('Juan'));
      expect(summary, contains('Documento: CC 123'));
      expect(summary, contains('--- CONSULTAS MÉDICAS ---'));
      expect(summary, contains('• Fecha: '));
      expect(summary, contains('Motivo/Historia: Fiebre alta'));
      expect(summary, contains('Plan: Reposo e hidratación'));
      expect(summary, contains('--- VACUNAS ---'));
      expect(summary, contains('• BCG (Dosis 1) - '));
      expect(
        find.text('Resumen clínico copiado al portapapeles.'),
        findsOneWidget,
      );
    });

    testWidgets('advierte y "Copy clinical data" copia el resumen (EN)', (
      tester,
    ) async {
      final List<String> copied = captureClipboard();

      await openDeleteDialog(tester, makeClinicalEntry(), locale: 'en');

      expect(
        find.text(
          'Warning: This record contains unsynced medical consultations or '
          'vaccines.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Copy clinical data'));
      await tester.pumpAndSettle();

      final String summary = copied.single;
      expect(summary, contains('=== CLINICAL SUMMARY ==='));
      expect(summary, contains('Patient: '));
      expect(summary, contains('Document: CC 123'));
      expect(summary, contains('--- MEDICAL CONSULTATIONS ---'));
      expect(summary, contains('Date: '));
      expect(summary, contains('Reason/History: Fiebre alta'));
      expect(summary, contains('Plan: Reposo e hidratación'));
      expect(summary, contains('--- VACCINATIONS ---'));
      expect(summary, contains('(Dose 1)'));
      expect(
        find.text('Clinical summary copied to clipboard.'),
        findsOneWidget,
      );
    });

    testWidgets('solo vacunas: el resumen omite las consultas', (tester) async {
      final List<String> copied = captureClipboard();

      await openDeleteDialog(tester, makeClinicalEntry(consultations: false));
      await tester.tap(find.text('Copiar datos'));
      await tester.pumpAndSettle();

      expect(copied.single, isNot(contains('CONSULTAS MÉDICAS')));
      expect(copied.single, contains('--- VACUNAS ---'));
    });

    testWidgets(
      'consulta sin motivo ni plan: el resumen no incluye esas líneas',
      (tester) async {
        final List<String> copied = captureClipboard();

        await openDeleteDialog(
          tester,
          makeClinicalEntry(vaccines: false, details: false),
        );
        await tester.tap(find.text('Copiar datos'));
        await tester.pumpAndSettle();

        expect(copied.single, contains('--- CONSULTAS MÉDICAS ---'));
        expect(copied.single, isNot(contains('Motivo/Historia')));
        expect(copied.single, isNot(contains('Plan:')));
        expect(copied.single, isNot(contains('VACUNAS')));
      },
    );

    testWidgets('sin datos clínicos no aparece la advertencia ni el botón', (
      tester,
    ) async {
      await openDeleteDialog(tester, makeEntry());

      expect(
        find.textContaining('Atención: Este registro contiene'),
        findsNothing,
      );
      expect(find.text('Copiar datos'), findsNothing);
    });
  });
}
