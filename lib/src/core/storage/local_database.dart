// lib/src/core/storage/local_database.dart

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/nfc/domain/patient_record.dart';
import '../utils/app_logger.dart';
import 'web_storage.dart' as web_storage;

const Set<int> kPermanentSyncErrorCodes = <int>{400, 409, 422};

class LocalDatabase {
  LocalDatabase._({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? _defaultSecureStorage,
      _forceWeb = null,
      _webGet = web_storage.getWebStorageItem,
      _webSet = web_storage.setWebStorageItem,
      _webRemove = web_storage.removeWebStorageItem;

  static LocalDatabase instance = LocalDatabase._();

  @visibleForTesting
  static void setInstanceForTesting(LocalDatabase db) {
    instance = db;
  }

  @visibleForTesting
  LocalDatabase.forTesting({
    FlutterSecureStorage? secureStorage,
    bool? forceWeb,
    String? Function(String key)? webGet,
    void Function(String key, String value)? webSet,
    void Function(String key)? webRemove,
  }) : _secureStorage = secureStorage ?? _defaultSecureStorage,
       _forceWeb = forceWeb,
       _webGet = webGet ?? web_storage.getWebStorageItem,
       _webSet = webSet ?? web_storage.setWebStorageItem,
       _webRemove = webRemove ?? web_storage.removeWebStorageItem;

  final bool? _forceWeb;
  final String? Function(String key) _webGet;
  final void Function(String key, String value) _webSet;
  final void Function(String key) _webRemove;

  static const FlutterSecureStorage _defaultSecureStorage =
      FlutterSecureStorage(webOptions: WebOptions(useSessionStorage: true));

  static const String _dbName = 'hwb_patients.db';
  static const int _dbVersion = 5;
  static const String _table = 'local_patients';
  static const String _chipStatusTable = 'nfc_chip_status';
  static const String _emergencyLogTable = 'emergency_access_log';
  static const String _dbKeyStorageName = 'hwb_sqlite_aes_key';

  static const String _webStoreKey = 'hwb_web_patients_store';
  static const String _webLogKey = 'hwb_web_emergency_log';
  static const String _webChipKey = 'hwb_web_chip_status';

  final FlutterSecureStorage _secureStorage;
  Database? _db;
  Uint8List? _dbEncryptionKey;

  static Future<void> init() async {}

  bool get _isWeb => _forceWeb ?? kIsWeb;

  Map<String, Map<String, dynamic>> get _webStore {
    if (!_isWeb) return {};
    try {
      final raw = _webGet(_webStoreKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  void _saveWebStore(Map<String, Map<String, dynamic>> store) {
    if (!_isWeb) return;
    try {
      _webSet(_webStoreKey, jsonEncode(store));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando en localStorage web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  List<Map<String, Object?>> get _webEmergencyLog {
    if (!_isWeb) return [];
    try {
      final raw = _webGet(_webLogKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((v) => Map<String, Object?>.from(v as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  void _saveWebEmergencyLog(List<Map<String, Object?>> logs) {
    if (!_isWeb) return;
    try {
      _webSet(_webLogKey, jsonEncode(logs));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando logs de emergencia en web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, Map<String, dynamic>> get _webChipStatus {
    if (!_isWeb) return {};
    try {
      final raw = _webGet(_webChipKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  void _saveWebChipStatus(Map<String, Map<String, dynamic>> status) {
    if (!_isWeb) return;
    try {
      _webSet(_webChipKey, jsonEncode(status));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando chip status en web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ── Encryption Helpers ────────────────────────────────────────────────────

  Future<Uint8List> _getOrCreateEncryptionKey() async {
    if (_dbEncryptionKey != null) return _dbEncryptionKey!;

    try {
      final existingKeyBase64 = await _secureStorage.read(
        key: _dbKeyStorageName,
      );
      if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
        _dbEncryptionKey = base64Decode(existingKeyBase64);
        return _dbEncryptionKey!;
      }
    } catch (e) {
      AppLogger.e('Error leyendo clave de cifrado local: $e');
    }

    final random = Random.secure();
    final newKeyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );

    try {
      await _secureStorage.write(
        key: _dbKeyStorageName,
        value: base64Encode(newKeyBytes),
      );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo persistir la clave de cifrado local',
        error: e,
        stackTrace: stack,
      );
      throw StateError(
        'Almacén seguro no disponible: no se puede cifrar la PHI local.',
      );
    }

    _dbEncryptionKey = newKeyBytes;
    return _dbEncryptionKey!;
  }

  Future<String> _encryptPayload(String plainJson) async {
    try {
      final keyBytes = await _getOrCreateEncryptionKey();
      final algorithm = crypto.AesGcm.with256bits();
      final secretKey = crypto.SecretKey(keyBytes);
      final nonce = algorithm.newNonce();

      final secretBox = await algorithm.encrypt(
        utf8.encode(plainJson),
        secretKey: secretKey,
        nonce: nonce,
      );

      final combined = Uint8List(
        secretBox.nonce.length +
            secretBox.cipherText.length +
            secretBox.mac.bytes.length,
      );
      combined.setAll(0, secretBox.nonce);
      combined.setAll(secretBox.nonce.length, secretBox.cipherText);
      combined.setAll(
        secretBox.nonce.length + secretBox.cipherText.length,
        secretBox.mac.bytes,
      );

      return base64Encode(combined);
    } catch (e, stack) {
      AppLogger.e('Error cifrando PHI local', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<String> _decryptPayload(String cipherBase64) async {
    if (cipherBase64.startsWith('{') && cipherBase64.endsWith('}')) {
      AppLogger.d(
        'Registro local en formato heredado (sin cifrar): pendiente de migrar',
      );
      return cipherBase64;
    }

    try {
      final keyBytes = await _getOrCreateEncryptionKey();
      final combined = base64Decode(cipherBase64);

      if (combined.length < 12 + 16) {
        return '{}';
      }

      final nonce = combined.sublist(0, 12);
      final macBytes = combined.sublist(combined.length - 16);
      final cipherText = combined.sublist(12, combined.length - 16);

      final algorithm = crypto.AesGcm.with256bits();
      final secretKey = crypto.SecretKey(keyBytes);
      final secretBox = crypto.SecretBox(
        cipherText,
        nonce: nonce,
        mac: crypto.Mac(macBytes),
      );

      final clearBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(clearBytes);
    } catch (e) {
      AppLogger.e('Error descifrando PHI local: $e');
      return '{}';
    }
  }

  static String _maskName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 1) return parts.isEmpty ? '' : parts.first;
    return '${parts.first} ${parts[1][0]}.';
  }

  Future<void> destroyEncryptionKey() async {
    _dbEncryptionKey = null;
    try {
      await _secureStorage.delete(key: _dbKeyStorageName);
    } catch (e) {
      AppLogger.e('Error borrando la clave de cifrado local: $e');
    }
  }

  // ── Database Initialization ───────────────────────────────────────────────

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
      onDowngrade: (Database db, int oldVersion, int newVersion) async {
        AppLogger.e(
          'Downgrade de esquema detectado ($oldVersion → $newVersion). '
          'Se conservan los datos locales.',
        );
      },
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
            synced_at     TEXT,
            revision      INTEGER NOT NULL DEFAULT 0
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
          await _addColumnIfMissing(db, _table, 'sync_error_code', 'INTEGER');
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            _table,
            'revision',
            'INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final bool exists = info.any((row) => row['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
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
      'patient_name': patientName == null
          ? null
          : await _encryptPayload(patientName),
      'user_id': userId == null ? null : await _encryptPayload(userId),
      'reason': reason,
      'occurred_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    };
    try {
      final db = await _database;
      if (db == null) {
        final logs = _webEmergencyLog;
        logs.add(<String, Object?>{
          ...row,
          'id': DateTime.now().microsecondsSinceEpoch,
        });
        _saveWebEmergencyLog(logs);
        return;
      }
      await db.insert(_emergencyLogTable, row);
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando registro de emergencia local',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs() async {
    try {
      final db = await _database;
      final rows = db == null
          ? _webEmergencyLog
                .where((Map<String, Object?> r) => r['is_synced'] == 0)
                .toList()
          : await db.query(_emergencyLogTable, where: 'is_synced = 0');

      final out = <Map<String, Object?>>[];
      for (final r in rows) {
        final mutable = Map<String, Object?>.from(r);
        final name = mutable['patient_name'] as String?;
        if (name != null && name.isNotEmpty) {
          mutable['patient_name'] = await _decryptPayload(name);
        }
        final uId = mutable['user_id'] as String?;
        if (uId != null && uId.isNotEmpty) {
          mutable['user_id'] = await _decryptPayload(uId);
        }
        out.add(mutable);
      }
      return out;
    } catch (e) {
      AppLogger.e(
        'Error obteniendo registros de emergencia no sincronizados: $e',
      );
      return const <Map<String, Object?>>[];
    }
  }

  Future<void> markEmergencyLogsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    if (_isWeb) {
      final logs = _webEmergencyLog;
      for (final row in logs) {
        if (ids.contains(row['id'])) row['is_synced'] = 1;
      }
      _saveWebEmergencyLog(logs);
      return;
    }
    final db = await _database;
    final placeholders = List<String>.filled(ids.length, '?').join(',');
    await db!.update(
      _emergencyLogTable,
      <String, Object?>{'is_synced': 1},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> savePatient(PatientFullRecord record) async {
    final rawJson = jsonEncode(record.toJson());
    final encryptedJson = await _encryptPayload(rawJson);

    String createdAt = DateTime.now().toIso8601String();
    int revision = 0;

    final maskedNameStr = _maskName(record.patientInfo.fullName);

    if (_isWeb) {
      final store = _webStore;
      final previous = store[record.patientId];
      if (previous != null) {
        createdAt = previous['created_at'] as String;
        revision = ((previous['revision'] as int?) ?? 0) + 1;
      }
      store[record.patientId] = <String, dynamic>{
        'patient_id': record.patientId,
        'device_uid': record.deviceUid,
        'patient_name': maskedNameStr,
        'record_json': encryptedJson,
        'is_synced': 0,
        'sync_error': null,
        'sync_error_code': null,
        'created_at': createdAt,
        'synced_at': null,
        'revision': revision,
      };
      _saveWebStore(store);
      return;
    }

    final db = await _database;

    final existing = await db!.query(
      _table,
      columns: ['created_at', 'revision'],
      where: 'patient_id = ?',
      whereArgs: [record.patientId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final prevCreatedAt = existing.first['created_at'] as String?;
      if (prevCreatedAt != null) createdAt = prevCreatedAt;
      revision = ((existing.first['revision'] as int?) ?? 0) + 1;
    }

    final row = <String, dynamic>{
      'patient_id': record.patientId,
      'device_uid': record.deviceUid,
      'patient_name': maskedNameStr,
      'record_json': encryptedJson,
      'is_synced': 0,
      'sync_error': null,
      'sync_error_code': null,
      'created_at': createdAt,
      'synced_at': null,
      'revision': revision,
    };

    await db.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<List<LocalPatientEntry>> getUnsyncedRecords() async {
    if (_isWeb) {
      final entries = <LocalPatientEntry>[];
      for (final r in _webStore.values.where(
        (r) => (r['is_synced'] as int) == 0,
      )) {
        final decryptedJson = await _decryptPayload(r['record_json'] as String);
        final row = Map<String, dynamic>.from(r);
        row['record_json'] = decryptedJson;
        entries.add(LocalPatientEntry.fromRow(row));
      }
      return entries..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final db = await _database;
    final rows = await db!.query(
      _table,
      where: 'is_synced = ?',
      whereArgs: const <int>[0],
      orderBy: 'created_at ASC',
    );

    final entries = <LocalPatientEntry>[];
    for (final row in rows) {
      final mutableRow = Map<String, dynamic>.from(row);
      mutableRow['record_json'] = await _decryptPayload(
        row['record_json'] as String,
      );
      entries.add(LocalPatientEntry.fromRow(mutableRow));
    }
    return entries;
  }

  Future<List<LocalPatientEntry>> getAllRecords() async {
    if (_isWeb) {
      final entries = <LocalPatientEntry>[];
      for (final r in _webStore.values) {
        final decryptedJson = await _decryptPayload(r['record_json'] as String);
        final row = Map<String, dynamic>.from(r);
        row['record_json'] = decryptedJson;
        entries.add(LocalPatientEntry.fromRow(row));
      }
      return entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await _database;
    final rows = await db!.query(_table, orderBy: 'created_at DESC');

    final entries = <LocalPatientEntry>[];
    for (final row in rows) {
      final mutableRow = Map<String, dynamic>.from(row);
      mutableRow['record_json'] = await _decryptPayload(
        row['record_json'] as String,
      );
      entries.add(LocalPatientEntry.fromRow(mutableRow));
    }
    return entries;
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

  Future<int> getRetryablePendingCount() async {
    if (_isWeb) {
      return _webStore.values.where((r) {
        if ((r['is_synced'] as int) != 0) return false;
        final code = r['sync_error_code'] as int?;
        return code == null || !kPermanentSyncErrorCodes.contains(code);
      }).length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
      'AND (sync_error_code IS NULL OR sync_error_code NOT IN (400, 409, 422))',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getBlockedCount() async {
    if (_isWeb) {
      return _webStore.values.where((r) {
        if ((r['is_synced'] as int) != 0) return false;
        final code = r['sync_error_code'] as int?;
        return code != null && kPermanentSyncErrorCodes.contains(code);
      }).length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
      'AND sync_error_code IN (400, 409, 422)',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Sync lifecycle ────────────────────────────────────────────────────────

  Future<void> purgeStalePermanentErrors({
    Duration maxAge = const Duration(days: 30),
  }) async {
    final threshold = DateTime.now().subtract(maxAge).toIso8601String();
    if (_isWeb) {
      final store = _webStore;
      store.removeWhere((id, row) {
        final code = row['sync_error_code'] as int?;
        final createdAt = row['created_at'] as String?;
        final isPermanent = code == 400 || code == 409 || code == 422;
        return isPermanent &&
            createdAt != null &&
            createdAt.compareTo(threshold) < 0;
      });
      _saveWebStore(store);
      return;
    }
    final db = await _database;
    await db!.delete(
      _table,
      where: 'sync_error_code IN (400, 409, 422) AND created_at < ?',
      whereArgs: [threshold],
    );
  }

  Future<void> markSynced(
    String patientId, {
    String? createdAt,
    String? recordJson,
    int? revision,
  }) async {
    if (_isWeb) {
      final store = _webStore;
      final current = store[patientId];
      if (current == null) return;
      if (revision != null &&
          ((current['revision'] as int?) ?? 0) != revision) {
        return;
      }
      store.remove(patientId);
      _saveWebStore(store);
      return;
    }
    final db = await _database;

    if (revision != null) {
      await db!.delete(
        _table,
        where: 'patient_id = ? AND revision = ?',
        whereArgs: <Object>[patientId, revision],
      );
    } else if (createdAt != null) {
      await db!.delete(
        _table,
        where: 'patient_id = ? AND created_at = ?',
        whereArgs: <Object>[patientId, createdAt],
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
      final store = _webStore;
      if (store.containsKey(patientId)) {
        store[patientId] = <String, dynamic>{
          ...store[patientId]!,
          'sync_error': error,
          'sync_error_code': statusCode,
        };
        _saveWebStore(store);
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
      final store = _webStore;
      store.remove(patientId);
      _saveWebStore(store);
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
      final statusMap = _webChipStatus;
      statusMap[status.patientId] = row;
      _saveWebChipStatus(statusMap);
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
      final statusMap = _webChipStatus;
      statusMap.remove(patientId);
      _saveWebChipStatus(statusMap);
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
      _webRemove(_webStoreKey);
      _webRemove(_webChipKey);
      return;
    }
    final db = await _database;
    await db!.delete(_table);
    await db.delete(_chipStatusTable);
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

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
    this.revision = 0,
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
      revision: (row['revision'] as int?) ?? 0,
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
  final int revision;

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
    final parts = patientName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 1) return patientName;
    return '${parts.first} ${parts[1][0]}.';
  }
}

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
