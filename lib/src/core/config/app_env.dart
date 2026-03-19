import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl => _optional(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  ).replaceFirst(RegExp(r'/$'), '');

  static String get authEmail => _required('API_AUTH_EMAIL');

  static String get authPassword => _required('API_AUTH_PASSWORD');

  static String _optional(String key, {required String defaultValue}) {
    final String? value = _readEnvValue(key);
    if (value == null || value.trim().isEmpty) {
      return defaultValue;
    }
    return value.trim();
  }

  static String _required(String key) {
    final String? value = _readEnvValue(key);
    if (value == null || value.trim().isEmpty) {
      throw StateError('Missing environment variable: $key');
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
