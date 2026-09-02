// lib/src/core/storage/web_storage_js.dart

import 'dart:async';

import 'package:idb_shim/idb_browser.dart';

const String _dbName = 'hwb_local_store';
const String _storeName = 'kv';
const int _dbVersion = 1;

Database? _db;
Future<Database>? _dbOpening;

Future<Database> _openDb() {
  final Database? existing = _db;
  if (existing != null) return Future<Database>.value(existing);
  return _dbOpening ??= _doOpen();
}

Future<Database> _doOpen() async {
  final factory = getIdbFactory();
  if (factory == null) {
    throw StateError(
      'IndexedDB no está disponible en este navegador; no se puede '
      'persistir la cola offline ni la auditoría de emergencia en Web.',
    );
  }
  final Database db = await factory.open(
    _dbName,
    version: _dbVersion,
    onUpgradeNeeded: (VersionChangeEvent event) {
      final Database upgradingDb = event.database;
      if (!upgradingDb.objectStoreNames.contains(_storeName)) {
        upgradingDb.createObjectStore(_storeName);
      }
    },
  );
  _db = db;
  return db;
}

Future<String?> getWebStorageItem(String key) async {
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadOnly);
  final ObjectStore store = txn.objectStore(_storeName);
  final Object? value = await store.getObject(key);
  await txn.completed;
  if (value == null) return null;
  return value as String;
}

Future<void> setWebStorageItem(String key, String value) async {
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadWrite);
  final ObjectStore store = txn.objectStore(_storeName);
  await store.put(value, key);
  await txn.completed;
}

Future<void> removeWebStorageItem(String key) async {
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadWrite);
  final ObjectStore store = txn.objectStore(_storeName);
  await store.delete(key);
  await txn.completed;
}

Future<void> clearAllWebStorage() async {
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadWrite);
  final ObjectStore store = txn.objectStore(_storeName);
  await store.clear();
  await txn.completed;
}

Future<List<MapEntry<String, String>>> listWebStorageEntries(
  String prefix,
) async {
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadOnly);
  final ObjectStore store = txn.objectStore(_storeName);
  final KeyRange range = KeyRange.bound(prefix, '$prefix\uFFFF');
  final entries = <MapEntry<String, String>>[];
  await for (final cursor in store.openCursor(
    range: range,
    autoAdvance: true,
  )) {
    final Object key = cursor.key;
    final Object value = cursor.value;
    if (key is String && value is String) {
      entries.add(MapEntry<String, String>(key, value));
    }
  }
  await txn.completed;
  return entries;
}

Future<void> deleteWebStorageByPrefix(String prefix) async {
  final entries = await listWebStorageEntries(prefix);
  if (entries.isEmpty) return;
  final Database db = await _openDb();
  final Transaction txn = db.transaction(_storeName, idbModeReadWrite);
  final ObjectStore store = txn.objectStore(_storeName);
  for (final entry in entries) {
    await store.delete(entry.key);
  }
  await txn.completed;
}
