// lib/src/features/auth/data/auth_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_session.dart';

class AuthRepository implements TokenProvider {
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
  @visibleForTesting
  static const String sessionKey = _sessionKey;

  static const String _tokenKey = 'hwb_access_token';
  static const String _refreshKey = 'hwb_refresh_token';
  static const String _nfcKeyKey = 'hwb_nfc_key';
  static const String _sessionKey = 'hwb_user_session';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  String? _cachedToken;
  String? _cachedRefreshToken;
  UserSession? _session;

  /// Guards against concurrent refreshes (single-flight). See
  /// [refreshAccessToken] for why this matters with a rotating backend.
  Future<String?>? _refreshInFlight;

  /// Flips to `true` when a refresh is authoritatively rejected by the backend
  /// (expired/revoked refresh token) — the session is over and the user must
  /// sign in again. A top-level listener routes to the login screen. Transient
  /// or offline refresh failures do NOT flip this: the work stays pending and
  /// the local-first UI is preserved.
  final ValueNotifier<bool> _sessionExpired = ValueNotifier<bool>(false);
  ValueListenable<bool> get sessionExpired => _sessionExpired;

  /// The currently authenticated user. Null before login.
  UserSession? get currentUser => _session;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    // A fresh sign-in clears any prior "session expired" state.
    _sessionExpired.value = false;

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
    // Persist the full profile so the session can be restored offline on the
    // next cold start with the correct role (see [restoreSession]).
    await _persistSession(_session!);
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

  /// Restores a previously authenticated session at app startup so the user is
  /// not bounced to the login screen when the OS kills the app — including when
  /// fully offline. Returns null when there is nothing to restore (no persisted
  /// token, or the user logged out), signalling the app to show login.
  ///
  /// Local-first: an EXPIRED access token does not block restoration. The UI is
  /// rebuilt from the persisted profile and the [ApiClient] interceptor renews
  /// the token on the first authenticated request once connectivity returns.
  Future<UserSession?> restoreSession() async {
    if (_session != null) return _session;

    // No persisted token => never logged in, or logged out. Nothing to restore.
    final String? token = await _readStoredToken();
    if (token == null || token.isEmpty) return null;
    _cachedToken = token;

    // Prefer the persisted profile: it carries the REAL role, so an admin or
    // nurse is restored as themselves rather than the doctor default that a
    // JWT-only session yields offline.
    final UserSession? persisted = await _readPersistedSession();
    if (persisted != null) {
      _session = persisted;
      return _session;
    }

    // No persisted profile (e.g. a session created before this feature shipped).
    // Fall back to /users/me, which itself degrades to a minimal JWT-derived
    // session when offline. Only persist a genuine profile (non-empty id), never
    // the JWT fallback, so a wrong role is never cached to disk.
    try {
      final UserSession fetched = await _fetchMe(token);
      _session = fetched;
      if (fetched.id.isNotEmpty) await _persistSession(fetched);
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

  /// Renews the access token using the stored refresh token, rotating both
  /// tokens on the server (`POST /api/v1/login/refresh`).
  ///
  /// Single-flight: concurrent 401s — e.g. a batch sync pushing many pending
  /// records at once — all share ONE refresh round-trip. This is not a nicety
  /// but a correctness requirement: the backend rotates refresh tokens (it
  /// revokes the old one when issuing a new pair), so a second concurrent
  /// refresh would present an already-revoked token and be rejected as a reuse
  /// attempt, tearing down the whole session.
  ///
  /// Returns the new access token, or `null` when the session is truly over
  /// (no refresh token, or the refresh token is expired/revoked). Transient
  /// failures (network / 5xx) are rethrown so the caller keeps its work pending
  /// instead of forcing a re-login.
  @override
  Future<String?> refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _performRefresh() async {
    final String? refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final Map<String, dynamic> data;
    try {
      data = await _apiClient.postJson(
        path: '/api/v1/login/refresh',
        body: <String, dynamic>{'refresh_token': refreshToken},
      );
    } on ApiException catch (e) {
      // 401 => refresh token expired or revoked => the session is definitively
      // over: clear it locally and signal the UI to route to login.
      if (e.statusCode == 401) {
        await _invalidateSession();
        return null;
      }
      // Transient error (network / 5xx): let the caller keep the work pending.
      rethrow;
    }

    final String? newAccess = data['access_token']?.toString();
    if (newAccess == null || newAccess.isEmpty) return null;

    _cachedToken = newAccess;
    try {
      await _secureStorage.write(key: _tokenKey, value: newAccess);
    } catch (_) {}

    // Persist the ROTATED refresh token. The previous one is now revoked
    // server-side, so failing to store the new one would break the next
    // refresh and strand the user at the login screen.
    final String? newRefresh = data['refresh_token']?.toString();
    if (newRefresh != null && newRefresh.isNotEmpty) {
      _cachedRefreshToken = newRefresh;
      try {
        await _secureStorage.write(key: _refreshKey, value: newRefresh);
      } catch (_) {}
    }

    return newAccess;
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
    try {
      await _secureStorage.delete(key: _sessionKey);
    } catch (_) {}
  }

  /// Forced sign-out when the backend rejects the refresh token. Clears the
  /// auth state (tokens + persisted profile) but intentionally leaves the local
  /// offline-first database untouched, so pending unsynced records survive the
  /// re-authentication. Idempotent: the notifier only fires on a real change.
  Future<void> _invalidateSession() async {
    await clearSession();
    _sessionExpired.value = true;
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

  Future<void> _persistSession(UserSession session) async {
    try {
      await _secureStorage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
      );
    } catch (_) {}
  }

  Future<UserSession?> _readPersistedSession() async {
    try {
      final String? raw = await _secureStorage.read(key: _sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserSession.fromJson(decoded);
    } catch (_) {
      // Corrupt or unreadable payload: ignore and let the caller re-fetch.
      return null;
    }
  }

  Future<String?> _readStoredToken() async {
    if (_cachedToken?.isNotEmpty == true) return _cachedToken;
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
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
