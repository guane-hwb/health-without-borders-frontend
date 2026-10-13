// lib/src/core/storage/local_database.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/nfc/domain/patient_record.dart';
import '../utils/app_logger.dart';
import '../utils/clinical_time.dart';
import 'web_storage.dart' as web_storage;

const Set<int> kPermanentSyncErrorCodes = <int>{400, 403, 409, 422};

final String _permanentCodesSql = kPermanentSyncErrorCodes.join(', ');

class LocalKeyUnavailableException implements Exception {
  LocalKeyUnavailableException(this.keyName, this.cause);

  final String keyName;
  final Object cause;

  @override
  String toString() =>
      'LocalKeyUnavailableException: No se pudo leer la clave de cifrado "$keyName" tras varios reintentos. '
      'No se sobrescribirá la clave existente para evitar pérdida de datos. Causa: $cause';
}

class WebStoreCorruptionException implements Exception {
  WebStoreCorruptionException(this.key, this.quarantineKey);

  final String key;
  final String quarantineKey;

  @override
  String toString() =>
      'WebStoreCorruptionException: no se pudo decodificar "$key"; '
      'el contenido original se conservó en "$quarantineKey".';
}

class AuditDecryptionException implements Exception {
  AuditDecryptionException(this.logId);
  final int logId;

  @override
  String toString() =>
      'AuditDecryptionException: no se pudo descifrar el registro de auditoría $logId por clave destruida o corrupta.';
}

class LocalDatabase {
  LocalDatabase._({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? _defaultSecureStorage,
      _legacySecureStorage = _defaultLegacySecureStorage,
      _platformOverride = null,
      _legacyDatabasesDirectory = getDatabasesPath,
      _protectedDirectory = _defaultProtectedDirectory,
      _excludeFromBackup = _defaultExcludeFromBackup,
      _forceWeb = null,
      _webGet = web_storage.getWebStorageItem,
      _webSet = web_storage.setWebStorageItem,
      _webRemove = web_storage.removeWebStorageItem,
      _webClearAll = web_storage.clearAllWebStorage,
      _webList = web_storage.listWebStorageEntries,
      _webDeleteByPrefix = web_storage.deleteWebStorageByPrefix;

  static LocalDatabase instance = LocalDatabase._();

  @visibleForTesting
  static void setInstanceForTesting(LocalDatabase db) {
    instance = db;
  }

  @visibleForTesting
  LocalDatabase.forTesting({
    FlutterSecureStorage? secureStorage,
    bool? forceWeb,
    Future<String?> Function(String key)? webGet,
    Future<void> Function(String key, String value)? webSet,
    Future<void> Function(String key)? webRemove,
    Future<void> Function()? webClearAll,
    Future<List<MapEntry<String, String>>> Function(String prefix)? webList,
    Future<void> Function(String prefix)? webDeleteByPrefix,
    FlutterSecureStorage? legacySecureStorage,
    TargetPlatform? platformOverride,
    Future<String> Function()? legacyDatabasesDirectory,
    Future<String> Function()? protectedDirectory,
    Future<void> Function(String path)? excludeFromBackup,
  }) : _secureStorage = secureStorage ?? _defaultSecureStorage,
       _legacySecureStorage =
           legacySecureStorage ?? _defaultLegacySecureStorage,
       _platformOverride = platformOverride,
       _legacyDatabasesDirectory = legacyDatabasesDirectory ?? getDatabasesPath,
       _protectedDirectory = protectedDirectory ?? _defaultProtectedDirectory,
       _excludeFromBackup = excludeFromBackup ?? _defaultExcludeFromBackup,
       _forceWeb = forceWeb,
       _webGet = webGet ?? web_storage.getWebStorageItem,
       _webSet = webSet ?? web_storage.setWebStorageItem,
       _webRemove = webRemove ?? web_storage.removeWebStorageItem,
       _webClearAll = webClearAll ?? web_storage.clearAllWebStorage,
       _webList = webList ?? web_storage.listWebStorageEntries,
       _webDeleteByPrefix =
           webDeleteByPrefix ?? web_storage.deleteWebStorageByPrefix;

  final bool? _forceWeb;
  final FlutterSecureStorage _legacySecureStorage;
  final TargetPlatform? _platformOverride;
  final Future<String> Function() _legacyDatabasesDirectory;
  final Future<String> Function() _protectedDirectory;
  final Future<void> Function(String path) _excludeFromBackup;
  final Future<String?> Function(String key) _webGet;
  final Future<void> Function(String key, String value) _webSet;
  final Future<void> Function(String key) _webRemove;
  final Future<void> Function()? _webClearAll;
  final Future<List<MapEntry<String, String>>> Function(String prefix) _webList;
  final Future<void> Function(String prefix) _webDeleteByPrefix;

  static final Symbol _webLockZoneKey = const Symbol('LocalDatabase._webLock');
  Future<void> _webIoLock = Future<void>.value();

  Future<T> _withWebLock<T>(Future<T> Function() action) async {
    if (Zone.current[_webLockZoneKey] == this) {
      return await action();
    }
    final completer = Completer<void>();
    final previous = _webIoLock;
    _webIoLock = completer.future;
    try {
      await previous.catchError((_) {});
      return await runZoned(action, zoneValues: {_webLockZoneKey: this});
    } finally {
      completer.complete();
    }
  }

  static const String _keychainService = 'hwb_local_db';

  static const FlutterSecureStorage _defaultSecureStorage =
      FlutterSecureStorage(
        iOptions: IOSOptions(
          accountName: _keychainService,
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        mOptions: MacOsOptions(
          accountName: _keychainService,
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        aOptions: AndroidOptions(),
        // Web: la llave vive en sessionStorage, no en localStorage junto al
        // texto cifrado de IndexedDB. Al cerrar la pestaña la cola queda
        // ilegible y se borra al arrancar sin sesión (AuthRepository).
        webOptions: WebOptions(useSessionStorage: true),
      );

  /// iOS/macOS: almacén anterior a la migración al llavero solo-dispositivo.
  /// Web: apunta al almacén persistente (localStorage) de versiones previas,
  /// solo para borrar las llaves que dejaron allí.
  static const FlutterSecureStorage _defaultLegacySecureStorage =
      FlutterSecureStorage(webOptions: WebOptions(useSessionStorage: false));

  @visibleForTesting
  static FlutterSecureStorage get defaultSecureStorageForTesting =>
      _defaultSecureStorage;

  static const MethodChannel _backupChannel = MethodChannel(
    'hwb/backup_exclusion',
  );

  static Future<String> _defaultProtectedDirectory() async =>
      (await getApplicationSupportDirectory()).path;

  static Future<void> _defaultExcludeFromBackup(String path) => _backupChannel
      .invokeMethod<void>('excludeFromBackup', <String, String>{'path': path});

  static const String _protectedDbDirName = 'hwb_db';
  static const List<String> _dbSidecarSuffixes = <String>[
    '-wal',
    '-shm',
    '-journal',
  ];

  static const String _dbName = 'hwb_patients.db';
  static const int _dbVersion = 11;
  static const String _table = 'local_patients';
  static const String _chipStatusTable = 'nfc_chip_status';
  static const String _emergencyLogTable = 'emergency_access_log';
  static const String _keyVersionTable = 'nfc_key_version_observations';
  static const String _syncNoticeTable = 'sync_notices';
  static const String _dbKeyStorageName = 'hwb_sqlite_aes_key';
  static const String _auditKeyStorageName = 'hwb_sqlite_audit_aes_key';

  static const String _webStoreKey = 'hwb_web_patients_store';
  static const String _webLogKey = 'hwb_web_emergency_log';
  static const String _webChipKey = 'hwb_web_chip_status';

  static const String _webPatientPrefix = 'hwb_web_patient::';
  static const String _webChipPrefix = 'hwb_web_chip::';
  static const String _webKeyVersionPrefix = 'hwb_web_keyver::';
  static const String _webLogPrefix = 'hwb_web_emlog::';
  static const String _webNoticePrefix = 'hwb_web_notice::';

  final FlutterSecureStorage _secureStorage;
  Database? _db;
  Uint8List? _dbEncryptionKey;
  Uint8List? _auditEncryptionKey;
  Future<Uint8List>? _keyInitFuture;
  Future<Uint8List>? _auditKeyInitFuture;

  static Future<void> init() async {}

  bool get _isWeb => _forceWeb ?? kIsWeb;

  bool get _isApple {
    if (_isWeb) return false;
    final TargetPlatform platform = _platformOverride ?? defaultTargetPlatform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  bool _webMigrationChecked = false;

  Completer<void>? _webMigrationCompleter;

  Future<void> _ensureWebMigrated() async {
    if (!_isWeb || _webMigrationChecked) return;
    final existing = _webMigrationCompleter;
    if (existing != null) return existing.future;
    final completer = Completer<void>();
    _webMigrationCompleter = completer;
    try {
      try {
        final raw = await _webGet(_webStoreKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final row = Map<String, dynamic>.from(entry.value as Map);
            await _webSet('$_webPatientPrefix${entry.key}', jsonEncode(row));
          }
          await _webRemove(_webStoreKey);
        }
      } catch (e, stack) {
        AppLogger.e(
          'Error migrando cola web heredada de pacientes',
          error: e,
          stackTrace: stack,
        );
      }
      try {
        final raw = await _webGet(_webChipKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final row = Map<String, dynamic>.from(entry.value as Map);
            await _webSet('$_webChipPrefix${entry.key}', jsonEncode(row));
          }
          await _webRemove(_webChipKey);
        }
      } catch (e, stack) {
        AppLogger.e(
          'Error migrando chip status web heredado',
          error: e,
          stackTrace: stack,
        );
      }
      try {
        final raw = await _webGet(_webLogKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List;
          for (final v in decoded) {
            final row = Map<String, Object?>.from(v as Map);
            final id = (row['id'] as num?)?.toInt() ?? _newWebLocalId();
            row['id'] = id;
            await _webSet('$_webLogPrefix$id', jsonEncode(row));
          }
          await _webRemove(_webLogKey);
        }
      } catch (e, stack) {
        AppLogger.e(
          'Error migrando log de emergencia web heredado',
          error: e,
          stackTrace: stack,
        );
      }
    } finally {
      _webMigrationChecked = true;
      _webMigrationCompleter = null;
      completer.complete();
    }
  }

  int _newWebLocalId() => Random.secure().nextInt(1 << 31) + 1;

  final List<String> _webQuarantinedKeys = <String>[];

  @visibleForTesting
  List<String> get webQuarantinedKeysForTesting =>
      List.unmodifiable(_webQuarantinedKeys);

  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      _dbInitFuture = null;
    }
  }

  Future<Map<String, dynamic>?> _webReadJsonRecord(String key) async {
    await _ensureWebMigrated();
    final raw = await _webGet(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e, stack) {
      final quarantineKey =
          '$key::quarantine::${DateTime.now().toIso8601String()}';
      AppLogger.e(
        'Dato ilegible en "$key"; se preserva sin modificar en '
        '"$quarantineKey" y se aborta cualquier escritura sobre "$key".',
        error: e,
        stackTrace: stack,
      );
      try {
        await _webSet(quarantineKey, raw);
        _webQuarantinedKeys.add(quarantineKey);
      } catch (quarantineError, quarantineStack) {
        AppLogger.e(
          'No se pudo poner en cuarentena "$key"',
          error: quarantineError,
          stackTrace: quarantineStack,
        );
      }
      throw WebStoreCorruptionException(key, quarantineKey);
    }
  }

  Future<List<MapEntry<String, String>>> getWebQuarantinedEntries() async {
    if (!_isWeb) return const <MapEntry<String, String>>[];
    final results = <MapEntry<String, String>>[];
    for (final prefix in <String>[
      _webPatientPrefix,
      _webChipPrefix,
      _webLogPrefix,
    ]) {
      final entries = await _webList(prefix);
      results.addAll(entries.where((e) => e.key.contains('::quarantine::')));
    }
    return results;
  }

  Future<Map<String, dynamic>?> _webGetPatient(String patientId) =>
      _webReadJsonRecord('$_webPatientPrefix$patientId');

  Future<void> _webPutPatient(
    String patientId,
    Map<String, dynamic> row,
  ) async {
    await _ensureWebMigrated();
    try {
      await _webSet('$_webPatientPrefix$patientId', jsonEncode(row));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando paciente en IndexedDB web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _webDeletePatient(String patientId) async {
    await _ensureWebMigrated();
    await _webRemove('$_webPatientPrefix$patientId');
  }

  Future<List<Map<String, dynamic>>> _webAllPatients() async {
    await _ensureWebMigrated();
    final entries = await _webList(_webPatientPrefix);
    final rows = <Map<String, dynamic>>[];
    for (final e in entries) {
      if (e.key.contains('::quarantine::')) continue;
      try {
        rows.add(Map<String, dynamic>.from(jsonDecode(e.value) as Map));
      } catch (err, stack) {
        final quarantineKey =
            '${e.key}::quarantine::${DateTime.now().toIso8601String()}';
        AppLogger.e(
          'Registro de paciente ilegible en "${e.key}"; se preserva en '
          '"$quarantineKey" y se excluye de la lista hasta su recuperación.',
          error: err,
          stackTrace: stack,
        );
        try {
          await _webSet(quarantineKey, e.value);
          _webQuarantinedKeys.add(quarantineKey);
        } catch (_) {}
      }
    }
    return rows;
  }

  Future<Map<String, dynamic>?> _webGetChipRow(String patientId) =>
      _webReadJsonRecord('$_webChipPrefix$patientId');

  Future<void> _webPutChipRow(
    String patientId,
    Map<String, dynamic> row,
  ) async {
    await _ensureWebMigrated();
    try {
      await _webSet('$_webChipPrefix$patientId', jsonEncode(row));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando chip status en IndexedDB web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _webDeleteChipRow(String patientId) async {
    await _ensureWebMigrated();
    await _webRemove('$_webChipPrefix$patientId');
  }

  Future<void> _webPutKeyVersionRow(
    String deviceUid,
    Map<String, Object?> row,
  ) async {
    await _ensureWebMigrated();
    try {
      await _webSet('$_webKeyVersionPrefix$deviceUid', jsonEncode(row));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando versión de llave NFC en IndexedDB web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> _webAllKeyVersionRows() async {
    await _ensureWebMigrated();
    final entries = await _webList(_webKeyVersionPrefix);
    final rows = <Map<String, Object?>>[];
    for (final e in entries) {
      if (e.key.contains('::quarantine::')) continue;
      try {
        rows.add(Map<String, Object?>.from(jsonDecode(e.value) as Map));
      } catch (_) {}
    }
    return rows;
  }

  Future<Map<String, Object?>?> _webGetLogRow(int id) async {
    final decoded = await _webReadJsonRecord('$_webLogPrefix$id');
    return decoded == null ? null : Map<String, Object?>.from(decoded);
  }

  Future<void> _webPutLogRow(int id, Map<String, Object?> row) async {
    await _ensureWebMigrated();
    try {
      await _webSet('$_webLogPrefix$id', jsonEncode(row));
    } catch (e, stack) {
      AppLogger.e(
        'Error guardando log de emergencia en IndexedDB web',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> _webAllLogRows() async {
    await _ensureWebMigrated();
    final entries = await _webList(_webLogPrefix);
    final rows = <Map<String, Object?>>[];
    for (final e in entries) {
      if (e.key.contains('::quarantine::')) continue;
      try {
        rows.add(Map<String, Object?>.from(jsonDecode(e.value) as Map));
      } catch (err, stack) {
        final quarantineKey =
            '${e.key}::quarantine::${DateTime.now().toIso8601String()}';
        AppLogger.e(
          'Registro de emergencia ilegible en "${e.key}"; se preserva en '
          '"$quarantineKey" y se excluye de la lista hasta su recuperación.',
          error: err,
          stackTrace: stack,
        );
        try {
          await _webSet(quarantineKey, e.value);
          _webQuarantinedKeys.add(quarantineKey);
        } catch (_) {}
      }
    }
    return rows;
  }

  // ── Encryption Helpers (PHI) ──────────────────────────────────────────────

  Future<Uint8List> _getOrCreateEncryptionKey() async {
    if (_dbEncryptionKey != null) return _dbEncryptionKey!;
    return _keyInitFuture ??= _initEncryptionKey();
  }

  Future<String?> _readKeyWithMigration(String name) async {
    final String? current = await _secureStorage.read(key: name);
    if (!_isApple) return current;

    if (current != null && current.isNotEmpty) {
      await _dropRedundantLegacyKey(name, current);
      return current;
    }

    final String? legacy = await _legacySecureStorage.read(key: name);
    if (legacy == null || legacy.isEmpty) return null;
    return _migrateLegacyKey(name, legacy);
  }

  Future<String> _migrateLegacyKey(String name, String legacyValue) async {
    try {
      await _secureStorage.write(key: name, value: legacyValue);
      final String? check = await _secureStorage.read(key: name);
      if (check != legacyValue) {
        throw StateError('La verificación de la llave migrada no coincide.');
      }
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo migrar la llave "$name" al llavero solo-dispositivo; '
        'se sigue usando la heredada y se reintentará en el próximo arranque',
        error: e,
        stackTrace: stack,
      );
      try {
        await _secureStorage.delete(key: name);
      } catch (_) {}
      return legacyValue;
    }

    try {
      await _legacySecureStorage.delete(key: name);
    } catch (e) {
      AppLogger.e(
        'Llave "$name" migrada, pero no se pudo borrar la heredada: $e',
      );
    }
    return legacyValue;
  }

  Future<void> _dropRedundantLegacyKey(String name, String current) async {
    try {
      final String? legacy = await _legacySecureStorage.read(key: name);
      if (legacy == null || legacy.isEmpty) return;
      if (legacy == current) {
        await _legacySecureStorage.delete(key: name);
      } else {
        AppLogger.e(
          'La llave "$name" heredada difiere de la actual; se conserva la '
          'actual y se deja la heredada sin tocar.',
        );
      }
    } catch (e) {
      AppLogger.e('No se pudo limpiar la llave heredada "$name": $e');
    }
  }

  Future<Uint8List> _initEncryptionKey() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final existingKeyBase64 = await _readKeyWithMigration(
          _dbKeyStorageName,
        );
        if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
          _dbEncryptionKey = base64Decode(existingKeyBase64);
          return _dbEncryptionKey!;
        }
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        AppLogger.e(
          'Error leyendo clave de cifrado local (intento $attempt): $e',
        );
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    if (lastError != null) {
      _keyInitFuture = null;
      throw LocalKeyUnavailableException(_dbKeyStorageName, lastError);
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
      _keyInitFuture = null;
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

    final keyBytes = await _getOrCreateEncryptionKey();
    final combined = base64Decode(cipherBase64);

    if (combined.length < 12 + 16) {
      throw const FormatException(
        'Invalid or truncated local encryption payload.',
      );
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

    final clearBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(clearBytes);
  }

  // ── Encryption Helpers (Audit Logs) ──────────────────────────────────────

  Future<Uint8List> _getOrCreateAuditEncryptionKey() async {
    if (_auditEncryptionKey != null) return _auditEncryptionKey!;
    return _auditKeyInitFuture ??= _initAuditEncryptionKey();
  }

  Future<Uint8List> _initAuditEncryptionKey() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final existingKeyBase64 = await _readKeyWithMigration(
          _auditKeyStorageName,
        );
        if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
          _auditEncryptionKey = base64Decode(existingKeyBase64);
          return _auditEncryptionKey!;
        }
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        AppLogger.e(
          'Error leyendo clave de cifrado de auditoría (intento $attempt): $e',
        );
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    if (lastError != null) {
      _auditKeyInitFuture = null;
      throw LocalKeyUnavailableException(_auditKeyStorageName, lastError);
    }

    final random = Random.secure();
    final newKeyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );

    try {
      await _secureStorage.write(
        key: _auditKeyStorageName,
        value: base64Encode(newKeyBytes),
      );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo persistir la clave de cifrado de auditoría',
        error: e,
        stackTrace: stack,
      );
      _auditKeyInitFuture = null;
      throw StateError('Almacén seguro no disponible para auditoría.');
    }

    _auditEncryptionKey = newKeyBytes;
    return _auditEncryptionKey!;
  }

  Future<String> _encryptAuditPayload(String plainText) async {
    try {
      final keyBytes = await _getOrCreateAuditEncryptionKey();
      final algorithm = crypto.AesGcm.with256bits();
      final secretKey = crypto.SecretKey(keyBytes);
      final nonce = algorithm.newNonce();

      final secretBox = await algorithm.encrypt(
        utf8.encode(plainText),
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
      AppLogger.e(
        'Error cifrando log de auditoría',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  static final RegExp _unpaddedBase64 = RegExp(r'^[A-Za-z0-9+/]{40,}$');

  static bool _looksLikeAuditCiphertext(String value) =>
      value.startsWith('ey') ||
      value.contains('=') ||
      (value.length % 4 == 0 && _unpaddedBase64.hasMatch(value));

  Future<String> _decryptAuditPayload(String cipherBase64) async {
    if (!_looksLikeAuditCiphertext(cipherBase64)) {
      return cipherBase64;
    }

    try {
      final keyBytes = await _getOrCreateAuditEncryptionKey();
      final combined = base64Decode(cipherBase64);

      if (combined.length < 12 + 16) {
        return '[CORRUPTED_KEY_MISSING]';
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
      AppLogger.e('Error descifrando log de auditoría: $e');
      return '[CORRUPTED_KEY_MISSING]';
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
    _keyInitFuture = null;
    try {
      await _secureStorage.delete(key: _dbKeyStorageName);
    } catch (e) {
      AppLogger.e('Error borrando la clave de cifrado local: $e');
    }
    if (_isApple) {
      try {
        await _legacySecureStorage.delete(key: _dbKeyStorageName);
      } catch (e) {
        AppLogger.e('Error borrando la clave heredada de cifrado local: $e');
      }
    }
    if (_isWeb) {
      // Builds anteriores guardaron las llaves en localStorage: no deben
      // sobrevivir al cierre de sesión.
      for (final String name in <String>[
        _dbKeyStorageName,
        _auditKeyStorageName,
      ]) {
        try {
          await _legacySecureStorage.delete(key: name);
        } catch (e) {
          AppLogger.e('Error borrando la clave web heredada $name: $e');
        }
      }
      try {
        await _withWebLock(() => _webClearAll!());
      } catch (e) {
        AppLogger.e('Error limpiando IndexedDB web tras borrar la clave: $e');
      }
    }
  }

  // ── Database Initialization ───────────────────────────────────────────────

  Future<Database?> get _database async {
    if (_isWeb) return null;
    if (_db != null && _db!.isOpen) return _db;
    final Future<Database> pending = _dbInitFuture ??= _initDb();
    try {
      _db = await pending;
    } catch (_) {
      _dbInitFuture = null;
      rethrow;
    }
    return _db;
  }

  Future<Database>? _dbInitFuture;

  Future<String> _resolveDbPath() async {
    final String legacyPath = join(await _legacyDatabasesDirectory(), _dbName);
    if (!_isApple) return legacyPath;

    final String protectedDir = join(
      await _protectedDirectory(),
      _protectedDbDirName,
    );
    try {
      await Directory(protectedDir).create(recursive: true);
    } catch (e) {
      AppLogger.e('No se pudo crear la carpeta protegida de la base local: $e');
      return legacyPath;
    }
    try {
      await _excludeFromBackup(protectedDir);
    } catch (e) {
      AppLogger.e(
        'No se pudo excluir la base local de las copias de seguridad: $e',
      );
    }

    final String newPath = join(protectedDir, _dbName);
    final bool ready = await _moveLegacyDatabase(legacyPath, newPath);
    return ready ? newPath : legacyPath;
  }

  Future<bool> _moveLegacyDatabase(String from, String to) async {
    final File source = File(from);
    if (await File(to).exists()) return true;
    if (!await source.exists()) return true;

    final File staging = File('$to.migrating');
    try {
      for (final String suffix in <String>['', ..._dbSidecarSuffixes]) {
        final File stale = File('$to$suffix');
        if (await stale.exists()) await stale.delete();
      }
      if (await staging.exists()) await staging.delete();

      for (final String suffix in _dbSidecarSuffixes) {
        final File aux = File('$from$suffix');
        if (await aux.exists()) await aux.copy('$to$suffix');
      }
      await source.copy(staging.path);
      if (await staging.length() != await source.length()) {
        throw StateError('La copia de la base local no coincide en tamaño.');
      }
      await staging.rename(to);
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo trasladar la base local a Application Support',
        error: e,
        stackTrace: stack,
      );
      return false;
    }

    for (final String suffix in <String>[..._dbSidecarSuffixes, '']) {
      try {
        final File old = File('$from$suffix');
        if (await old.exists()) await old.delete();
      } catch (e) {
        AppLogger.e('No se pudo borrar el archivo heredado $from$suffix: $e');
      }
    }
    return true;
  }

  Future<Database> _initDb() async {
    final String dbPath = await _resolveDbPath();
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
            revision      INTEGER NOT NULL DEFAULT 0,
            owner_user_id TEXT,
            organization_id TEXT,
            pending_retired_reason TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_synced ON $_table (is_synced)');
        await db.execute('CREATE INDEX idx_owner ON $_table (owner_user_id)');
        await _createChipStatusTable(db);
        await _createEmergencyLogTable(db);
        await _createKeyVersionTable(db);
        await _createSyncNoticeTable(db);
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
        if (oldVersion < 6) {
          await _addColumnIfMissing(db, _table, 'owner_user_id', 'TEXT');
          await _addColumnIfMissing(db, _table, 'organization_id', 'TEXT');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_owner ON $_table (owner_user_id)',
          );
        }
        if (oldVersion < 7) {
          await _addColumnIfMissing(
            db,
            _table,
            'pending_retired_reason',
            'TEXT',
          );
        }
        if (oldVersion < 8) {
          await _addColumnIfMissing(
            db,
            _emergencyLogTable,
            'client_event_id',
            'TEXT',
          );
        }
        if (oldVersion < 9) {
          await _addColumnIfMissing(db, _table, 'owner_user_id', 'TEXT');
          await _addColumnIfMissing(db, _table, 'organization_id', 'TEXT');
          await _addColumnIfMissing(
            db,
            _emergencyLogTable,
            'owner_user_id',
            'TEXT',
          );
          await _addColumnIfMissing(
            db,
            _emergencyLogTable,
            'organization_id',
            'TEXT',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_emlog_owner ON '
            '$_emergencyLogTable (owner_user_id)',
          );
        }
        if (oldVersion < 10) {
          await _createKeyVersionTable(db);
        }
        if (oldVersion < 11) {
          await _createSyncNoticeTable(db);
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

  static Future<void> _createKeyVersionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_keyVersionTable (
        device_uid  TEXT PRIMARY KEY,
        device_role TEXT NOT NULL,
        key_version INTEGER NOT NULL,
        had_header  INTEGER NOT NULL DEFAULT 0,
        observed_at TEXT NOT NULL,
        is_synced   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_keyver_synced '
      'ON $_keyVersionTable (is_synced)',
    );
  }

  static Future<void> _createSyncNoticeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_syncNoticeTable (
        patient_id    TEXT PRIMARY KEY,
        patient_name  TEXT NOT NULL,
        codes         TEXT NOT NULL,
        owner_user_id TEXT,
        created_at    TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createEmergencyLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_emergencyLogTable (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        client_event_id TEXT,
        patient_uid   TEXT NOT NULL,
        patient_name  TEXT,
        user_id       TEXT,
        reason        TEXT NOT NULL,
        occurred_at   TEXT NOT NULL,
        is_synced     INTEGER NOT NULL DEFAULT 0,
        owner_user_id TEXT,
        organization_id TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_emlog_owner ON '
      '$_emergencyLogTable (owner_user_id)',
    );
  }

  Future<void> recordNfcKeyVersion({
    required String deviceUid,
    required String deviceRole,
    required int keyVersion,
    bool hadHeader = false,
  }) async {
    if (deviceUid.isEmpty) return;

    final row = <String, Object?>{
      'device_uid': deviceUid,
      'device_role': deviceRole,
      'key_version': keyVersion,
      'had_header': hadHeader ? 1 : 0,
      'observed_at': DateTime.now().toUtc().toIso8601String(),
      'is_synced': 0,
    };

    try {
      final db = await _database;
      if (db == null) {
        await _withWebLock(() => _webPutKeyVersionRow(deviceUid, row));
        return;
      }
      await db.insert(
        _keyVersionTable,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo registrar la versión de llave NFC observada',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<List<Map<String, Object?>>> pendingNfcKeyVersions() async {
    try {
      final db = await _database;
      if (db == null) {
        return (await _webAllKeyVersionRows())
            .where(
              (Map<String, Object?> r) =>
                  (r['is_synced'] as num?)?.toInt() == 0,
            )
            .toList();
      }
      return await db.query(_keyVersionTable, where: 'is_synced = 0');
    } catch (e, stack) {
      AppLogger.e(
        'No se pudieron leer las versiones de llave NFC pendientes',
        error: e,
        stackTrace: stack,
      );
      return <Map<String, Object?>>[];
    }
  }

  Future<void> markNfcKeyVersionsSynced(List<String> deviceUids) async {
    if (deviceUids.isEmpty) return;
    try {
      final db = await _database;
      if (db == null) {
        await _withWebLock(() async {
          for (final String uid in deviceUids) {
            final rows = await _webAllKeyVersionRows();
            for (final r in rows) {
              if (r['device_uid'] == uid) {
                await _webPutKeyVersionRow(uid, <String, Object?>{
                  ...r,
                  'is_synced': 1,
                });
              }
            }
          }
        });
        return;
      }
      await db.update(
        _keyVersionTable,
        <String, Object?>{'is_synced': 1},
        where:
            'device_uid IN (${List<String>.filled(deviceUids.length, '?').join(',')})',
        whereArgs: deviceUids,
      );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudieron marcar como sincronizadas las versiones de llave NFC',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> logEmergencyAccess({
    required String patientUid,
    String? patientName,
    String? userId,
    String reason = 'guardian_absent_offline',
    String? ownerUserId,
    String? organizationId,
  }) async {
    final row = <String, Object?>{
      'client_event_id': const Uuid().v4(),
      'patient_uid': patientUid,
      'patient_name': patientName == null
          ? null
          : await _encryptAuditPayload(patientName),
      'user_id': userId == null ? null : await _encryptAuditPayload(userId),
      'reason': reason,
      'occurred_at': toIso8601WithOffset(DateTime.now()),
      'is_synced': 0,
      'owner_user_id': ownerUserId,
      'organization_id': organizationId,
    };
    try {
      final db = await _database;
      if (db == null) {
        await _withWebLock(() async {
          final id = _newWebLocalId();
          await _webPutLogRow(id, <String, Object?>{...row, 'id': id});
        });
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

  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs({
    String? ownerUserId,
  }) async {
    final db = await _database;
    final rows = db == null
        ? (await _webAllLogRows())
              .where(
                (Map<String, Object?> r) =>
                    (r['is_synced'] as num?)?.toInt() == 0 &&
                    (ownerUserId == null ||
                        r['owner_user_id'] == null ||
                        r['owner_user_id'] == ownerUserId),
              )
              .toList()
        : await db.query(
            _emergencyLogTable,
            where: ownerUserId != null
                ? 'is_synced = 0 AND (owner_user_id = ? OR owner_user_id IS NULL)'
                : 'is_synced = 0',
            whereArgs: ownerUserId != null ? [ownerUserId] : null,
          );

    final out = <Map<String, Object?>>[];
    for (final r in rows) {
      final mutable = Map<String, Object?>.from(r);
      final int? id = (mutable['id'] as num?)?.toInt();
      final uId = mutable['user_id'] as String?;
      if (uId != null && uId.isNotEmpty) {
        final decryptedUserId = await _decryptAuditPayload(uId);
        if (decryptedUserId == '[CORRUPTED_KEY_MISSING]') {
          throw AuditDecryptionException(id ?? 0);
        }
        mutable['user_id'] = decryptedUserId;
      }
      if (ownerUserId != null && mutable['owner_user_id'] == null) {
        final actor = mutable['user_id'] as String?;
        if (actor != null && actor.isNotEmpty && actor != ownerUserId) {
          continue;
        }
        await _adoptEmergencyLog(id, ownerUserId);
        mutable['owner_user_id'] = ownerUserId;
      }
      final existingCid = mutable['client_event_id'] as String?;
      if (existingCid == null || existingCid.isEmpty) {
        final cid = const Uuid().v4();
        mutable['client_event_id'] = cid;
        await _persistEmergencyClientEventId(id, cid);
      }
      final name = mutable['patient_name'] as String?;
      if (name != null && name.isNotEmpty) {
        final decryptedName = await _decryptAuditPayload(name);
        if (decryptedName == '[CORRUPTED_KEY_MISSING]') {
          throw AuditDecryptionException(id ?? 0);
        }
        mutable['patient_name'] = decryptedName;
      }
      out.add(mutable);
    }
    return out;
  }

  Future<void> _adoptEmergencyLog(int? id, String ownerUserId) async {
    if (id == null) return;
    if (_isWeb) {
      await _withWebLock(() async {
        final row = await _webGetLogRow(id);
        if (row == null || row['owner_user_id'] != null) return;
        row['owner_user_id'] = ownerUserId;
        await _webPutLogRow(id, row);
      });
      return;
    }
    final db = await _database;
    await db?.update(
      _emergencyLogTable,
      <String, Object?>{'owner_user_id': ownerUserId},
      where: 'id = ? AND owner_user_id IS NULL',
      whereArgs: [id],
    );
  }

  Future<int> getOrphanedEmergencyLogCount() async {
    if (_isWeb) {
      final logs = await _webAllLogRows();
      return logs
          .where(
            (r) =>
                ((r['is_synced'] as num?)?.toInt() ?? 0) == 0 &&
                r['owner_user_id'] == null,
          )
          .length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_emergencyLogTable '
      'WHERE is_synced = 0 AND owner_user_id IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _persistEmergencyClientEventId(int? id, String cid) async {
    if (id == null) return;
    if (_isWeb) {
      await _withWebLock(() async {
        final row = await _webGetLogRow(id);
        if (row == null) return;
        row['client_event_id'] = cid;
        await _webPutLogRow(id, row);
      });
      return;
    }
    final db = await _database;
    await db?.update(
      _emergencyLogTable,
      <String, Object?>{'client_event_id': cid},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markEmergencyLogsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    if (_isWeb) {
      await _withWebLock(() async {
        for (final id in ids) {
          final row = await _webGetLogRow(id);
          if (row == null) continue;
          row['is_synced'] = 1;
          await _webPutLogRow(id, row);
        }
      });
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
  final Map<String, Future<void>> _patientSaveQueues = <String, Future<void>>{};

  Future<void> savePatient(
    PatientFullRecord record, {
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
    bool isSynced = false,
  }) {
    final String patientId = record.patientId;

    final Future<void> previous =
        _patientSaveQueues[patientId] ?? Future<void>.value();
    final Completer<void> ticket = Completer<void>();
    _patientSaveQueues[patientId] = ticket.future;

    return _runQueuedSave(
      previous: previous,
      ticket: ticket,
      patientId: patientId,
      record: record,
      ownerUserId: ownerUserId,
      organizationId: organizationId,
      retiredDeviceReason: retiredDeviceReason,
      isSynced: isSynced,
    );
  }

  Future<void> _runQueuedSave({
    required Future<void> previous,
    required Completer<void> ticket,
    required String patientId,
    required PatientFullRecord record,
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
    bool isSynced = false,
  }) async {
    await previous.catchError((_) {});
    try {
      await _savePatientNow(
        record,
        ownerUserId: ownerUserId,
        organizationId: organizationId,
        retiredDeviceReason: retiredDeviceReason,
        isSynced: isSynced,
      );
    } finally {
      ticket.complete();
      if (identical(_patientSaveQueues[patientId], ticket.future)) {
        await _patientSaveQueues.remove(patientId);
      }
    }
  }

  Future<void> _savePatientNow(
    PatientFullRecord record, {
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
    bool isSynced = false,
  }) async {
    final rawJson = jsonEncode(record.toJson());
    final encryptedJson = await _encryptPayload(rawJson);

    String createdAt = DateTime.now().toIso8601String();
    int revision = 0;

    final maskedNameStr = _maskName(record.patientInfo.fullName);

    if (_isWeb) {
      await _withWebLock(() async {
        final previous = await _webGetPatient(record.patientId);
        final effectiveOwner = ownerUserId ?? previous?['owner_user_id'];
        if (effectiveOwner == null) {
          AppLogger.e(
            'savePatient(${record.patientId}) llamado sin ownerUserId: la fila '
            'quedará sin propietario y no se sincronización ni se mostrará en '
            'ninguna consulta filtrada por usuario hasta que se reconcilie.',
          );
        }
        if (previous != null) {
          createdAt = previous['created_at'] as String;
          revision = ((previous['revision'] as int?) ?? 0) + 1;
        }
        final row = <String, dynamic>{
          'patient_id': record.patientId,
          'device_uid': record.deviceUid,
          'patient_name': maskedNameStr,
          'record_json': encryptedJson,
          'is_synced': isSynced ? 1 : 0,
          'sync_error': null,
          'sync_error_code': null,
          'created_at': createdAt,
          'synced_at': isSynced ? DateTime.now().toIso8601String() : null,
          'revision': revision,
          'owner_user_id': effectiveOwner,
          'organization_id': organizationId ?? previous?['organization_id'],
          'pending_retired_reason':
              retiredDeviceReason ?? previous?['pending_retired_reason'],
        };
        await _webPutPatient(record.patientId, row);
      });
      return;
    }

    final db = await _database;

    await db!.transaction((txn) async {
      final existing = await txn.query(
        _table,
        columns: [
          'created_at',
          'revision',
          'owner_user_id',
          'organization_id',
          'pending_retired_reason',
        ],
        where: 'patient_id = ?',
        whereArgs: [record.patientId],
        limit: 1,
      );

      String? prevOwner = ownerUserId;
      String? prevOrg = organizationId;
      String? reason = retiredDeviceReason;

      if (existing.isNotEmpty) {
        final prevCreatedAt = existing.first['created_at'] as String?;
        if (prevCreatedAt != null) createdAt = prevCreatedAt;
        revision = ((existing.first['revision'] as int?) ?? 0) + 1;
        prevOwner ??= existing.first['owner_user_id'] as String?;
        prevOrg ??= existing.first['organization_id'] as String?;
        reason ??= existing.first['pending_retired_reason'] as String?;
      }

      if (prevOwner == null) {
        AppLogger.e(
          'savePatient(${record.patientId}) llamado sin ownerUserId: la fila '
          'quedará sin propietario y no se sincronizará ni se mostrará en '
          'ninguna consulta filtrada por usuario hasta que se reconcilie.',
        );
      }

      final row = <String, dynamic>{
        'patient_id': record.patientId,
        'device_uid': record.deviceUid,
        'patient_name': maskedNameStr,
        'record_json': encryptedJson,
        'is_synced': isSynced ? 1 : 0,
        'sync_error': null,
        'sync_error_code': null,
        'created_at': createdAt,
        'synced_at': isSynced ? DateTime.now().toIso8601String() : null,
        'revision': revision,
        'owner_user_id': prevOwner,
        'organization_id': prevOrg,
        'pending_retired_reason': reason,
      };

      await txn.insert(
        _table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<List<LocalPatientEntry>> getUnsyncedRecords({
    String? ownerUserId,
  }) async {
    if (_isWeb) {
      final entries = <LocalPatientEntry>[];
      final store = await _webAllPatients();
      for (final r in store.where(
        (r) =>
            (r['is_synced'] as int) == 0 &&
            (ownerUserId == null ||
                r['owner_user_id'] == null ||
                r['owner_user_id'] == ownerUserId),
      )) {
        try {
          final decryptedJson = await _decryptPayload(
            r['record_json'] as String,
          );
          final row = Map<String, dynamic>.from(r);
          row['record_json'] = decryptedJson;
          entries.add(LocalPatientEntry.fromRow(row));
        } catch (e, stack) {
          AppLogger.e(
            'Fallo al descifrar fila web para ${r['patient_id']}',
            error: e,
            stackTrace: stack,
          );
        }
      }
      return entries..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final db = await _database;
    final String whereClause = ownerUserId != null
        ? 'is_synced = 0 AND (owner_user_id = ? OR owner_user_id IS NULL)'
        : 'is_synced = 0';
    final List<Object> whereArgs = ownerUserId != null ? [ownerUserId] : [];

    final rows = await db!.query(
      _table,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );

    final entries = <LocalPatientEntry>[];
    for (final row in rows) {
      try {
        final mutableRow = Map<String, dynamic>.from(row);
        mutableRow['record_json'] = await _decryptPayload(
          row['record_json'] as String,
        );
        entries.add(LocalPatientEntry.fromRow(mutableRow));
      } catch (e, stack) {
        AppLogger.e(
          'Fallo al descifrar fila SQLite para ${row['patient_id']}',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return entries;
  }

  Future<List<LocalPatientEntry>> getAllRecords({String? ownerUserId}) async {
    if (_isWeb) {
      final entries = <LocalPatientEntry>[];
      final store = await _webAllPatients();
      for (final r in store.where(
        (r) =>
            ownerUserId == null ||
            r['owner_user_id'] == null ||
            r['owner_user_id'] == ownerUserId,
      )) {
        try {
          final decryptedJson = await _decryptPayload(
            r['record_json'] as String,
          );
          final row = Map<String, dynamic>.from(r);
          row['record_json'] = decryptedJson;
          entries.add(LocalPatientEntry.fromRow(row));
        } catch (e, stack) {
          AppLogger.e(
            'Fallo al descifrar fila web para ${r['patient_id']}',
            error: e,
            stackTrace: stack,
          );
        }
      }
      return entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await _database;
    final String? whereClause = ownerUserId != null
        ? 'owner_user_id = ? OR owner_user_id IS NULL'
        : null;
    final List<Object>? whereArgs = ownerUserId != null ? [ownerUserId] : null;

    final rows = await db!.query(
      _table,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final entries = <LocalPatientEntry>[];
    for (final row in rows) {
      try {
        final mutableRow = Map<String, dynamic>.from(row);
        mutableRow['record_json'] = await _decryptPayload(
          row['record_json'] as String,
        );
        entries.add(LocalPatientEntry.fromRow(mutableRow));
      } catch (e, stack) {
        AppLogger.e(
          'Fallo al descifrar fila SQLite para ${row['patient_id']}',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return entries;
  }

  Future<int> getUnsyncedCount({String? ownerUserId}) async {
    if (_isWeb) {
      final store = await _webAllPatients();
      return store
          .where(
            (r) =>
                (r['is_synced'] as int) == 0 &&
                (ownerUserId == null ||
                    r['owner_user_id'] == null ||
                    r['owner_user_id'] == ownerUserId),
          )
          .length;
    }
    final db = await _database;
    final String sql = ownerUserId != null
        ? 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 AND (owner_user_id = ? OR owner_user_id IS NULL)'
        : 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0';
    final List<Object> args = ownerUserId != null ? [ownerUserId] : [];

    final result = await db!.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedEmergencyLogCount({String? ownerUserId}) async {
    if (_isWeb) {
      final logs = await _webAllLogRows();
      return logs
          .where(
            (r) =>
                ((r['is_synced'] as num?)?.toInt() ?? 0) == 0 &&
                (ownerUserId == null ||
                    r['owner_user_id'] == null ||
                    r['owner_user_id'] == ownerUserId),
          )
          .length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      ownerUserId != null
          ? 'SELECT COUNT(*) as cnt FROM $_emergencyLogTable '
                'WHERE is_synced = 0 AND (owner_user_id = ? OR owner_user_id IS NULL)'
          : 'SELECT COUNT(*) as cnt FROM $_emergencyLogTable WHERE is_synced = 0',
      ownerUserId != null ? [ownerUserId] : [],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getOrphanedPendingCount() async {
    if (_isWeb) {
      final store = await _webAllPatients();
      return store
          .where(
            (r) => (r['is_synced'] as int) == 0 && r['owner_user_id'] == null,
          )
          .length;
    }
    final db = await _database;
    final result = await db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table '
      'WHERE is_synced = 0 AND owner_user_id IS NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getRetryablePendingCount({String? ownerUserId}) async {
    if (_isWeb) {
      final store = await _webAllPatients();
      return store.where((r) {
        if ((r['is_synced'] as int) != 0) return false;
        if (ownerUserId != null &&
            r['owner_user_id'] != null &&
            r['owner_user_id'] != ownerUserId) {
          return false;
        }
        final code = r['sync_error_code'] as int?;
        return code == null || !kPermanentSyncErrorCodes.contains(code);
      }).length;
    }
    final db = await _database;
    final String sql = ownerUserId != null
        ? 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
              'AND (owner_user_id = ? OR owner_user_id IS NULL) '
              'AND (sync_error_code IS NULL OR sync_error_code NOT IN ($_permanentCodesSql))'
        : 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
              'AND (sync_error_code IS NULL OR sync_error_code NOT IN ($_permanentCodesSql))';
    final List<Object> args = ownerUserId != null ? [ownerUserId] : [];

    final result = await db!.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getBlockedCount({String? ownerUserId}) async {
    if (_isWeb) {
      final store = await _webAllPatients();
      return store.where((r) {
        if ((r['is_synced'] as int) != 0) return false;
        if (ownerUserId != null &&
            r['owner_user_id'] != null &&
            r['owner_user_id'] != ownerUserId) {
          return false;
        }
        final code = r['sync_error_code'] as int?;
        return code != null && kPermanentSyncErrorCodes.contains(code);
      }).length;
    }
    final db = await _database;
    final String sql = ownerUserId != null
        ? 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
              'AND (owner_user_id = ? OR owner_user_id IS NULL) '
              'AND sync_error_code IN ($_permanentCodesSql)'
        : 'SELECT COUNT(*) as cnt FROM $_table WHERE is_synced = 0 '
              'AND sync_error_code IN ($_permanentCodesSql)';
    final List<Object> args = ownerUserId != null ? [ownerUserId] : [];

    final result = await db!.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Sync lifecycle ────────────────────────────────────────────────────────

  Future<void> markSynced(
    String patientId, {
    String? createdAt,
    String? recordJson,
    int? revision,
  }) async {
    if (_isWeb) {
      await _withWebLock(() async {
        final current = await _webGetPatient(patientId);
        if (current == null) return;
        if (revision != null &&
            ((current['revision'] as int?) ?? 0) != revision) {
          return;
        }
        await _webDeletePatient(patientId);
      });
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
    int? revision,
  }) async {
    if (_isWeb) {
      await _withWebLock(() async {
        final current = await _webGetPatient(patientId);
        if (current == null) return;
        if (revision != null &&
            ((current['revision'] as int?) ?? 0) != revision) {
          return;
        }
        final updated = <String, dynamic>{
          ...current,
          'sync_error': error,
          'sync_error_code': statusCode,
        };
        await _webPutPatient(patientId, updated);
      });
      return;
    }
    final db = await _database;
    if (revision != null) {
      await db!.update(
        _table,
        <String, dynamic>{'sync_error': error, 'sync_error_code': statusCode},
        where: 'patient_id = ? AND revision = ?',
        whereArgs: <Object>[patientId, revision],
      );
    } else {
      await db!.update(
        _table,
        <String, dynamic>{'sync_error': error, 'sync_error_code': statusCode},
        where: 'patient_id = ?',
        whereArgs: <String>[patientId],
      );
    }
  }

  /// Moves a pending row the server already saved onto the version it was
  /// saved as, so its retry is not taken for an old copy.
  ///
  /// Only while the row still holds [revision], that is, exactly what was
  /// sent: a later edit keeps its own base.
  Future<void> rebasePending(
    String patientId, {
    required int revision,
    required int recordVersion,
  }) async {
    Future<String> withVersion(String cipher) async {
      final Map<String, dynamic> record =
          jsonDecode(await _decryptPayload(cipher)) as Map<String, dynamic>;
      record['baseVersion'] = recordVersion;
      return _encryptPayload(jsonEncode(record));
    }

    if (_isWeb) {
      await _withWebLock(() async {
        final current = await _webGetPatient(patientId);
        if (current == null ||
            ((current['revision'] as int?) ?? 0) != revision) {
          return;
        }
        await _webPutPatient(patientId, <String, dynamic>{
          ...current,
          'record_json': await withVersion(current['record_json'] as String),
        });
      });
      return;
    }
    final db = await _database;
    final rows = await db!.query(
      _table,
      columns: <String>['record_json'],
      where: 'patient_id = ? AND revision = ?',
      whereArgs: <Object>[patientId, revision],
      limit: 1,
    );
    if (rows.isEmpty) return;
    await db.update(
      _table,
      <String, Object?>{
        'record_json': await withVersion(rows.first['record_json'] as String),
      },
      where: 'patient_id = ? AND revision = ?',
      whereArgs: <Object>[patientId, revision],
    );
  }

  Future<void> deleteRecord(String patientId) async {
    if (_isWeb) {
      await _withWebLock(() async {
        await _webDeletePatient(patientId);
      });
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
      final r = await _webGetChipRow(patientId);
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
      await _withWebLock(() async {
        await _webPutChipRow(status.patientId, row);
      });
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
      await _withWebLock(() async {
        await _webDeleteChipRow(patientId);
      });
      return;
    }
    final db = await _database;
    await db!.delete(
      _chipStatusTable,
      where: 'patient_id = ?',
      whereArgs: <String>[patientId],
    );
  }

  // ── Sync notices ──────────────────────────────────────────────────────────

  /// Keeps what the server did not apply on a sync it accepted, until the
  /// user dismisses it. One notice per patient: a later sync adds its codes.
  ///
  /// The sync itself already succeeded, so a failure here is only logged.
  Future<void> addSyncNotice({
    required String patientId,
    required String patientName,
    required List<String> codes,
    String? ownerUserId,
  }) async {
    if (patientId.isEmpty || codes.isEmpty) return;

    Map<String, Object?> row(Map<String, Object?>? previous) =>
        <String, Object?>{
          'patient_id': patientId,
          'patient_name': _maskName(patientName),
          'codes': jsonEncode(
            <String>{
              ...SyncNotice.decodeCodes(previous?['codes']),
              ...codes,
            }.toList(),
          ),
          'owner_user_id': ownerUserId ?? previous?['owner_user_id'],
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

    try {
      final db = await _database;
      if (db == null) {
        await _withWebLock(() async {
          final String key = '$_webNoticePrefix$patientId';
          final Map<String, dynamic>? previous = await _webReadJsonRecord(key);
          await _webSet(key, jsonEncode(row(previous)));
        });
        return;
      }
      await db.transaction((txn) async {
        final previous = await txn.query(
          _syncNoticeTable,
          where: 'patient_id = ?',
          whereArgs: <String>[patientId],
          limit: 1,
        );
        await txn.insert(
          _syncNoticeTable,
          row(previous.isEmpty ? null : previous.first),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo guardar el aviso de sincronización',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Notices not dismissed yet, newest first.
  Future<List<SyncNotice>> getSyncNotices({String? ownerUserId}) async {
    try {
      final db = await _database;
      final List<Map<String, Object?>> rows;
      if (db == null) {
        await _ensureWebMigrated();
        rows = <Map<String, Object?>>[];
        for (final e in await _webList(_webNoticePrefix)) {
          if (e.key.contains('::quarantine::')) continue;
          try {
            rows.add(Map<String, Object?>.from(jsonDecode(e.value) as Map));
          } catch (_) {}
        }
      } else {
        rows = await db.query(_syncNoticeTable);
      }
      return rows
          .where(
            (Map<String, Object?> r) =>
                ownerUserId == null ||
                r['owner_user_id'] == null ||
                r['owner_user_id'] == ownerUserId,
          )
          .map(SyncNotice.fromRow)
          .toList()
        ..sort(
          (SyncNotice a, SyncNotice b) => b.createdAt.compareTo(a.createdAt),
        );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudieron leer los avisos de sincronización',
        error: e,
        stackTrace: stack,
      );
      return const <SyncNotice>[];
    }
  }

  Future<void> dismissSyncNotice(String patientId) async {
    try {
      final db = await _database;
      if (db == null) {
        await _withWebLock(() => _webRemove('$_webNoticePrefix$patientId'));
        return;
      }
      await db.delete(
        _syncNoticeTable,
        where: 'patient_id = ?',
        whereArgs: <String>[patientId],
      );
    } catch (e, stack) {
      AppLogger.e(
        'No se pudo descartar el aviso de sincronización',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> clearAll() async {
    if (_isWeb) {
      await _withWebLock(() async {
        await _webDeleteByPrefix(_webPatientPrefix);
        await _webDeleteByPrefix(_webChipPrefix);
        await _webDeleteByPrefix(_webNoticePrefix);
        await _webRemove(_webStoreKey);
        await _webRemove(_webChipKey);

        final allLogs = await _webAllLogRows();
        for (final row in allLogs) {
          final isSynced =
              row['is_synced'] == 1 ||
              row['is_synced'] == '1' ||
              (row['is_synced'] as num?)?.toInt() == 1;
          if (!isSynced) continue;
          final id = (row['id'] as num?)?.toInt();
          if (id != null) {
            await _webRemove('$_webLogPrefix$id');
          }
        }
      });
      return;
    }
    final db = await _database;
    await db!.delete(_table);
    await db.delete(_chipStatusTable);
    await db.delete(_syncNoticeTable);
    await db.delete(_emergencyLogTable, where: 'is_synced = 1');
  }
}

/// What the server kept as it had it on a sync it accepted, waiting for the
/// user to read it (see [LocalDatabase.addSyncNotice]).
class SyncNotice {
  const SyncNotice({
    required this.patientId,
    required this.patientName,
    required this.codes,
    required this.createdAt,
  });

  factory SyncNotice.fromRow(Map<String, Object?> row) => SyncNotice(
    patientId: row['patient_id'] as String,
    patientName: (row['patient_name'] as String?) ?? '',
    codes: decodeCodes(row['codes']),
    createdAt: (row['created_at'] as String?) ?? '',
  );

  static List<String> decodeCodes(Object? raw) {
    if (raw is! String || raw.isEmpty) return const <String>[];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((dynamic c) => c.toString())
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  final String patientId;

  /// Masked as in the sync queue: first name and an initial.
  final String patientName;

  /// The `conflicts` codes, see SyncConflictCode.
  final List<String> codes;
  final String createdAt;
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
    this.ownerUserId,
    this.organizationId,
    this.retiredDeviceReason,
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
      ownerUserId: row['owner_user_id'] as String?,
      organizationId: row['organization_id'] as String?,
      retiredDeviceReason: row['pending_retired_reason'] as String?,
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
  final String? ownerUserId;
  final String? organizationId;
  final String? retiredDeviceReason;

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
