// test/unit/local_database_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';

void main() {
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

  // ── LocalDatabase.init() ──────────────────────────────────────────────────

  group('LocalDatabase.init()', () {
    test('completes without error (lazy init, no-op)', () async {
      await expectLater(LocalDatabase.init(), completes);
    });
  });
}
