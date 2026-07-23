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
  static const int _dbVersion = 4;
  static const String _table = 'local_patients';
  static const String _chipStatusTable = 'nfc_chip_status';
  static const String _emergencyLogTable = 'emergency_access_log';

  Database? _db;

  // In-memory fallback for web (rows keyed by patient_id)
  final Map<String, Map<String, dynamic>> _webStore = {};
  final List<Map<String, Object?>> _webEmergencyLog = <Map<String, Object?>>[];

  // In-memory fallback for chip-dirty status on web (keyed by patient_id)
  final Map<String, Map<String, dynamic>> _webChipStatus = {};

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
          // Persist the HTTP status of the last sync failure so the queue UI
          // can tell a permanent conflict (409) apart from a retryable error.
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN sync_error_code INTEGER',
          );
        }
      },
    );
  }

  /// NFC backup staleness, tracked separately from the outbound sync queue so
  /// it survives `markSynced` (which deletes the queue row). Persists which
  /// chips are out of date for a patient until they are re-written.
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

  /// Break-glass access log.
  ///
  /// Records every time a clinician viewed a minor's data offline without the
  /// guardian card present. Kept in its own table with an `is_synced` flag,
  /// matching the outbound queue pattern, so it can be shipped to the server
  /// once an audit endpoint exists. Until then it is local-only — which is a
  /// known limitation, since the log lives on the device of the person it
  /// audits.
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

  /// Appends a break-glass access entry. Never throws: an audit write must not
  /// be able to block a clinician from seeing a patient in an emergency.
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
    } catch (_) {
      // Swallow: losing an audit row is bad, blocking emergency care is worse.
    }
  }

  /// Break-glass entries not yet shipped to the server.
  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs() async {
    try {
      final db = await _database;
      if (db == null) {
        return _webEmergencyLog
            .where((Map<String, Object?> r) => r['is_synced'] == 0)
            .toList();
      }
      return db.query(_emergencyLogTable, where: 'is_synced = 0');
    } catch (_) {
      return <Map<String, Object?>>[];
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

  Future<void> markSyncError(
    String patientId,
    String error, {
    int? statusCode,
  }) async {
    if (_isWeb) {
      if (_webStore.containsKey(patientId)) {
        _webStore[patientId] = {
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
      {'sync_error': error, 'sync_error_code': statusCode},
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

  // ── NFC chip status (backup staleness) ────────────────────────────────────

  /// Returns the chip-dirty status for a patient, or null if nothing is stale.
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
      whereArgs: [patientId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NfcChipStatus.fromRow(rows.first);
  }

  /// Marks one or both chips as stale for a patient. Flags are OR-ed with any
  /// existing state, so repeated edits never clear a pending chip.
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

  /// Clears the dirty flag for one or both chips after a successful re-write.
  /// Deletes the row once nothing is stale.
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
      whereArgs: [patientId],
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

// ── NFC chip status data class ──────────────────────────────────────────────

/// Tracks which NFC chips are out of date relative to the patient's record.
///
/// The guardian card holds the full record, so any change makes it stale; the
/// patient wristband holds only triage, so it goes stale only when a
/// triage-relevant field changes (demographics, blood type, chronic
/// conditions, allergies, guardian UIDs).
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
