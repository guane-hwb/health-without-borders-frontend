// lib/src/core/storage/web_storage_html.dart

// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getWebStorageItem(String key) {
  return html.window.localStorage[key];
}

void setWebStorageItem(String key, String value) {
  html.window.localStorage[key] = value;
}

void removeWebStorageItem(String key) {
  html.window.localStorage.remove(key);
}
