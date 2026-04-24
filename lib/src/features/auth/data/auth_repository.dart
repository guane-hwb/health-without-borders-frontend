import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // ── Public API ──────────────────────────────────────────────────────────

  /// Login with explicit credentials (from the login form).
  /// Returns the raw JWT access token.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = await _apiClient.postForm(
      path: '/api/v1/login/access-token',
      form: <String, String>{
        'username': email,
        'password': password,
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
      // Ignore keychain failures; keep using in-memory token.
    }
    return accessToken;
  }

  /// Returns a valid token — reads from cache or secure storage.
  /// If [forceRefresh] is true, throws because we need credentials
  /// (the caller should redirect to the login screen on 401).
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
        // Some desktop builds can fail keychain access (-34018).
      }
    }

    // No valid token available — caller must redirect to login.
    throw ApiException(
      'Session expired. Please log in again.',
      statusCode: 401,
    );
  }

  /// Clears the current session (logout).
  Future<void> clearSession() async {
    _cachedToken = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {
      // Ignore secure storage failures in desktop dev.
    }
  }

  /// Whether there is a cached token available (does not validate expiry).
  bool get hasToken => _cachedToken != null && _cachedToken!.isNotEmpty;

  // ── JWT Decoding (local, no backend call) ───────────────────────────────

  /// Extracts the user role from the JWT payload.
  /// The backend encodes `sub` (email) in the JWT.  The role is fetched
  /// from the backend user object; for now we derive it from the email
  /// convention or from a separate /users/me endpoint in the future.
  ///
  /// Currently the backend JWT only contains `sub` and `exp`, so role-based
  /// UI adaptation will need a lightweight GET /users/me or embedding the
  /// role in the token.  This method is a placeholder that returns the
  /// email from the token.
  String? get currentEmail {
    if (_cachedToken == null) return null;
    try {
      final parts = _cachedToken!.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Map<String, dynamic> decoded =
          jsonDecode(payload) as Map<String, dynamic>;
      return decoded['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}