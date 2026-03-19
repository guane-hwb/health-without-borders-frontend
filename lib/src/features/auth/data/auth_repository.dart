import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'hwb_access_token';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  String? _cachedToken;

  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        return _cachedToken!;
      }

      try {
        final String? stored = await _secureStorage.read(key: _tokenKey);
        if (stored != null && stored.isNotEmpty) {
          _cachedToken = stored;
          return stored;
        }
      } catch (_) {
        // Some desktop builds can fail keychain access in local dev (-34018).
        // Fall back to in-memory token only.
      }
    }

    return _loginAndPersist();
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {
      // Ignore local secure storage failures in desktop dev.
    }
  }

  Future<String> _loginAndPersist() async {
    final Map<String, dynamic> data = await _apiClient.postForm(
      path: '/api/v1/login/access-token',
      form: <String, String>{
        'username': AppEnv.authEmail,
        'password': AppEnv.authPassword,
      },
    );

    final String? accessToken = data['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Backend login did not return an access token.');
    }

    _cachedToken = accessToken;
    try {
      await _secureStorage.write(key: _tokenKey, value: accessToken);
    } catch (_) {
      // Ignore keychain failures and keep using in-memory token.
    }
    return accessToken;
  }
}
