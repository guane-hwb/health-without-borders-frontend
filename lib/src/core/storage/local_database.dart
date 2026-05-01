import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/nfc/domain/patient_record.dart';

/// Local SQLite database for offline-first patient storage.
///
/// On mobile (iOS/Android): uses native sqflite.
/// On Flutter Web: sqflite is not supported. We use an in-memory fallback
/// so the app runs in Chrome for testing without crashing.
/// For production web persistence you would add sqflite_common_ffi_web.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _dbName = 'hwb_patients.db';
  static const int _dbVersion = 1;
  static const String _table = 'local_patients';

  Database? _db;

  // In-memory fallback for web (rows keyed by patient_id)
  final Map<String, Map<String, dynamic>> _webStore = {};

  /// Call once in main() before runApp().
  static Future<void> init() async {
    // Nothing to do — database is lazily opened on first use.
    // If you later add sqflite_common_ffi_web you can activate it here.
  }

  bool get _isWeb => kIsWeb;

  Future<Database?> get _database async {
    if (_isWeb) return null; // web uses _webStore
    if (_db != null) return _db;
    _db = await _initDb();
    return _db;
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
        await db.execute('CREATE INDEX idx_synced ON $_table (is_synced)');
      },
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> savePatient(PatientFullRecord record) async {
    final row = <String, dynamic>{
      'patient_id': record.patientId,
      'device_uid': record.deviceUid,
      'patient_name': record.patientInfo.fullName,
      'record_json': jsonEncode(record.toJson()),
      'is_synced': 0,
      'sync_error': null,
      'created_at': DateTime.now().toIso8601String(),
      'synced_at': null,
    };

    if (_isWeb) {
      _webStore[record.patientId] = row;
      return;
    }

    final db = await _database;
    await db!.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<List<LocalPatientEntry>> getUnsyncedRecords() async {
    if (_isWeb) {
      return _webStore.values
          .where((r) => (r['is_synced'] as int) == 0)
          .map(LocalPatientEntry.fromRow)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final db = await _database;
    final rows = await db!.query(
      _table,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return rows.map(LocalPatientEntry.fromRow).toList();
  }

  Future<List<LocalPatientEntry>> getAllRecords() async {
    if (_isWeb) {
      return _webStore.values.map(LocalPatientEntry.fromRow).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await _database;
    final rows = await db!.query(_table, orderBy: 'created_at DESC');
    return rows.map(LocalPatientEntry.fromRow).toList();
  }

  Future<int> getUnsyncedCount() async {
    if (_isWeb) {
      return _webStore.values.where((r) => (r['is_synced'] as int) == 0).length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Sync lifecycle ────────────────────────────────────────────────────────

  Future<void> markSynced(String patientId) async {
    // After successful cloud sync, delete the local record entirely.
    // The authoritative copy now lives in the backend.
    if (_isWeb) {
      _webStore.remove(patientId);
      return;
    }
    final db = await _database;
    await db!.delete(_table, where: 'patient_id = ?', whereArgs: [patientId]);
  }

  Future<void> markSyncError(String patientId, String error) async {
    if (_isWeb) {
      if (_webStore.containsKey(patientId)) {
        _webStore[patientId] = {..._webStore[patientId]!, 'sync_error': error};
      }
      return;
    }
    final db = await _database;
    await db!.update(
      _table,
      {'sync_error': error},
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  Future<void> deleteRecord(String patientId) async {
    if (_isWeb) {
      _webStore.remove(patientId);
      return;
    }
    final db = await _database;
    await db!.delete(_table, where: 'patient_id = ?', whereArgs: [patientId]);
  }

  Future<void> clearAll() async {
    if (_isWeb) {
      _webStore.clear();
      return;
    }
    final db = await _database;
    await db!.delete(_table);
  }
}

// ── Data class ────────────────────────────────────────────────────────────

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

  PatientFullRecord? toPatientRecord() {
    if (recordJson.isEmpty || recordJson == '{}') return null;
    try {
      return PatientFullRecord.fromJson(
        jsonDecode(recordJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  String get maskedName {
    final parts = patientName.split(' ');
    if (parts.length <= 1) return patientName;
    return '${parts.first} ${parts[1][0]}.';
  }
}
