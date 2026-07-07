// test/unit/local_database_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

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
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = p.join(await getDatabasesPath(), 'hwb_patients.db');
    if (await databaseExists(dbPath)) {
      await deleteDatabase(dbPath);
    }
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
    final localDb = LocalDatabase.instance;

    Future<Database> rawConnection() async {
      final dbPath = p.join(await getDatabasesPath(), 'hwb_patients.db');
      return openDatabase(dbPath);
    }

    setUp(() async {
      await localDb.clearAll();
    });

    test(
      'savePatient persists a record retrievable via getAllRecords',
      () async {
        await localDb.savePatient(_buildRecord(patientId: 'p-200'));

        final all = await localDb.getAllRecords();
        expect(all, hasLength(1));
        expect(all.first.patientId, equals('p-200'));
        expect(all.first.deviceUid, equals('dev-100'));
        expect(all.first.patientName, equals('Ana García'));
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
        expect(all.first.patientName, equals('Bea García'));
      },
    );

    test('getAllRecords orders rows by createdAt descending', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-first'));
      await Future.delayed(const Duration(milliseconds: 5));
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
      await Future.delayed(const Duration(milliseconds: 5));
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

    test('markSynced deletes the local record entirely', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-e'));
      await localDb.markSynced('p-e');

      expect(await localDb.getAllRecords(), isEmpty);
    });

    test('markSyncError stores the error message on the row', () async {
      await localDb.savePatient(_buildRecord(patientId: 'p-f'));
      await localDb.markSyncError('p-f', 'network error');

      final all = await localDb.getAllRecords();
      expect(all.single.syncError, equals('network error'));
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
  });
}
