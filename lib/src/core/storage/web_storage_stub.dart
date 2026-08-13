// lib/src/core/storage/web_storage_stub.dart

import 'package:flutter/foundation.dart' show kIsWeb;

Never _unsupported() => throw UnsupportedError(
  'web_storage: se seleccionó el stub no-op estando en web. Revisa la '
  'importación condicional de web_storage.dart (predicado del target).',
);

String? getWebStorageItem(String key) => kIsWeb ? _unsupported() : null;

void setWebStorageItem(String key, String value) {
  if (kIsWeb) _unsupported();
}

void removeWebStorageItem(String key) {
  if (kIsWeb) _unsupported();
}
