// test/unit/local_database_test.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

PatientFullRecord _buildRecord({
  String patientId = 'p-100',
  String deviceUid = 'dev-100',
  String firstName = 'Ana',
  String lastName = 'García',
}) {
  return PatientFullRecord(
    patientId: patientId,
    deviceUid: deviceUid,
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '12345678',
      ),
      firstLastName: lastName,
      firstName: firstName,
      dob: '2015-03-10',
      biologicalSex: 'F',
      address: Address(city: 'Bogotá', state: 'DC'),
    ),
    guardianInfo: GuardianInfo(
      name: 'Guardian',
      relationship: '01',
      phone: '+50688887777',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorage mockStorage;
  final Map<String, String> inMemoryStorage = {};

  setUpAll(() async {
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final dbPath = p.join(await getDatabasesPath(), 'hwb_patients.db');
      if (await databaseExists(dbPath)) {
        await deleteDatabase(dbPath);
      }
    }
  });

  setUp(() {
    inMemoryStorage.clear();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer(
      (invocation) async =>
          inMemoryStorage[invocation.namedArguments[#key] as String],
    );
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      inMemoryStorage[invocation.namedArguments[#key] as String] =
          invocation.namedArguments[#value] as String;
    });
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((
      invocation,
    ) async {
      inMemoryStorage.remove(invocation.namedArguments[#key] as String);
    });

    LocalDatabase.setInstanceForTesting(
      LocalDatabase.forTesting(secureStorage: mockStorage),
    );
  });

  // ── LocalPatientEntry.fromRow ─────────────────────────────────────────────

  group('LocalPatientEntry.fromRow', () {
    Map<String, dynamic> baseRow({
      String patientId = 'p-001',
      String deviceUid = 'dev-001',
      String patientName = 'Ana García',
      String recordJson = '{"patientId":"p-001"}',
      int isSynced = 0,
      String? syncError,
      String createdAt = '2024-01-01T00:00:00.000Z',
      String? syncedAt,
    }) {
      return {
        'patient_id': patientId,
        'device_uid': deviceUid,
        'patient_name': patientName,
        'record_json': recordJson,
        'is_synced': isSynced,
        'sync_error': syncError,
        'created_at': createdAt,
        'synced_at': syncedAt,
      };
    }

    test('maps all fields correctly when isSynced = 0', () {
      final entry = LocalPatientEntry.fromRow(baseRow());
      expect(entry.patientId, equals('p-001'));
      expect(entry.deviceUid, equals('dev-001'));
      expect(entry.patientName, equals('Ana García'));
      expect(entry.isSynced, isFalse);
      expect(entry.syncError, isNull);
      expect(entry.syncedAt, isNull);
    });

    test('maps isSynced = 1 to true', () {
      final entry = LocalPatientEntry.fromRow(baseRow(isSynced: 1));
      expect(entry.isSynced, isTrue);
    });

    test('maps optional fields syncError and syncedAt when present', () {
      final entry = LocalPatientEntry.fromRow(
        baseRow(
          syncError: 'network error',
          syncedAt: '2024-06-01T12:00:00.000Z',
        ),
      );
      expect(entry.syncError, equals('network error'));
      expect(entry.syncedAt, equals('2024-06-01T12:00:00.000Z'));
    });
  });

  // ── LocalPatientEntry.toPatientRecord ─────────────────────────────────────

  group('LocalPatientEntry.toPatientRecord', () {
    test('returns null for empty recordJson', () {
      final entry = LocalPatientEntry(
        patientId: 'p-001',
        deviceUid: 'dev-001',
        patientName: 'Ana García',
        recordJson: '',
        isSynced: false,
        createdAt: '2024-01-01T00:00:00.000Z',
      );
      expect(entry.toPatientRecord(), isNull);
    });

    test('returns null for recordJson = {}', () {
      final entry = LocalPatientEntry(
        patientId: 'p-001',
        deviceUid: 'dev-001',
        patientName: 'Ana García',
        recordJson: '{}',
        isSynced: false,
        createdAt: '2024-01-01T00:00:00.000Z',
      );
      expect(entry.toPatientRecord(), isNull);
    });

    test('returns null for malformed JSON', () {
      final entry = LocalPatientEntry(
        patientId: 'p-001',
        deviceUid: 'dev-001',
        patientName: 'Ana García',
        recordJson: 'NOT_VALID_JSON{{{',
        isSynced: false,
        createdAt: '2024-01-01T00:00:00.000Z',
      );
      expect(entry.toPatientRecord(), isNull);
    });

    test('returns a PatientFullRecord for valid JSON', () {
      final validJson = '''{
        "patientId": "p-001",
        "device_uid": "dev-001",
        "patientInfo": {
          "identification": {
            "documentType": "DNI",
            "documentNumber": "12345678"
          },
          "firstLastName": "García",
          "firstName": "Ana",
          "dob": "2015-03-10",
          "biologicalSex": "F",
          "address": {
            "city": "Bogotá",
            "state": "DC"
          }
        },
        "guardianInfo": {
          "name": "Guardian",
          "relationship": "01",
          "phone": "+50688887777"
        }
      }''';
      final entry = LocalPatientEntry(
        patientId: 'p-001',
        deviceUid: 'dev-001',
        patientName: 'Ana García',
        recordJson: validJson,
        isSynced: false,
        createdAt: '2024-01-01T00:00:00.000Z',
      );
      expect(entry.toPatientRecord(), isNotNull);
    });
  });

  // ── LocalPatientEntry.maskedName ──────────────────────────────────────────

  group('LocalPatientEntry.maskedName', () {
    LocalPatientEntry entryWithName(String name) {
      return LocalPatientEntry(
        patientId: 'x',
        deviceUid: 'y',
        patientName: name,
        recordJson: '{}',
        isSynced: false,
        createdAt: '2024-01-01T00:00:00.000Z',
      );
    }

    test('masks the last name initial for a two-part name', () {
      expect(entryWithName('Ana García').maskedName, equals('Ana G.'));
    });

    test('masks only the first letter of the second part', () {
      expect(entryWithName('Juan Carlos Pérez').maskedName, equals('Juan C.'));
    });

    test('returns the original name when it has no spaces (single word)', () {
      expect(entryWithName('Mononym').maskedName, equals('Mononym'));
    });

    test('handles name with leading/trailing spaces gracefully', () {
      expect(() => entryWithName(' Ana García ').maskedName, returnsNormally);
    });
  });

  // ── NfcChipStatus ────────────────────────────────────────────────────────

  group('NfcChipStatus', () {
    test('clean() starts with both flags false', () {
      final status = NfcChipStatus.clean('p-1');
      expect(status.patientId, equals('p-1'));
      expect(status.patientChipDirty, isFalse);
      expect(status.guardianChipDirty, isFalse);
      expect(status.anyDirty, isFalse);
    });

    test('fromRow maps 1/0 integers to booleans', () {
      final status = NfcChipStatus.fromRow({
        'patient_id': 'p-1',
        'patient_chip_dirty': 1,
        'guardian_chip_dirty': 0,
      });
      expect(status.patientChipDirty, isTrue);
      expect(status.guardianChipDirty, isFalse);
    });

    test('fromRow defaults missing dirty flags to false', () {
      final status = NfcChipStatus.fromRow({'patient_id': 'p-1'});
      expect(status.patientChipDirty, isFalse);
      expect(status.guardianChipDirty, isFalse);
    });

    test('markDirty ORs new flags without clearing existing ones', () {
      final dirty = NfcChipStatus.clean(
        'p-1',
      ).markDirty(patient: true).markDirty(guardian: true).markDirty();
      expect(dirty.patientChipDirty, isTrue);
      expect(dirty.guardianChipDirty, isTrue);
      expect(dirty.anyDirty, isTrue);
    });

    test('clearDirty only clears the requested flags', () {
      const dirty = NfcChipStatus(
        patientId: 'p-1',
        patientChipDirty: true,
        guardianChipDirty: true,
      );
      final cleared = dirty.clearDirty(patient: true);
      expect(cleared.patientChipDirty, isFalse);
      expect(cleared.guardianChipDirty, isTrue);
      expect(cleared.anyDirty, isTrue);
    });

    test('toRow serializes booleans back to 1/0', () {
      final row = const NfcChipStatus(
        patientId: 'p-1',
        patientChipDirty: true,
        guardianChipDirty: false,
      ).toRow();
      expect(row['patient_id'], equals('p-1'));
      expect(row['patient_chip_dirty'], equals(1));
      expect(row['guardian_chip_dirty'], equals(0));
    });

    test('toRow -> fromRow round-trips correctly', () {
      const original = NfcChipStatus(
        patientId: 'p-9',
        patientChipDirty: true,
        guardianChipDirty: true,
      );
      final roundTripped = NfcChipStatus.fromRow(original.toRow());
      expect(roundTripped.patientChipDirty, equals(original.patientChipDirty));
      expect(
        roundTripped.guardianChipDirty,
        equals(original.guardianChipDirty),
      );
    });
  });

  // ── LocalDatabase.init() ──────────────────────────────────────────────────

  group('LocalDatabase.init()', () {
    test('completes without error (lazy init, no-op)', () async {
      await expectLater(LocalDatabase.init(), completes);
    });
  });

  // ── LocalDatabase — real sqlite-backed behaviour ──────────────────────────
  group('LocalDatabase (native/sqlite code path)', () {
    late LocalDatabase localDb;

    Future<Database> rawConnection() async {
      final dbPath = p.join(await getDatabasesPath(), 'hwb_patients.db');
      return openDatabase(dbPath);
    }

    setUp(() async {
      localDb = LocalDatabase.instance;
      await localDb.clearAll();
      final db = await rawConnection();
      await db.delete('emergency_access_log');
    });

    // ── Break-glass audit log ───────────────────────────────────────────────

    test('logEmergencyAccess persiste una entrada sin sincronizar', () async {
      await localDb.logEmergencyAccess(
        patientUid: '04:AA:BB',
        patientName: 'Ana Pérez',
        userId: 'user-1',
      );

      final pending = await localDb.pendingEmergencyAccessLogs();
      expect(pending, hasLength(1));
      expect(pending.single['patient_uid'], '04:AA:BB');
      expect(pending.single['patient_name'], 'Ana Pérez');
      expect(pending.single['user_id'], 'user-1');
      expect(pending.single['is_synced'], 0);
      expect(pending.single['reason'], 'guardian_absent_offline');
      expect(pending.single['occurred_at'], isNotEmpty);
    });

    test('acumula varias entradas', () async {
      await localDb.logEmergencyAccess(patientUid: '04:AA');
      await localDb.logEmergencyAccess(patientUid: '04:BB');
      expect(await localDb.pendingEmergencyAccessLogs(), hasLength(2));
    });

    test('tolera campos opcionales ausentes', () async {
      await localDb.logEmergencyAccess(patientUid: '04:CC');
      final pending = await localDb.pendingEmergencyAccessLogs();
      expect(pending.single['patient_name'], isNull);
      expect(pending.single['user_id'], isNull);
    });

    test(
      'getUnsyncedEmergencyLogCount cuenta solo entradas sin sincronizar',
      () async {
        await localDb.logEmergencyAccess(patientUid: '04:D1');
        await localDb.logEmergencyAccess(patientUid: '04:D2');
        expect(await localDb.getUnsyncedEmergencyLogCount(), equals(2));

        final pending = await localDb.pendingEmergencyAccessLogs();
        final firstId = pending.first['id'] as int;
        await localDb.markEmergencyLogsSynced([firstId]);

        expect(await localDb.getUnsyncedEmergencyLogCount(), equals(1));
      },
    );

    test('clearAll conserva accesos de emergencia pendientes pero borra los '
        'ya sincronizados', () async {
      await localDb.logEmergencyAccess(patientUid: '04:PEND');
      await localDb.logEmergencyAccess(patientUid: '04:DONE');

      final pending = await localDb.pendingEmergencyAccessLogs();
      final doneId =
          pending.firstWhere((r) => r['patient_uid'] == '04:DONE')['id'] as int;
      await localDb.markEmergencyLogsSynced([doneId]);

      await localDb.clearAll();

      final raw = await rawConnection();
      final allRows = await raw.query('emergency_access_log');
      expect(allRows, hasLength(1));
      expect(allRows.single['patient_uid'], '04:PEND');
      expect(await localDb.getUnsyncedEmergencyLogCount(), equals(1));
    });

    test(
      'savePatient persists a record retrievable via getAllRecords',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'p-200'));

        final all = await localDb.getAllRecords();
        expect(all, hasLength(1));
        expect(all.first.patientId, equals('p-200'));
        expect(all.first.deviceUid, equals('dev-100'));
        expect(all.first.patientName, equals('Ana G.'));
        expect(all.first.isSynced, isFalse);
        expect(all.first.syncError, isNull);
        expect(all.first.syncedAt, isNull);
      },
    );

    test(
      'savePatient overwrites an existing row for the same patientId',
      () async {
        await localDb.savePatient(
          _buildRecord(patientId: 'p-201', firstName: 'Ana'),
        );
        await localDb.savePatient(
          _buildRecord(patientId: 'p-201', firstName: 'Bea'),
        );

        final all = await localDb.getAllRecords();
        expect(all, hasLength(1));
        expect(all.first.patientName, equals('Bea G.'));
      },
    );

    test('getAllRecords orders rows by createdAt descending', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-first'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await localDb.savePatient(_buildRecord(patientId: 'p-second'));

      final all = await localDb.getAllRecords();
      expect(all.map((e) => e.patientId), equals(['p-second', 'p-first']));
    });

    test('getUnsyncedRecords excludes rows flagged as synced', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-a'));
      await localDb.savePatient(_buildRecord(patientId: 'p-b'));

      final raw = await rawConnection();
      await raw.update(
        'local_patients',
        {'is_synced': 1},
        where: 'patient_id = ?',
        whereArgs: ['p-a'],
      );

      final unsynced = await localDb.getUnsyncedRecords();
      expect(unsynced.map((e) => e.patientId), equals(['p-b']));
    });

    test('getUnsyncedRecords orders rows by createdAt ascending', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-old'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await localDb.savePatient(_buildRecord(patientId: 'p-new'));

      final unsynced = await localDb.getUnsyncedRecords();
      expect(unsynced.map((e) => e.patientId), equals(['p-old', 'p-new']));
    });

    test('getUnsyncedCount reflects only rows with is_synced = 0', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-c'));
      await localDb.savePatient(_buildRecord(patientId: 'p-d'));
      expect(await localDb.getUnsyncedCount(), equals(2));

      final raw = await rawConnection();
      await raw.update(
        'local_patients',
        {'is_synced': 1},
        where: 'patient_id = ?',
        whereArgs: ['p-c'],
      );
      expect(await localDb.getUnsyncedCount(), equals(1));
    });

    group('filtrado por owner_user_id', () {
      test(
        'getAllRecords(ownerUserId: B) NO devuelve los pacientes de A',
        () async {
          await localDb.savePatient(
            _buildRecord(patientId: 'p-a1'),
            ownerUserId: 'nurse-a',
          );
          await localDb.savePatient(
            _buildRecord(patientId: 'p-a2'),
            ownerUserId: 'nurse-a',
          );

          final forDoctorB = await localDb.getAllRecords(
            ownerUserId: 'doctor-b',
          );

          expect(forDoctorB, isEmpty);
        },
      );

      test(
        'getAllRecords(ownerUserId: A) SÍ devuelve los pacientes propios',
        () async {
          await localDb.savePatient(
            _buildRecord(patientId: 'p-a3'),
            ownerUserId: 'nurse-a',
          );

          final forNurseA = await localDb.getAllRecords(ownerUserId: 'nurse-a');

          expect(forNurseA.map((e) => e.patientId), equals(['p-a3']));
        },
      );

      test(
        'getUnsyncedCount(ownerUserId: B) es 0 aunque A tenga pendientes '
        '— esto es lo que evita el incidente de trazabilidad falseada',
        () async {
          await localDb.savePatient(
            _buildRecord(patientId: 'p-a4'),
            ownerUserId: 'nurse-a',
          );
          await localDb.savePatient(
            _buildRecord(patientId: 'p-a5'),
            ownerUserId: 'nurse-a',
          );

          expect(
            await localDb.getUnsyncedCount(ownerUserId: 'doctor-b'),
            equals(0),
          );
          expect(
            await localDb.getUnsyncedCount(ownerUserId: 'nurse-a'),
            equals(2),
          );
          expect(await localDb.getUnsyncedCount(), equals(2));
        },
      );

      test('registros legados sin owner_user_id (previos a la migración) '
          'siguen siendo visibles para cualquier usuario', () async {
        await localDb.savePatient(_buildRecord(patientId: 'p-legacy'));

        final forAnyUser = await localDb.getAllRecords(
          ownerUserId: 'cualquier-usuario',
        );

        expect(forAnyUser.map((e) => e.patientId), contains('p-legacy'));
      });
    });

    test('markSynced deletes the local record entirely', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-e'));
      await localDb.markSynced('p-e');

      expect(await localDb.getAllRecords(), isEmpty);
    });

    test(
      'markSynced con la revisión que sí se sincronizó borra el registro',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'p-rev1'));
        final saved = (await localDb.getAllRecords()).single;
        expect(saved.revision, equals(0));

        await localDb.markSynced('p-rev1', revision: saved.revision);

        expect(await localDb.getAllRecords(), isEmpty);
      },
    );

    test('markSynced NO borra una edición hecha durante el POST '
        '(la revisión ya avanzó)', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-rev2'));
      final original = (await localDb.getAllRecords()).single;
      expect(original.revision, equals(0));

      await localDb.savePatient(
        _buildRecord(patientId: 'p-rev2', firstName: 'Bea'),
      );

      await localDb.markSynced('p-rev2', revision: original.revision);

      final remaining = await localDb.getAllRecords();
      expect(
        remaining,
        hasLength(1),
        reason:
            'La edición hecha durante el POST no debe perderse: el '
            'registro sigue pendiente de sincronizar con su valor nuevo',
      );
      expect(
        remaining.single.revision,
        equals(1),
        reason: 'Debe seguir siendo la revisión nueva, no la confirmada',
      );
    });

    test(
      'markSynced sin revisión (compatibilidad) sigue borrando por patientId',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'p-rev3'));
        await localDb.markSynced('p-rev3');

        expect(await localDb.getAllRecords(), isEmpty);
      },
    );

    test('markSyncError stores the error message on the row', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-f'));
      await localDb.markSyncError('p-f', 'network error');

      final all = await localDb.getAllRecords();
      expect(all.single.syncError, equals('network error'));
    });

    test('markSyncError stores the HTTP status code on the row', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-f2'));
      await localDb.markSyncError('p-f2', 'conflict', statusCode: 409);

      final all = await localDb.getAllRecords();
      final row = all.singleWhere((e) => e.patientId == 'p-f2');
      expect(row.syncError, equals('conflict'));
      expect(row.syncErrorCode, equals(409));
    });

    test('deleteRecord removes the row regardless of sync status', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-g'));
      await localDb.deleteRecord('p-g');

      expect(await localDb.getAllRecords(), isEmpty);
    });

    test('clearAll removes every patient row', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-h'));
      await localDb.savePatient(_buildRecord(patientId: 'p-i'));
      await localDb.clearAll();

      expect(await localDb.getAllRecords(), isEmpty);
    });

    // ── Chip status ─────────────────────────────────────────────────────

    test('getChipStatus returns null for an empty patientId', () async {
      expect(await localDb.getChipStatus(''), isNull);
    });

    test('getChipStatus returns null when nothing is stale', () async {
      expect(await localDb.getChipStatus('unknown-patient'), isNull);
    });

    test('markChipsDirty is a no-op when patientId is empty', () async {
      await localDb.markChipsDirty('', patient: true);
      expect(await localDb.getChipStatus(''), isNull);
    });

    test('markChipsDirty is a no-op when no flag is requested', () async {
      await localDb.markChipsDirty('p-j');
      expect(await localDb.getChipStatus('p-j'), isNull);
    });

    test(
      'markChipsDirty creates a row with only the requested flag set',
      () async {
        await localDb.markChipsDirty('p-k', patient: true);

        final status = await localDb.getChipStatus('p-k');
        expect(status, isNotNull);
        expect(status!.patientChipDirty, isTrue);
        expect(status.guardianChipDirty, isFalse);
      },
    );

    test('markChipsDirty ORs onto existing dirty flags', () async {
      await localDb.markChipsDirty('p-l', patient: true);
      await localDb.markChipsDirty('p-l', guardian: true);

      final status = await localDb.getChipStatus('p-l');
      expect(status!.patientChipDirty, isTrue);
      expect(status.guardianChipDirty, isTrue);
    });

    test('clearChipsDirty is a no-op when patientId is empty', () async {
      await localDb.markChipsDirty('p-m', patient: true);
      await localDb.clearChipsDirty('', patient: true);

      expect(await localDb.getChipStatus('p-m'), isNotNull);
    });

    test(
      'clearChipsDirty is a no-op when there is no existing status',
      () async {
        await expectLater(
          localDb.clearChipsDirty('never-marked', patient: true),
          completes,
        );
        expect(await localDb.getChipStatus('never-marked'), isNull);
      },
    );

    test(
      'clearChipsDirty clears only the requested flag and keeps the row',
      () async {
        await localDb.markChipsDirty('p-n', patient: true, guardian: true);
        await localDb.clearChipsDirty('p-n', patient: true);

        final status = await localDb.getChipStatus('p-n');
        expect(status, isNotNull);
        expect(status!.patientChipDirty, isFalse);
        expect(status.guardianChipDirty, isTrue);
      },
    );

    test(
      'clearChipsDirty deletes the row once nothing is left dirty',
      () async {
        await localDb.markChipsDirty('p-o', patient: true, guardian: true);
        await localDb.clearChipsDirty('p-o', patient: true, guardian: true);

        expect(await localDb.getChipStatus('p-o'), isNull);
      },
    );

    test('clearAll also clears chip status rows', () async {
      await localDb.markChipsDirty('p-p', patient: true);
      await localDb.clearAll();

      expect(await localDb.getChipStatus('p-p'), isNull);
    });

    test(
      'purgeStalePermanentErrors borra sólo los errores permanentes anteriores al umbral',
      () async {
        final db = await rawConnection();
        final vieja = DateTime.now()
            .subtract(const Duration(days: 40))
            .toIso8601String();
        final reciente = DateTime.now()
            .subtract(const Duration(days: 29))
            .toIso8601String();

        Future<void> seed(String id, String createdAt, int code) async {
          await localDb.savePatient(_buildRecord(patientId: id));
          await db.update(
            'local_patients',
            {'created_at': createdAt, 'sync_error_code': code},
            where: 'patient_id = ?',
            whereArgs: [id],
          );
        }

        await seed('p-409-vieja', vieja, 409);
        await seed('p-422-vieja', vieja, 422);
        await seed('p-409-reciente', reciente, 409);
        await seed('p-500-vieja', vieja, 500);

        await localDb.purgeStalePermanentErrors();

        final ids = (await localDb.getAllRecords())
            .map((e) => e.patientId)
            .toSet();
        expect(ids, {'p-409-reciente', 'p-500-vieja'});
      },
    );

    test('purgeStalePermanentErrors respeta un maxAge explícito', () async {
      final db = await rawConnection();
      await localDb.savePatient(_buildRecord(patientId: 'p-409-10d'));
      await db.update(
        'local_patients',
        {
          'created_at': DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
          'sync_error_code': 409,
        },
        where: 'patient_id = ?',
        whereArgs: ['p-409-10d'],
      );

      await localDb.purgeStalePermanentErrors(maxAge: const Duration(days: 5));

      expect(await localDb.getAllRecords(), isEmpty);
    });
  });

  // ── LocalDatabase — (localStorage/sessionStorage Web path) ────────────────

  group('LocalDatabase (web code path)', () {
    late LocalDatabase localDb;
    late Map<String, String> webBackend;

    setUp(() {
      webBackend = {};
      localDb = LocalDatabase.forTesting(
        secureStorage: mockStorage,
        forceWeb: true,
        webGet: (key) => webBackend[key],
        webSet: (key, value) => webBackend[key] = value,
        webRemove: (key) => webBackend.remove(key),
      );
    });

    test(
      'savePatient guarda un registro recuperable por getAllRecords en Web',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'w-1'));

        final all = await localDb.getAllRecords();
        expect(all, hasLength(1));
        expect(all.first.patientId, equals('w-1'));
        expect(all.first.patientName, equals('Ana G.'));
        expect(all.first.isSynced, isFalse);
        expect(all.first.revision, equals(0));
      },
    );

    test(
      'savePatient persiste el registro cifrado en el backend Web inyectado',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'w-cipher'));

        expect(webBackend.containsKey('hwb_web_patients_store'), isTrue);
        expect(webBackend['hwb_web_patients_store'], isNot(contains('García')));
      },
    );

    test('savePatient incrementa la revisión en ediciones sucesivas', () async {
      await localDb.savePatient(
        _buildRecord(patientId: 'w-2', firstName: 'Ana'),
      );
      await localDb.savePatient(
        _buildRecord(patientId: 'w-2', firstName: 'Bea'),
      );

      final all = await localDb.getAllRecords();
      expect(all.single.revision, equals(1));
    });

    test('markSynced en Web respeta la guarda de revisión '
        '(v2-guarda-created-at-inutil, rama web)', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-3'));
      final original = (await localDb.getAllRecords()).single;

      await localDb.savePatient(
        _buildRecord(patientId: 'w-3', firstName: 'Bea'),
      );
      await localDb.markSynced('w-3', revision: original.revision);

      final remaining = await localDb.getAllRecords();
      expect(remaining, hasLength(1));
      expect(remaining.single.revision, equals(1));
    });

    test('markSynced en Web borra cuando la revisión coincide', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-4'));
      final saved = (await localDb.getAllRecords()).single;

      await localDb.markSynced('w-4', revision: saved.revision);

      expect(await localDb.getAllRecords(), isEmpty);
    });

    test('getUnsyncedRecords excluye filas ya sincronizadas en Web', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-5'));
      await localDb.savePatient(_buildRecord(patientId: 'w-6'));
      final saved = (await localDb.getAllRecords()).firstWhere(
        (e) => e.patientId == 'w-5',
      );

      await localDb.markSynced('w-5', revision: saved.revision);

      final unsynced = await localDb.getUnsyncedRecords();
      expect(unsynced.map((e) => e.patientId), equals(['w-6']));
    });

    test('getUnsyncedCount cuenta solo lo pendiente en Web', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-7'));
      await localDb.savePatient(_buildRecord(patientId: 'w-8'));
      expect(await localDb.getUnsyncedCount(), equals(2));

      final saved = (await localDb.getAllRecords()).firstWhere(
        (e) => e.patientId == 'w-7',
      );
      await localDb.markSynced('w-7', revision: saved.revision);

      expect(await localDb.getUnsyncedCount(), equals(1));
    });

    test('Web: getAllRecords(ownerUserId: B) NO devuelve los pacientes de A '
        'tras un cierre de pestaña sin logout', () async {
      await localDb.savePatient(
        _buildRecord(patientId: 'w-a1'),
        ownerUserId: 'nurse-a',
      );

      final forDoctorB = await localDb.getAllRecords(ownerUserId: 'doctor-b');

      expect(forDoctorB, isEmpty);
    });

    test(
      'Web: getUnsyncedCount(ownerUserId: B) es 0 aunque A tenga pendientes',
      () async {
        await localDb.savePatient(
          _buildRecord(patientId: 'w-a2'),
          ownerUserId: 'nurse-a',
        );
        await localDb.savePatient(
          _buildRecord(patientId: 'w-a3'),
          ownerUserId: 'nurse-a',
        );

        expect(
          await localDb.getUnsyncedCount(ownerUserId: 'doctor-b'),
          equals(0),
        );
        expect(
          await localDb.getUnsyncedCount(ownerUserId: 'nurse-a'),
          equals(2),
        );
      },
    );

    test(
      'purgeStalePermanentErrors solo retira registros con errores permanentes en Web',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'w-perm'));
        await localDb.markSyncError('w-perm', 'conflict', statusCode: 409);

        await localDb.savePatient(_buildRecord(patientId: 'w-temp'));
        await localDb.markSyncError('w-temp', 'timeout', statusCode: 503);

        await localDb.purgeStalePermanentErrors(maxAge: Duration.zero);

        final remaining = await localDb.getAllRecords();
        expect(remaining.map((e) => e.patientId), contains('w-temp'));
        expect(remaining.map((e) => e.patientId), isNot(contains('w-perm')));
      },
    );

    test('markSyncError guarda el código y mensaje en Web', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-9'));
      await localDb.markSyncError('w-9', 'conflict', statusCode: 409);

      final all = await localDb.getAllRecords();
      expect(all.single.syncError, equals('conflict'));
      expect(all.single.syncErrorCode, equals(409));
    });

    test('deleteRecord borra la fila en Web sin importar su estado', () async {
      await localDb.savePatient(_buildRecord(patientId: 'w-10'));
      await localDb.deleteRecord('w-10');

      expect(await localDb.getAllRecords(), isEmpty);
    });

    test(
      'clearAll borra todos los registros y el chip status en Web',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'w-11'));
        await localDb.markChipsDirty('w-11', patient: true);

        await localDb.clearAll();

        expect(await localDb.getAllRecords(), isEmpty);
        expect(await localDb.getChipStatus('w-11'), isNull);
      },
    );

    test(
      'markChipsDirty / clearChipsDirty funcionan sobre el backend Web',
      () async {
        await localDb.markChipsDirty('w-12', patient: true, guardian: true);
        var status = await localDb.getChipStatus('w-12');
        expect(status!.patientChipDirty, isTrue);
        expect(status.guardianChipDirty, isTrue);

        await localDb.clearChipsDirty('w-12', patient: true);
        status = await localDb.getChipStatus('w-12');
        expect(status!.patientChipDirty, isFalse);
        expect(status.guardianChipDirty, isTrue);
      },
    );

    test(
      'logEmergencyAccess / pendingEmergencyAccessLogs funcionan en Web',
      () async {
        await localDb.logEmergencyAccess(
          patientUid: '04:WEB',
          patientName: 'Ana Pérez',
          userId: 'user-1',
        );

        final pending = await localDb.pendingEmergencyAccessLogs();
        expect(pending, hasLength(1));
        expect(pending.single['patient_uid'], '04:WEB');
        expect(pending.single['patient_name'], 'Ana Pérez');
        expect(pending.single['is_synced'], 0);
      },
    );

    test(
      'getUnsyncedEmergencyLogCount cuenta solo entradas sin sincronizar en Web',
      () async {
        await localDb.logEmergencyAccess(patientUid: '04:W-D1');
        await localDb.logEmergencyAccess(patientUid: '04:W-D2');
        expect(await localDb.getUnsyncedEmergencyLogCount(), equals(2));

        final pending = await localDb.pendingEmergencyAccessLogs();
        final firstId = pending.first['id'];
        await localDb.markEmergencyLogsSynced([firstId as int]);

        expect(await localDb.getUnsyncedEmergencyLogCount(), equals(1));
      },
    );

    test('clearAll en Web conserva accesos de emergencia pendientes pero '
        'borra los ya sincronizados', () async {
      await localDb.logEmergencyAccess(patientUid: '04:W-PEND');
      await localDb.logEmergencyAccess(patientUid: '04:W-DONE');

      final pending = await localDb.pendingEmergencyAccessLogs();
      final doneId = pending.firstWhere(
        (r) => r['patient_uid'] == '04:W-DONE',
      )['id'];
      await localDb.markEmergencyLogsSynced([doneId as int]);

      await localDb.clearAll();

      final remaining = await localDb.pendingEmergencyAccessLogs();
      expect(remaining, hasLength(1));
      expect(remaining.single['patient_uid'], '04:W-PEND');
      expect(await localDb.getUnsyncedEmergencyLogCount(), equals(1));
    });

    test(
      'un backend Web corrupto/vacío no revienta: se trata como sin datos',
      () async {
        webBackend['hwb_web_patients_store'] = 'NOT_VALID_JSON{{{';

        expect(await localDb.getAllRecords(), isEmpty);
        expect(await localDb.getUnsyncedCount(), equals(0));
      },
    );
  });
}
