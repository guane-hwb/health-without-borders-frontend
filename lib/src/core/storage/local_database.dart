// lib/src/core/storage/local_database.dart

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/nfc/domain/patient_record.dart';
import '../utils/app_logger.dart';

/// Local SQLite database for offline-first patient storage.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _dbName = 'hwb_patients.db';
  static const int _dbVersion = 4;
  static const String _table = 'local_patients';
  static const String _chipStatusTable = 'nfc_chip_status';
  static const String _emergencyLogTable = 'emergency_access_log';

  Database? _db;

  final Map<String, Map<String, dynamic>> _webStore = {};
  final List<Map<String, Object?>> _webEmergencyLog = <Map<String, Object?>>[];
  final Map<String, Map<String, dynamic>> _webChipStatus = {};

  static Future<void> init() async {}

  bool get _isWeb => kIsWeb;

  Future<Database?> get _database async {
    if (_isWeb) return null;
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
            sync_error_code INTEGER,
            created_at    TEXT NOT NULL,
            synced_at     TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_synced ON $_table (is_synced)');
        await _createChipStatusTable(db);
        await _createEmergencyLogTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _createChipStatusTable(db);
        }
        if (oldVersion < 4) {
          await _createEmergencyLogTable(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN sync_error_code INTEGER',
          );
        }
      },
    );
  }

  static Future<void> _createChipStatusTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_chipStatusTable (
        patient_id          TEXT PRIMARY KEY,
        patient_chip_dirty  INTEGER NOT NULL DEFAULT 0,
        guardian_chip_dirty INTEGER NOT NULL DEFAULT 0,
        updated_at          TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createEmergencyLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_emergencyLogTable (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_uid   TEXT NOT NULL,
        patient_name  TEXT,
        user_id       TEXT,
        reason        TEXT NOT NULL,
        occurred_at   TEXT NOT NULL,
        is_synced     INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> logEmergencyAccess({
    required String patientUid,
    String? patientName,
    String? userId,
    String reason = 'guardian_absent_offline',
  }) async {
    final row = <String, Object?>{
      'patient_uid': patientUid,
      'patient_name': patientName,
      'user_id': userId,
      'reason': reason,
      'occurred_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    };
    try {
      final db = await _database;
      if (db == null) {
        _webEmergencyLog.add(row);
        return;
      }
      await db.insert(_emergencyLogTable, row);
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando registro de emergencia local',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs() async {
    try {
      final db = await _database;
      if (db == null) {
        return _webEmergencyLog
            .where((Map<String, Object?> r) => r['is_synced'] == 0)
            .toList();
      }
      return db.query(_emergencyLogTable, where: 'is_synced = 0');
    } catch (e) {
      AppLogger.e(
        'Error obteniendo registros de emergencia no sincronizados: $e',
      );
      return const <Map<String, Object?>>[];
    }
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
      'sync_error_code': null,
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
      whereArgs: const <int>[0],
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

  Future<void> markSynced(String patientId, {String? createdAt}) async {
    if (_isWeb) {
      if (createdAt != null) {
        final current = _webStore[patientId];
        if (current != null && current['created_at'] != createdAt) {
          return;
        }
      }
      _webStore.remove(patientId);
      return;
    }
    final db = await _database;
    if (createdAt != null) {
      await db!.delete(
        _table,
        where: 'patient_id = ? AND created_at = ?',
        whereArgs: <String>[patientId, createdAt],
      );
    } else {
      await db!.delete(
        _table,
        where: 'patient_id = ?',
        whereArgs: <String>[patientId],
      );
    }
  }

  Future<void> markSyncError(
    String patientId,
    String error, {
    int? statusCode,
  }) async {
    if (_isWeb) {
      if (_webStore.containsKey(patientId)) {
        _webStore[patientId] = <String, dynamic>{
          ..._webStore[patientId]!,
          'sync_error': error,
          'sync_error_code': statusCode,
        };
      }
      return;
    }
    final db = await _database;
    await db!.update(
      _table,
      <String, dynamic>{'sync_error': error, 'sync_error_code': statusCode},
      where: 'patient_id = ?',
      whereArgs: <String>[patientId],
    );
  }

  Future<void> deleteRecord(String patientId) async {
    if (_isWeb) {
      _webStore.remove(patientId);
      return;
    }
    final db = await _database;
    await db!.delete(
      _table,
      where: 'patient_id = ?',
      whereArgs: <String>[patientId],
    );
  }

  // ── NFC chip status (backup staleness) ────────────────────────────────────

  Future<NfcChipStatus?> getChipStatus(String patientId) async {
    if (patientId.isEmpty) return null;
    if (_isWeb) {
      final r = _webChipStatus[patientId];
      return r == null ? null : NfcChipStatus.fromRow(r);
    }
    final db = await _database;
    final rows = await db!.query(
      _chipStatusTable,
      where: 'patient_id = ?',
      whereArgs: <String>[patientId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NfcChipStatus.fromRow(rows.first);
  }

  Future<void> markChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {
    if (patientId.isEmpty || (!patient && !guardian)) return;
    final current =
        (await getChipStatus(patientId)) ?? NfcChipStatus.clean(patientId);
    await _upsertChipStatus(
      current.markDirty(patient: patient, guardian: guardian),
    );
  }

  Future<void> clearChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {
    if (patientId.isEmpty) return;
    final current = await getChipStatus(patientId);
    if (current == null) return;
    final updated = current.clearDirty(patient: patient, guardian: guardian);
    if (!updated.anyDirty) {
      await _deleteChipStatus(patientId);
    } else {
      await _upsertChipStatus(updated);
    }
  }

  Future<void> _upsertChipStatus(NfcChipStatus status) async {
    final row = status.toRow()
      ..['updated_at'] = DateTime.now().toIso8601String();
    if (_isWeb) {
      _webChipStatus[status.patientId] = row;
      return;
    }
    final db = await _database;
    await db!.insert(
      _chipStatusTable,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deleteChipStatus(String patientId) async {
    if (_isWeb) {
      _webChipStatus.remove(patientId);
      return;
    }
    final db = await _database;
    await db!.delete(
      _chipStatusTable,
      where: 'patient_id = ?',
      whereArgs: <String>[patientId],
    );
  }

  Future<void> clearAll() async {
    if (_isWeb) {
      _webStore.clear();
      _webEmergencyLog.clear();
      _webChipStatus.clear();
      return;
    }
    final db = await _database;
    await db!.delete(_table);
    await db.delete(_chipStatusTable);
    await db.delete(_emergencyLogTable);
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
    this.syncErrorCode,
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
      syncErrorCode: row['sync_error_code'] as int?,
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
  final int? syncErrorCode;
  final String createdAt;
  final String? syncedAt;

  PatientFullRecord? toPatientRecord() {
    if (recordJson.isEmpty || recordJson == '{}') return null;
    try {
      return PatientFullRecord.fromJson(
        jsonDecode(recordJson) as Map<String, dynamic>,
      );
    } catch (e) {
      AppLogger.e('Error al deserializar recordJson local para $patientId: $e');
      return null;
    }
  }

  String get maskedName {
    final parts = patientName.split(' ');
    if (parts.length <= 1) return patientName;
    return '${parts.first} ${parts[1][0]}.';
  }
}

// ── NFC chip status data class ──────────────────────────────────────────────

class NfcChipStatus {
  const NfcChipStatus({
    required this.patientId,
    required this.patientChipDirty,
    required this.guardianChipDirty,
  });

  factory NfcChipStatus.clean(String patientId) => NfcChipStatus(
    patientId: patientId,
    patientChipDirty: false,
    guardianChipDirty: false,
  );

  factory NfcChipStatus.fromRow(Map<String, dynamic> row) => NfcChipStatus(
    patientId: row['patient_id'] as String,
    patientChipDirty: (row['patient_chip_dirty'] as int? ?? 0) == 1,
    guardianChipDirty: (row['guardian_chip_dirty'] as int? ?? 0) == 1,
  );

  final String patientId;
  final bool patientChipDirty;
  final bool guardianChipDirty;

  bool get anyDirty => patientChipDirty || guardianChipDirty;

  NfcChipStatus markDirty({bool patient = false, bool guardian = false}) =>
      NfcChipStatus(
        patientId: patientId,
        patientChipDirty: patientChipDirty || patient,
        guardianChipDirty: guardianChipDirty || guardian,
      );

  NfcChipStatus clearDirty({bool patient = false, bool guardian = false}) =>
      NfcChipStatus(
        patientId: patientId,
        patientChipDirty: patientChipDirty && !patient,
        guardianChipDirty: guardianChipDirty && !guardian,
      );

  Map<String, dynamic> toRow() => <String, dynamic>{
    'patient_id': patientId,
    'patient_chip_dirty': patientChipDirty ? 1 : 0,
    'guardian_chip_dirty': guardianChipDirty ? 1 : 0,
  };
}
