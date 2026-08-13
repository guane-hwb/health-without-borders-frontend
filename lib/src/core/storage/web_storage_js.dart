// lib/src/core/storage/web_storage_js.dart

import 'package:web/web.dart' as web;

String? getWebStorageItem(String key) => web.window.sessionStorage.getItem(key);

void setWebStorageItem(String key, String value) =>
    web.window.sessionStorage.setItem(key, value);

void removeWebStorageItem(String key) =>
    web.window.sessionStorage.removeItem(key);
