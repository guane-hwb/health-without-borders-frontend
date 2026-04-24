import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/nfc/domain/patient_record.dart';

/// Local SQLite database for offline-first patient storage.
///
/// Every patient save goes here first with `is_synced = 0`.
/// The [SyncEngine] picks up unsynced records and pushes them to the backend.
/// After a successful sync (HTTP 201), the record is marked `is_synced = 1`
/// and clinical detail is scrubbed per the security policy.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _dbName = 'hwb_patients.db';
  static const int _dbVersion = 1;
  static const String _table = 'local_patients';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String dbPath = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            patient_id    TEXT PRIMARY KEY,
            device_uid    TEXT NOT NULL,
            patient_name  TEXT NOT NULL,
            record_json   TEXT NOT NULL,
            is_synced     INTEGER NOT NULL DEFAULT 0,
            sync_error    TEXT,
            created_at    TEXT NOT NULL,
            synced_at     TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_synced ON $_table (is_synced)',
        );
      },
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Saves a patient record locally. If a record with the same patientId
  /// already exists, it is replaced (upsert).
  Future<void> savePatient(PatientFullRecord record) async {
    final db = await database;
    await db.insert(
      _table,
      {
        'patient_id': record.patientId,
        'device_uid': record.deviceUid,
        'patient_name': record.patientInfo.fullName,
        'record_json': jsonEncode(record.toJson()),
        'is_synced': 0,
        'sync_error': null,
        'created_at': DateTime.now().toIso8601String(),
        'synced_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Returns all records that have NOT been synced to the backend yet.
  Future<List<LocalPatientEntry>> getUnsyncedRecords() async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return rows.map(LocalPatientEntry.fromRow).toList();
  }

  /// Returns all records (synced and unsynced) for the brigade history screen.
  Future<List<LocalPatientEntry>> getAllRecords() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(LocalPatientEntry.fromRow).toList();
  }

  /// Returns the count of unsynced records (for badge display).
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Sync lifecycle ────────────────────────────────────────────────────────

  /// Marks a record as successfully synced and scrubs clinical detail.
  ///
  /// Per the integration guide section 10.2, after a successful 201 response
  /// the detailed clinical data is deleted from local storage. Only the
  /// patient name, ID, device_uid, and sync metadata are kept.
  Future<void> markSynced(String patientId) async {
    final db = await database;
    await db.update(
      _table,
      {
        'is_synced': 1,
        'sync_error': null,
        'synced_at': DateTime.now().toIso8601String(),
        // Scrub clinical detail — keep only identification metadata
        'record_json': '{}',
      },
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  /// Records a sync error for a patient (for UI display and retry logic).
  Future<void> markSyncError(String patientId, String error) async {
    final db = await database;
    await db.update(
      _table,
      {'sync_error': error},
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  /// Deletes a single local record (e.g., after review).
  Future<void> deleteRecord(String patientId) async {
    final db = await database;
    await db.delete(_table, where: 'patient_id = ?', whereArgs: [patientId]);
  }

  /// Deletes all local records.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }
}

// ── Data class for local records ────────────────────────────────────────────

class LocalPatientEntry {
  LocalPatientEntry({
    required this.patientId,
    required this.deviceUid,
    required this.patientName,
    required this.recordJson,
    required this.isSynced,
    this.syncError,
    required this.createdAt,
    this.syncedAt,
  });

  factory LocalPatientEntry.fromRow(Map<String, dynamic> row) {
    return LocalPatientEntry(
      patientId: row['patient_id'] as String,
      deviceUid: row['device_uid'] as String,
      patientName: row['patient_name'] as String,
      recordJson: row['record_json'] as String,
      isSynced: (row['is_synced'] as int) == 1,
      syncError: row['sync_error'] as String?,
      createdAt: row['created_at'] as String,
      syncedAt: row['synced_at'] as String?,
    );
  }

  final String patientId;
  final String deviceUid;
  final String patientName;
  final String recordJson;
  final bool isSynced;
  final String? syncError;
  final String createdAt;
  final String? syncedAt;

  /// Parses the stored JSON back into a PatientFullRecord.
  /// Returns null if the record was scrubbed after sync.
  PatientFullRecord? toPatientRecord() {
    if (recordJson.isEmpty || recordJson == '{}') return null;
    try {
      final Map<String, dynamic> json =
          jsonDecode(recordJson) as Map<String, dynamic>;
      return PatientFullRecord.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Masked name for the "Review Before Upload" screen.
  /// "Sofía García" → "Sofía G."
  String get maskedName {
    final parts = patientName.split(' ');
    if (parts.length <= 1) return patientName;
    return '${parts.first} ${parts[1][0]}.';
  }
}