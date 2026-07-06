// test/unit/nfc/sync_engine_test.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockLocalPatientEntry extends Mock implements LocalPatientEntry {}

class MockPatientFullRecord extends Mock implements PatientFullRecord {}

class MockPatientSyncResponse extends Mock implements PatientSyncResponse {}

class MockApiException extends Mock implements ApiException {}

class FakePatientFullRecord extends Fake implements PatientFullRecord {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePatientFullRecord());
  });

  late MockPatientRepository patientRepo;
  late MockLocalDatabase localDb;
  late SyncEngine engine;

  // Helpers ------------------------------------------------------------

  MockLocalPatientEntry buildEntry(String id, {PatientFullRecord? record}) {
    final entry = MockLocalPatientEntry();
    when(() => entry.patientId).thenReturn(id);
    when(() => entry.toPatientRecord()).thenReturn(record);
    return entry;
  }

  MockPatientSyncResponse buildResponse(String status, {String? message}) {
    final response = MockPatientSyncResponse();
    when(() => response.status).thenReturn(status);
    when(() => response.message).thenReturn(message ?? '');
    return response;
  }

  MockApiException buildApiException(int statusCode, String message) {
    final exception = MockApiException();
    when(() => exception.statusCode).thenReturn(statusCode);
    when(() => exception.message).thenReturn(message);
    return exception;
  }

  setUp(() {
    patientRepo = MockPatientRepository();
    localDb = MockLocalDatabase();

    when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
    when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => []);
    when(() => localDb.markSynced(any())).thenAnswer((_) async {});
    when(() => localDb.markSyncError(any(), any())).thenAnswer((_) async {});

    engine = SyncEngine(patientRepository: patientRepo, localDatabase: localDb);
  });

  tearDown(() {
    engine.stop();
  });

  // ── refreshPendingCount ────────────────────────────────────────────────

  group('refreshPendingCount', () {
    test('actualiza pendingCount con el valor de la base local', () async {
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 7);

      await engine.refreshPendingCount();

      expect(engine.pendingCount.value, 7);
    });

    test('mantiene el valor previo si la base local lanza un error', () async {
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 3);
      await engine.refreshPendingCount();
      expect(engine.pendingCount.value, 3);

      when(
        () => localDb.getUnsyncedCount(),
      ).thenThrow(Exception('storage down'));
      await engine.refreshPendingCount();

      expect(engine.pendingCount.value, 3);
    });
  });

  // ── syncAll ──────────────────────────────────────────────────────────────

  group('syncAll', () {
    test('sin registros pendientes no llama al repositorio', () async {
      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => []);
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);

      int? notifiedCount;
      engine.onSyncStatusChanged = (count) => notifiedCount = count;

      await engine.syncAll();

      verifyNever(() => patientRepo.syncPatient(any()));
      expect(notifiedCount, 0);
      expect(engine.pendingCount.value, 0);
    });

    test('sincroniza cada registro pendiente y actualiza el conteo', () async {
      final entryA = buildEntry('A', record: MockPatientFullRecord());
      final entryB = buildEntry('B', record: MockPatientFullRecord());

      when(
        () => localDb.getUnsyncedRecords(),
      ).thenAnswer((_) async => [entryA, entryB]);
      when(
        () => patientRepo.syncPatient(any()),
      ).thenAnswer((_) async => buildResponse('success'));
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);

      await engine.syncAll();

      verify(() => patientRepo.syncPatient(any())).called(2);
      verify(() => localDb.markSynced('A')).called(1);
      verify(() => localDb.markSynced('B')).called(1);
      expect(engine.pendingCount.value, 0);
    });

    test(
      'llamadas concurrentes se serializan (segunda no reprocesa)',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);

        final completer = Completer<PatientSyncResponse>();
        when(
          () => patientRepo.syncPatient(any()),
        ).thenAnswer((_) => completer.future);

        final firstCall = engine.syncAll();
        final secondCall = engine.syncAll();

        completer.complete(buildResponse('success'));
        await Future.wait([firstCall, secondCall]);

        verify(() => patientRepo.syncPatient(any())).called(1);
      },
    );
  });

  // ── _syncOne ──────────────────────────────────────

  group('sincronización de un registro individual', () {
    test(
      'registro ya scrubbeado/corrupto (toPatientRecord == null) se salta',
      () async {
        final entry = buildEntry('A', record: null);
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);

        await engine.syncAll();

        verifyNever(() => patientRepo.syncPatient(any()));
        verifyNever(() => localDb.markSynced(any()));
        verifyNever(() => localDb.markSyncError(any(), any()));
      },
    );

    test(
      'respuesta con status "success" marca el registro como sincronizado',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);
        when(
          () => patientRepo.syncPatient(any()),
        ).thenAnswer((_) async => buildResponse('success'));

        String? syncedId;
        bool? syncedOk;
        engine.onRecordSynced = (id, ok, err) {
          syncedId = id;
          syncedOk = ok;
        };

        await engine.syncAll();

        verify(() => localDb.markSynced('A')).called(1);
        expect(syncedId, 'A');
        expect(syncedOk, true);
      },
    );

    test('respuesta con status distinto de "success" marca error', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => [entry]);
      when(() => patientRepo.syncPatient(any())).thenAnswer(
        (_) async => buildResponse('rejected', message: 'datos inválidos'),
      );

      String? recordedError;
      engine.onRecordSynced = (id, ok, err) => recordedError = err;

      await engine.syncAll();

      verify(
        () => localDb.markSyncError('A', 'Sync returned status: rejected'),
      ).called(1);
      expect(recordedError, 'datos inválidos');
    });

    test(
      'ApiException 401 marca error y detiene el flujo de ese registro',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(401, 'token expirado');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        bool? success;
        engine.onRecordSynced = (id, ok, err) => success = ok;

        await engine.syncAll();

        verify(() => localDb.markSyncError('A', 'token expirado')).called(1);
        expect(success, false);
      },
    );

    test('ApiException 400 marca error y no reintenta', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => [entry]);
      final exception = buildApiException(400, 'solicitud inválida');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      await engine.syncAll();

      verify(() => localDb.markSyncError('A', 'solicitud inválida')).called(1);
    });

    test('ApiException 422 marca error y no reintenta', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => [entry]);
      final exception = buildApiException(422, 'entidad no procesable');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      await engine.syncAll();

      verify(
        () => localDb.markSyncError('A', 'entidad no procesable'),
      ).called(1);
    });

    test(
      'ApiException 429 marca error y deja el registro para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(429, 'rate limited');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        await engine.syncAll();

        verify(() => localDb.markSyncError('A', 'rate limited')).called(1);
      },
    );

    test(
      'ApiException 500 marca error y deja el registro para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(500, 'error de servidor');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        await engine.syncAll();

        verify(() => localDb.markSyncError('A', 'error de servidor')).called(1);
      },
    );

    test(
      'excepción genérica (timeout/red) marca error y deja para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(),
        ).thenAnswer((_) async => [entry]);
        when(
          () => patientRepo.syncPatient(any()),
        ).thenThrow(Exception('timeout de red'));

        bool? success;
        engine.onRecordSynced = (id, ok, err) => success = ok;

        await engine.syncAll();

        verify(
          () =>
              localDb.markSyncError('A', any(that: contains('timeout de red'))),
        ).called(1);
        expect(success, false);
      },
    );
  });

  group('syncOne', () {
    test('retorna false si no hay ningún registro con ese patientId', () async {
      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => []);

      final result = await engine.syncOne('no-existe');

      expect(result, false);
      verifyNever(() => patientRepo.syncPatient(any()));
    });

    test(
      'retorna true cuando el registro se sincroniza correctamente',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());

        var callCount = 0;
        when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? [entry] : <LocalPatientEntry>[];
        });
        when(
          () => patientRepo.syncPatient(any()),
        ).thenAnswer((_) async => buildResponse('success'));

        final result = await engine.syncOne('A');

        expect(result, true);
        verify(() => localDb.markSynced('A')).called(1);
      },
    );

    test('retorna false cuando el registro sigue sin sincronizar', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());

      when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => [entry]);
      final exception = buildApiException(500, 'error de servidor');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      final result = await engine.syncOne('A');

      expect(result, false);
    });
  });

  // ── start / stop ──────────────────────────────────────────

  group('start / stop', () {
    late StreamController<List<ConnectivityResult>> connectivityController;
    late SyncEngine connectivityEngine;

    setUp(() {
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();
      connectivityEngine = SyncEngine(
        patientRepository: patientRepo,
        localDatabase: localDb,
        connectivityStream: connectivityController.stream,
      );
    });

    tearDown(() async {
      connectivityEngine.stop();
      await connectivityController.close();
    });

    test('start() intenta sincronizar inmediatamente', () async {
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => localDb.getUnsyncedRecords(),
      ).called(greaterThanOrEqualTo(1));
    });

    test('emitir un resultado con conexión dispara syncAll()', () async {
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);
      clearInteractions(localDb);

      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      verify(() => localDb.getUnsyncedRecords()).called(1);
    });

    test(
      'emitir solo ConnectivityResult.none no dispara syncAll() adicional',
      () async {
        connectivityEngine.start();
        await Future<void>.delayed(Duration.zero);
        clearInteractions(localDb);

        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => localDb.getUnsyncedRecords());
      },
    );

    test(
      'stop() cancela la suscripción y detiene futuras sincronizaciones',
      () async {
        connectivityEngine.start();
        await Future<void>.delayed(Duration.zero);

        connectivityEngine.stop();
        clearInteractions(localDb);

        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => localDb.getUnsyncedRecords());
      },
    );

    test('llamar start() dos veces cancela la suscripción anterior', () async {
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);

      clearInteractions(localDb);
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      verify(() => localDb.getUnsyncedRecords()).called(1);
    });
  });
}
