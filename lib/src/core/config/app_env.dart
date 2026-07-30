import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl {
    final rawUrl = _optional(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ).replaceFirst(RegExp(r'/$'), '');

    if (kReleaseMode && !rawUrl.startsWith('https://')) {
      throw StateError(
        'API_BASE_URL must use HTTPS in release mode. Received: $rawUrl',
      );
    }

    return rawUrl;
  }

  static String _optional(String key, {required String defaultValue}) {
    final String? value = _readEnvValue(key);
    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }
    return value.trim();
  }

  static String? _readEnvValue(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }
}
