// lib/src/core/storage/web_storage_stub.dart

Future<String?> getWebStorageItem(String key) async => null;

Future<void> setWebStorageItem(String key, String value) async {}

Future<void> removeWebStorageItem(String key) async {}

Future<void> clearAllWebStorage() async {}

Future<List<MapEntry<String, String>>> listWebStorageEntries(
  String prefix,
) async => const <MapEntry<String, String>>[];

Future<void> deleteWebStorageByPrefix(String prefix) async {}
