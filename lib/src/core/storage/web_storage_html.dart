// lib/src/core/storage/web_storage_html.dart

// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getWebStorageItem(String key) {
  return html.window.sessionStorage[key];
}

void setWebStorageItem(String key, String value) {
  html.window.sessionStorage[key] = value;
}

void removeWebStorageItem(String key) {
  html.window.sessionStorage.remove(key);
}
