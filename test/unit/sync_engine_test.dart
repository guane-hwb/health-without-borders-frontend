// test/unit/sync_engine_test.dart

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
    registerFallbackValue(const Duration(days: 30));
  });

  late MockPatientRepository patientRepo;
  late MockLocalDatabase localDb;
  late SyncEngine engine;

  // Helpers ------------------------------------------------------------

  MockLocalPatientEntry buildEntry(
    String id, {
    PatientFullRecord? record,
    String? createdAt,
    String? recordJson,
    int? syncErrorCode,
    int revision = 0,
  }) {
    final entry = MockLocalPatientEntry();
    final jsonStr = recordJson ?? '{"patientId": "$id"}';
    when(() => entry.patientId).thenReturn(id);
    when(
      () => entry.createdAt,
    ).thenReturn(createdAt ?? '2026-07-24T10:00:00.000Z');
    when(() => entry.recordJson).thenReturn(jsonStr);
    when(() => entry.toPatientRecord()).thenReturn(record);
    when(() => entry.syncErrorCode).thenReturn(syncErrorCode);
    when(() => entry.revision).thenReturn(revision);
    return entry;
  }

  MockPatientSyncResponse buildResponse(
    String status, {
    String? message,
    String? fhirStatus = 'success',
  }) {
    final response = MockPatientSyncResponse();
    when(() => response.status).thenReturn(status);
    when(() => response.message).thenReturn(message ?? '');
    when(() => response.fhirStatus).thenReturn(fhirStatus);
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

    when(
      () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => 0);
    when(
      () => localDb.getRetryablePendingCount(
        ownerUserId: any(named: 'ownerUserId'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      () => localDb.getBlockedCount(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => 0);
    when(
      () => localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => []);
    when(
      () => localDb.purgeStalePermanentErrors(maxAge: any(named: 'maxAge')),
    ).thenAnswer((_) async {});
    when(
      () => localDb.markSynced(
        any(),
        createdAt: any(named: 'createdAt'),
        recordJson: any(named: 'recordJson'),
        revision: any(named: 'revision'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => localDb.markSyncError(
        any(),
        any(),
        statusCode: any(named: 'statusCode'),
        revision: any(named: 'revision'),
      ),
    ).thenAnswer((_) async {});

    engine = SyncEngine(patientRepository: patientRepo, localDatabase: localDb);
  });

  tearDown(() {
    engine.stop();
  });

  // ── refreshPendingCount ────────────────────────────────────────────────

  group('refreshPendingCount', () {
    test('actualiza pendingCount con el valor de la base local', () async {
      when(
        () => localDb.getRetryablePendingCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 7);

      await engine.refreshPendingCount();

      expect(engine.pendingCount.value, 7);
    });

    test('mantiene el valor previo si la base local lanza un error', () async {
      when(
        () => localDb.getRetryablePendingCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 3);
      await engine.refreshPendingCount();
      expect(engine.pendingCount.value, 3);

      when(
        () => localDb.getRetryablePendingCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenThrow(Exception('storage down'));
      await engine.refreshPendingCount();

      expect(engine.pendingCount.value, 3);
    });
  });

  // ── syncAll ──────────────────────────────────────────────────────────────

  group('syncAll', () {
    test('sin registros pendientes no llama al repositorio', () async {
      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);
      when(
        () => localDb.getRetryablePendingCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 0);

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
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entryA, entryB]);
      when(
        () => patientRepo.syncPatient(any()),
      ).thenAnswer((_) async => buildResponse('success'));
      when(
        () => localDb.getRetryablePendingCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 0);

      await engine.syncAll();

      verify(() => patientRepo.syncPatient(any())).called(2);
      expect(engine.pendingCount.value, 0);
    });

    test('omite registros con errores permanentes (400, 409, 422)', () async {
      final entryOk = buildEntry('OK', record: MockPatientFullRecord());
      final entry409 = buildEntry(
        'CONFLICT',
        record: MockPatientFullRecord(),
        syncErrorCode: 409,
      );
      final entry422 = buildEntry(
        'INVALID',
        record: MockPatientFullRecord(),
        syncErrorCode: 422,
      );

      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entryOk, entry409, entry422]);
      when(
        () => patientRepo.syncPatient(any()),
      ).thenAnswer((_) async => buildResponse('success'));

      await engine.syncAll();

      verify(() => patientRepo.syncPatient(any())).called(1);
    });

    test('no invoca purgeStalePermanentErrors bajo ninguna circunstancia '
        '(v2-purga-silenciosa-30-dias)', () async {
      final entryOk = buildEntry('OK', record: MockPatientFullRecord());
      final entry409 = buildEntry(
        'CONFLICT',
        record: MockPatientFullRecord(),
        syncErrorCode: 409,
      );

      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entryOk, entry409]);
      when(
        () => patientRepo.syncPatient(any()),
      ).thenAnswer((_) async => buildResponse('success'));

      await engine.syncAll();

      verifyNever(
        () => localDb.purgeStalePermanentErrors(maxAge: any(named: 'maxAge')),
      );
    });

    test(
      'llamadas concurrentes se serializan (segunda no reprocesa)',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
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
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);

        await engine.syncAll();

        verifyNever(() => patientRepo.syncPatient(any()));
        verify(
          () => localDb.markSyncError(
            'A',
            'Registro local ilegible (fallo de descifrado)',
            statusCode: 422,
            revision: 0,
          ),
        ).called(1);
      },
    );

    test(
      'respuesta con status "success" marca el registro como sincronizado',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
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

        expect(syncedId, 'A');
        expect(syncedOk, true);
      },
    );

    test('respuesta con status distinto de "success" marca error', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entry]);
      when(() => patientRepo.syncPatient(any())).thenAnswer(
        (_) async => buildResponse('rejected', message: 'datos inválidos'),
      );

      String? recordedError;
      engine.onRecordSynced = (id, ok, err) => recordedError = err;

      await engine.syncAll();

      verify(
        () => localDb.markSyncError(
          'A',
          'Sync returned status: rejected',
          statusCode: null,
          revision: 0,
        ),
      ).called(1);
      expect(recordedError, 'datos inválidos');
    });

    test(
      'FHIR falla pero el status raiz es success: no borra la copia local',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        when(() => patientRepo.syncPatient(any())).thenAnswer(
          (_) async => buildResponse('success', fhirStatus: 'error'),
        );

        String? recordedError;
        engine.onRecordSynced = (id, ok, err) => recordedError = err;

        await engine.syncAll();

        verifyNever(
          () => localDb.markSynced(
            any(),
            createdAt: any(named: 'createdAt'),
            recordJson: any(named: 'recordJson'),
            revision: any(named: 'revision'),
          ),
        );
        verify(
          () => localDb.markSyncError(
            'A',
            'Envío FHIR fallido: error',
            statusCode: null,
            revision: 0,
          ),
        ).called(1);
        expect(recordedError, '');
      },
    );

    test(
      'ApiException 401 marca error y detiene el flujo de ese registro',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(401, 'token expirado');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        bool? success;
        engine.onRecordSynced = (id, ok, err) => success = ok;

        await engine.syncAll();

        verifyNever(
          () => localDb.markSyncError(
            any(),
            any(),
            statusCode: any(named: 'statusCode'),
            revision: any(named: 'revision'),
          ),
        );
        expect(success, false);
      },
    );

    test('ApiException 400 marca error y no reintenta', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entry]);
      final exception = buildApiException(400, 'solicitud inválida');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      await engine.syncAll();

      verify(
        () => localDb.markSyncError(
          'A',
          'solicitud inválida',
          statusCode: 400,
          revision: 0,
        ),
      ).called(1);
    });

    test(
      'ApiException 409 marca conflicto de manilla y no reintenta',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(
          409,
          'A patient is already registered with this device tag.',
        );
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        await engine.syncAll();

        verify(
          () => localDb.markSyncError(
            'A',
            'A patient is already registered with this device tag.',
            statusCode: 409,
            revision: 0,
          ),
        ).called(1);
      },
    );

    test('ApiException 422 marca error y no reintenta', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());
      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entry]);
      final exception = buildApiException(422, 'entidad no procesable');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      await engine.syncAll();

      verify(
        () => localDb.markSyncError(
          'A',
          'Error de validación (422): Campos incompatibles con el backend',
          statusCode: 422,
          revision: 0,
        ),
      ).called(1);
    });

    test(
      'ApiException 429 marca error y deja el registro para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(429, 'rate limited');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        await engine.syncAll();

        verify(
          () => localDb.markSyncError(
            'A',
            'rate limited',
            statusCode: 429,
            revision: 0,
          ),
        ).called(1);
      },
    );

    test(
      'ApiException 500 marca error y deja el registro para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        final exception = buildApiException(500, 'error de servidor');
        when(() => patientRepo.syncPatient(any())).thenThrow(exception);

        await engine.syncAll();

        verify(
          () => localDb.markSyncError(
            'A',
            'error de servidor',
            statusCode: 500,
            revision: 0,
          ),
        ).called(1);
      },
    );

    test(
      'excepción genérica (timeout/red) marca error y deja para reintento',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => [entry]);
        when(
          () => patientRepo.syncPatient(any()),
        ).thenThrow(TimeoutException('timeout de red'));

        bool? success;
        engine.onRecordSynced = (id, ok, err) => success = ok;

        await engine.syncAll();

        verify(
          () => localDb.markSyncError(
            'A',
            'Error de conexión de red',
            statusCode: null,
            revision: 0,
          ),
        ).called(1);
        expect(success, false);
      },
    );
  });

  group('syncOne', () {
    test(
      'retorna notFound si no hay ningún registro con ese patientId',
      () async {
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => []);

        final result = await engine.syncOne('no-existe');

        expect(result, SyncOneResult.notFound);
        verifyNever(() => patientRepo.syncPatient(any()));
      },
    );

    test(
      'retorna success cuando el registro se sincroniza correctamente',
      () async {
        final entry = buildEntry('A', record: MockPatientFullRecord());

        var callCount = 0;
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? [entry] : <LocalPatientEntry>[];
        });
        when(
          () => patientRepo.syncPatient(any()),
        ).thenAnswer((_) async => buildResponse('success'));

        final result = await engine.syncOne('A');

        expect(result, SyncOneResult.success);
        verify(
          () => localDb.markSynced(
            'A',
            createdAt: any(named: 'createdAt'),
            recordJson: any(named: 'recordJson'),
            revision: any(named: 'revision'),
          ),
        ).called(1);
      },
    );

    test('retorna failure cuando el registro sigue sin sincronizar', () async {
      final entry = buildEntry('A', record: MockPatientFullRecord());

      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => [entry]);
      final exception = buildApiException(500, 'error de servidor');
      when(() => patientRepo.syncPatient(any())).thenThrow(exception);

      final result = await engine.syncOne('A');

      expect(result, SyncOneResult.failure);
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
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).called(greaterThanOrEqualTo(1));
    });

    test('emitir un resultado con conexión dispara syncAll()', () async {
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);
      clearInteractions(localDb);

      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(seconds: 4));

      verify(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).called(1);
    });

    test(
      'emitir solo ConnectivityResult.none no dispara syncAll() adicional',
      () async {
        connectivityEngine.start();
        await Future<void>.delayed(Duration.zero);
        clearInteractions(localDb);

        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(seconds: 4));

        verifyNever(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        );
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
        await Future<void>.delayed(const Duration(seconds: 4));

        verifyNever(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        );
      },
    );

    test('llamar start() dos veces cancela la suscripción anterior', () async {
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);
      connectivityEngine.start();
      await Future<void>.delayed(Duration.zero);

      clearInteractions(localDb);
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(seconds: 4));

      verify(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).called(1);
    });
  });
}
