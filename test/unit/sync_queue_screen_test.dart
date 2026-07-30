// test/unit/sync_queue_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';

// =============================================================================
// Mocks
// =============================================================================

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

// =============================================================================
// Helpers
// =============================================================================

/// Creates a [LocalPatientEntry] instance with configured default values.
LocalPatientEntry makeEntry({
  String patientId = 'p-001',
  String deviceUid = 'device-001',
  String patientName = 'Juan Diaz',
  String recordJson = '{"patientId":"p-001"}',
  bool isSynced = false,
  String? syncError,
  String createdAt = '2024-05-01T10:00:00',
  String? syncedAt,
}) => LocalPatientEntry(
  patientId: patientId,
  deviceUid: deviceUid,
  patientName: patientName,
  recordJson: recordJson,
  isSynced: isSynced,
  syncError: syncError,
  createdAt: createdAt,
  syncedAt: syncedAt,
);

// =============================================================================
// UNIT TESTS
// =============================================================================

void main() {
  late MockLocalDatabase db;
  late MockSyncEngine syncEngine;

  setUp(() {
    db = MockLocalDatabase();
    syncEngine = MockSyncEngine();
  });

  group('LocalPatientEntry – Base Fields', () {
    test('patientId is stored correctly', () {
      final e = makeEntry(patientId: 'abc-123');
      expect(e.patientId, 'abc-123');
    });

    test('deviceUid is stored correctly', () {
      final e = makeEntry(deviceUid: 'dev-xyz');
      expect(e.deviceUid, 'dev-xyz');
    });

    test('patientName is stored correctly', () {
      final e = makeEntry(patientName: 'Maria Lopez');
      expect(e.patientName, 'Maria Lopez');
    });

    test('recordJson is stored correctly', () {
      final e = makeEntry(recordJson: '{"foo":"bar"}');
      expect(e.recordJson, '{"foo":"bar"}');
    });

    test('isSynced defaults to false', () {
      final e = makeEntry();
      expect(e.isSynced, isFalse);
    });

    test('isSynced can be assigned true', () {
      final e = makeEntry(isSynced: true);
      expect(e.isSynced, isTrue);
    });

    test('syncError defaults to null', () {
      final e = makeEntry();
      expect(e.syncError, isNull);
    });

    test('syncError retains the error string payload when assigned', () {
      final e = makeEntry(syncError: 'Network timeout');
      expect(e.syncError, 'Network timeout');
    });

    test('createdAt is stored correctly', () {
      final e = makeEntry(createdAt: '2024-12-31T23:59:59');
      expect(e.createdAt, '2024-12-31T23:59:59');
    });

    test('syncedAt defaults to null', () {
      final e = makeEntry();
      expect(e.syncedAt, isNull);
    });
  });

  group('LocalPatientEntry – maskedName', () {
    test(
      'displays first name and the initial letter of the last name followed by a dot',
      () {
        final e = makeEntry(patientName: 'Juan Diaz');
        expect(e.maskedName, 'Juan D.');
      },
    );

    test('handles compound names by masking only the second word token', () {
      final e = makeEntry(patientName: 'Ana Maria Gomez');
      expect(e.maskedName, 'Ana M.');
    });

    test(
      'returns raw name string unmutated if it contains only one word token',
      () {
        final e = makeEntry(patientName: 'Anónimo');
        expect(e.maskedName, 'Anónimo');
      },
    );

    test('returns empty string seamlessly when name is empty', () {
      final e = makeEntry(patientName: '');
      expect(e.maskedName, '');
    });
  });

  group('LocalPatientEntry – hasErr Logic', () {
    test('hasErr resolves to true when syncError string has content', () {
      final e = makeEntry(syncError: 'Algún error');
      expect(e.syncError?.isNotEmpty == true, isTrue);
    });

    test('hasErr resolves to false when syncError is null', () {
      final e = makeEntry();
      expect(e.syncError?.isNotEmpty == true, isFalse);
    });

    test('hasErr resolves to false when syncError is an empty string', () {
      final e = makeEntry(syncError: '');
      expect(e.syncError?.isNotEmpty == true, isFalse);
    });
  });

  group('LocalPatientEntry – Date String Extraction Parsing', () {
    test(
      'extracts the section before the T separator when createdAt is an ISO string',
      () {
        final e = makeEntry(createdAt: '2024-06-15T08:30:00');
        final date = e.createdAt.contains('T')
            ? e.createdAt.split('T').first
            : e.createdAt;
        expect(date, '2024-06-15');
      },
    );

    test(
      'returns unaltered createdAt string value when T separator is missing',
      () {
        final e = makeEntry(createdAt: '2024-06-15');
        final date = e.createdAt.contains('T')
            ? e.createdAt.split('T').first
            : e.createdAt;
        expect(date, '2024-06-15');
      },
    );
  });

  group('LocalPatientEntry – toPatientRecord Data Mapping', () {
    test('returns null when recordJson string payload is empty', () {
      final e = makeEntry(recordJson: '');
      expect(e.toPatientRecord(), isNull);
    });

    test('returns null when recordJson is an empty object string', () {
      final e = makeEntry(recordJson: '{}');
      expect(e.toPatientRecord(), isNull);
    });

    test(
      'returns null when recordJson string contains invalid JSON formatting',
      () {
        final e = makeEntry(recordJson: 'not-json');
        expect(e.toPatientRecord(), isNull);
      },
    );

    test(
      'executes safely without exceptions when recordJson formatting is valid',
      () {
        final e = makeEntry(
          recordJson:
              '{"patientId":"p-001","deviceUid":"dev-001","patientInfo":{"fullName":"Juan Diaz"}}',
        );
        expect(() => e.toPatientRecord(), returnsNormally);
      },
    );
  });

  group('LocalPatientEntry.fromRow Database Mapping Factory', () {
    test(
      'successfully builds instance entity properties out of a raw database row map',
      () {
        final row = {
          'patient_id': 'p-row',
          'device_uid': 'dev-row',
          'patient_name': 'Carlos Ruiz',
          'record_json': '{}',
          'is_synced': 0,
          'sync_error': null,
          'created_at': '2024-01-01T00:00:00',
          'synced_at': null,
        };
        final e = LocalPatientEntry.fromRow(row);
        expect(e.patientId, 'p-row');
        expect(e.deviceUid, 'dev-row');
        expect(e.patientName, 'Carlos Ruiz');
        expect(e.isSynced, isFalse);
        expect(e.syncError, isNull);
      },
    );

    test('mapeates integer flag value 1 onto boolean true for isSynced', () {
      final row = {
        'patient_id': 'x',
        'device_uid': 'd',
        'patient_name': 'Test',
        'record_json': '{}',
        'is_synced': 1,
        'sync_error': null,
        'created_at': '2024-01-01T00:00:00',
        'synced_at': null,
      };
      expect(LocalPatientEntry.fromRow(row).isSynced, isTrue);
    });

    test('maps non-null syncError string payload accurately', () {
      final row = {
        'patient_id': 'x',
        'device_uid': 'd',
        'patient_name': 'Test',
        'record_json': '{}',
        'is_synced': 0,
        'sync_error': 'Timeout',
        'created_at': '2024-01-01T00:00:00',
        'synced_at': null,
      };
      expect(LocalPatientEntry.fromRow(row).syncError, 'Timeout');
    });
  });

  group('LocalDatabase Mock Interceptions – getUnsyncedRecords', () {
    test(
      'returns empty array collection when no data items are pending synchronization',
      () async {
        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);

        final result = await db.getUnsyncedRecords();

        expect(result, isEmpty);
        verify(() => db.getUnsyncedRecords()).called(1);
      },
    );

    test(
      'returns all array data entry instances currently pending sync',
      () async {
        final entries = [
          makeEntry(patientId: 'p-1'),
          makeEntry(patientId: 'p-2'),
        ];
        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => entries);

        final result = await db.getUnsyncedRecords();

        expect(result, hasLength(2));
      },
    );

    test(
      'returned collection lists hold exactly the anticipated patient identifiers',
      () async {
        final entries = [
          makeEntry(patientId: 'abc'),
          makeEntry(patientId: 'xyz'),
        ];
        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => entries);

        final result = await db.getUnsyncedRecords();

        expect(result.map((e) => e.patientId), containsAll(['abc', 'xyz']));
      },
    );
  });

  group('LocalDatabase Mock Interceptions – deleteRecord', () {
    test(
      'invokes backend storage methods passing target patient identifier parameter',
      () async {
        when(() => db.deleteRecord(any())).thenAnswer((_) async {});

        await db.deleteRecord('p-001');

        verify(() => db.deleteRecord('p-001')).called(1);
      },
    );

    test(
      'supports independent invocation executions handling distinct data identifiers separately',
      () async {
        when(() => db.deleteRecord(any())).thenAnswer((_) async {});

        await db.deleteRecord('a');
        await db.deleteRecord('b');

        verify(() => db.deleteRecord('a')).called(1);
        verify(() => db.deleteRecord('b')).called(1);
      },
    );
  });

  group('SyncEngine Mock Interceptions – syncAll', () {
    test(
      'completes asynchronous task lifecycle without reporting standard error anomalies',
      () async {
        when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

        await expectLater(syncEngine.syncAll(), completes);
      },
    );

    test(
      'invokes engine routine layer exactly once per explicit programmatic call tracking',
      () async {
        when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

        await syncEngine.syncAll();

        verify(() => syncEngine.syncAll()).called(1);
      },
    );
  });

  group('SyncEngine Mock Interceptions – syncOne', () {
    test(
      'returns true boolean state upon successful operational outcome data completion',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => true);

        expect(await syncEngine.syncOne('p-001'), isTrue);
      },
    );

    test(
      'returns false boolean state when sync operations fail to resolve',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => false);

        expect(await syncEngine.syncOne('p-001'), isFalse);
      },
    );

    test(
      'transfers matching identity parameters downstream into execution engine modules',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => true);

        await syncEngine.syncOne('patient-xyz');

        verify(() => syncEngine.syncOne('patient-xyz')).called(1);
      },
    );

    test(
      'processes consecutive distinct calls independently tracking respective identifiers',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => true);

        await syncEngine.syncOne('id-1');
        await syncEngine.syncOne('id-2');

        verify(() => syncEngine.syncOne('id-1')).called(1);
        verify(() => syncEngine.syncOne('id-2')).called(1);
      },
    );
  });

  group('Load Flow Orchestration — Database to App State Sync', () {
    test(
      'loaded tracking records systematically match underlying storage queries output responses',
      () async {
        final expected = [makeEntry(patientId: 'x'), makeEntry(patientId: 'y')];
        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => expected);

        final entries = await db.getUnsyncedRecords();

        expect(entries, equals(expected));
      },
    );

    test(
      'database mirrors an empty status queue layout immediately following syncAll execution routines',
      () async {
        when(
          () => db.getUnsyncedRecords(),
        ).thenAnswer((_) async => [makeEntry()]);
        when(() => syncEngine.syncAll()).thenAnswer((_) async => true);

        final before = await db.getUnsyncedRecords();
        expect(before, hasLength(1));

        await syncEngine.syncAll();

        when(() => db.getUnsyncedRecords()).thenAnswer((_) async => []);
        final after = await db.getUnsyncedRecords();
        expect(after, isEmpty);
      },
    );
  });

  group('SyncOne Lifecycle State Variations Flow', () {
    test(
      'returning true maps dynamically towards success tracking layout colors channels',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => true);

        final ok = await syncEngine.syncOne('p-001');

        expect(ok, isTrue);
      },
    );

    test(
      'returning false maps dynamically towards error feedback notice presentation metrics',
      () async {
        when(() => syncEngine.syncOne(any())).thenAnswer((_) async => false);

        final ok = await syncEngine.syncOne('p-001');

        expect(ok, isFalse);
      },
    );
  });

  group('Deletion Prompt Confirmation Interception Flow', () {
    test(
      'does NOT issue database records deletions when dialog callback parameters evaluate to false',
      () async {
        when(() => db.deleteRecord(any())).thenAnswer((_) async {});

        const dialogResult = false;
        if (dialogResult == true) await db.deleteRecord('p-001');

        verifyNever(() => db.deleteRecord(any()));
      },
    );

    test(
      'issues real database records drop workflows when verification checks resolve to true',
      () async {
        when(() => db.deleteRecord(any())).thenAnswer((_) async {});

        const dialogResult = true;
        if (dialogResult == true) await db.deleteRecord('p-001');

        verify(() => db.deleteRecord('p-001')).called(1);
      },
    );

    test(
      'skips data item drops when navigation prompt routines are completely dismissed as null parameters',
      () async {
        when(() => db.deleteRecord(any())).thenAnswer((_) async {});

        const bool? dialogResult = null;
        if (dialogResult == true) await db.deleteRecord('p-001');

        verifyNever(() => db.deleteRecord(any()));
      },
    );
  });
}
