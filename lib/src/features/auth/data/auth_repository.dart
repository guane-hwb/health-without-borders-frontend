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

      final String? stored = await _secureStorage.read(key: _tokenKey);
      if (stored != null && stored.isNotEmpty) {
        _cachedToken = stored;
        return stored;
      }
    }

    return _loginAndPersist();
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _tokenKey);
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
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    return accessToken;
  }
}
