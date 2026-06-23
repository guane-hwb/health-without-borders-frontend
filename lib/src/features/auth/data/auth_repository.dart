// lib/src/features/auth/data/auth_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @visibleForTesting
  static const String tokenKey = _tokenKey;
  @visibleForTesting
  static const String refreshKey = _refreshKey;
  @visibleForTesting
  static const String nfcKeyKey = _nfcKeyKey;

  static const String _tokenKey = 'hwb_access_token';
  static const String _refreshKey = 'hwb_refresh_token';
  static const String _nfcKeyKey = 'hwb_nfc_key';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  String? _cachedToken;
  String? _cachedRefreshToken;
  UserSession? _session;

  /// The currently authenticated user. Null before login.
  UserSession? get currentUser => _session;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> tokenData = await _apiClient.postForm(
      path: '/api/v1/login/access-token',
      form: <String, String>{'username': email, 'password': password},
    );

    final String? accessToken = tokenData['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Login did not return an access token.');
    }

    _cachedToken = accessToken;
    try {
      await _secureStorage.write(key: _tokenKey, value: accessToken);
    } catch (_) {}

    // Persist the refresh token so the session can be terminated server-side
    // on logout (and, in the future, used to renew the access token).
    final String? refreshToken = tokenData['refresh_token']?.toString();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _cachedRefreshToken = refreshToken;
      try {
        await _secureStorage.write(key: _refreshKey, value: refreshToken);
      } catch (_) {}
    }

    // Store global NFC master key for offline NFC operations
    final nfcKey = tokenData['nfc_encryption_key']?.toString();
    if (nfcKey != null && nfcKey.isNotEmpty) {
      try {
        await _secureStorage.write(key: _nfcKeyKey, value: nfcKey);
      } catch (_) {}
    }
    _session = await _fetchMe(accessToken);
    return _session!;
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<UserSession?> getCurrentUser() async {
    if (_session != null) return _session;
    try {
      final token = await getAccessToken();
      _session = await _fetchMe(token);
    } catch (_) {}
    return _session;
  }

  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedToken?.isNotEmpty == true) return _cachedToken!;
    try {
      final stored = await _secureStorage.read(key: _tokenKey);
      if (stored?.isNotEmpty == true) {
        _cachedToken = stored;
        return stored!;
      }
    } catch (_) {}
    throw ApiException(
      'Session expired. Please log in again.',
      statusCode: 401,
    );
  }

  /// Returns the global NFC master key for encrypting/decrypting NFC payloads.
  /// Returns null if not available (user not logged in yet).
  Future<String?> getNfcEncryptionKey() async {
    try {
      return await _secureStorage.read(key: _nfcKeyKey);
    } catch (_) {
      return null;
    }
  }

  /// Ends the session on the server — revoking both the access token and, when
  /// available, the refresh token — and then clears the local session.
  ///
  /// Best-effort: any network or credential error is swallowed and the local
  /// session is cleared regardless, so the user is never left stranded as
  /// "logged in" on the device (e.g. when offline).
  Future<void> logout() async {
    try {
      final String? token =
          _cachedToken ?? await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        final String? refreshToken = await _getRefreshToken();
        await _apiClient.postJson(
          path: '/api/v1/logout',
          headers: <String, String>{'Authorization': 'Bearer $token'},
          body: <String, dynamic>{
            if (refreshToken != null && refreshToken.isNotEmpty)
              'refresh_token': refreshToken,
          },
        );
      }
    } catch (_) {
      // Ignore: clear the local session regardless of server reachability.
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _session = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _refreshKey);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _nfcKeyKey);
    } catch (_) {}
  }

  bool get hasToken => _cachedToken?.isNotEmpty == true;

  // ── Private ───────────────────────────────────────────────────────────────

  Future<String?> _getRefreshToken() async {
    if (_cachedRefreshToken?.isNotEmpty == true) return _cachedRefreshToken;
    try {
      final stored = await _secureStorage.read(key: _refreshKey);
      if (stored?.isNotEmpty == true) {
        _cachedRefreshToken = stored;
        return stored;
      }
    } catch (_) {}
    return null;
  }

  Future<UserSession> _fetchMe(String token) async {
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    try {
      final data = await _apiClient.getJson(
        path: '/api/v1/users/me',
        headers: headers,
      );
      return UserSession.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    } catch (_) {}
    // Fallback: email only from JWT
    final email = _emailFromJwt(token);
    return UserSession.fromEmail(email ?? 'user');
  }

  String? _emailFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return (jsonDecode(payload) as Map<String, dynamic>)['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}
