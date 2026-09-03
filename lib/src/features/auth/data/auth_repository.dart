// lib/src/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/nfc/nfc_keyring.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/user_session.dart';

class AuthRepository implements TokenProvider {
  AuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
    LocalDatabase? localDatabase,
  }) : _apiClient = apiClient,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             mOptions: MacOsOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             aOptions: AndroidOptions(),
             webOptions: WebOptions(useSessionStorage: true),
           ),
       _localDb = localDatabase ?? LocalDatabase.instance;

  @visibleForTesting
  static const String tokenKey = _tokenKey;
  @visibleForTesting
  static const String refreshKey = _refreshKey;
  @visibleForTesting
  static const String nfcKeyKey = _nfcKeyKey;
  @visibleForTesting
  static const String nfcKeyringKey = _nfcKeyringKey;
  @visibleForTesting
  static const String sessionKey = _sessionKey;
  @visibleForTesting
  static const String lastUserIdKey = _lastUserIdKey;

  static const String _tokenKey = 'hwb_access_token';
  static const String _refreshKey = 'hwb_refresh_token';
  static const String _nfcKeyKey = 'hwb_nfc_key';
  static const String _nfcKeyringKey = 'hwb_nfc_keyring';
  static const String _sessionKey = 'hwb_user_session';
  static const String _lastUserIdKey = 'hwb_last_user_id';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final LocalDatabase _localDb;

  String? _cachedToken;
  String? _cachedRefreshToken;
  String? _cachedNfcKey;
  NfcKeyring? _cachedKeyring;
  UserSession? _session;

  final ValueNotifier<UserSession?> _sessionNotifier =
      ValueNotifier<UserSession?>(null);
  ValueNotifier<UserSession?> get sessionNotifier => _sessionNotifier;

  Future<String?>? _refreshInFlight;

  final ValueNotifier<bool> _sessionExpired = ValueNotifier<bool>(false);
  ValueListenable<bool> get sessionExpired => _sessionExpired;

  UserSession? get currentUser => _session;

  void _updateSession(UserSession? session) {
    _session = session;
    _sessionNotifier.value = session;
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
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

    final String? refreshToken = tokenData['refresh_token']?.toString();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _cachedRefreshToken = refreshToken;
      try {
        await _secureStorage.write(key: _refreshKey, value: refreshToken);
      } catch (_) {}
    }

    await _absorbKeyring(tokenData);

    String? lastUserId;
    try {
      lastUserId = await _secureStorage.read(key: _lastUserIdKey);
    } catch (_) {}

    final fetchedSession = await _fetchMe(accessToken);
    _updateSession(fetchedSession);

    if (lastUserId != null &&
        lastUserId.isNotEmpty &&
        lastUserId != _session!.id) {
      final int pendingPatients = await _localDb.getUnsyncedCount();
      final int pendingEmergencyLogs = await _localDb
          .getUnsyncedEmergencyLogCount();
      if (pendingPatients == 0 && pendingEmergencyLogs == 0) {
        await _localDb.clearAll();
        await _localDb.destroyEncryptionKey();
      } else {
        AppLogger.e(
          'Cambio de usuario detectado (de $lastUserId a ${_session!.id}). '
          'Quedan $pendingPatients registro(s) y $pendingEmergencyLogs '
          'acceso(s) de emergencia pendiente(s) en el dispositivo: '
          'se conservan sin borrar.',
        );
      }
    }

    if (_session!.id.isNotEmpty) {
      await _persistSession(_session!);
      try {
        await _secureStorage.write(key: _lastUserIdKey, value: _session!.id);
      } catch (_) {}
    }

    return _session!;
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<UserSession?> getCurrentUser() async {
    if (_session != null) return _session;
    try {
      final token = await getAccessToken();
      _updateSession(await _fetchMe(token));
    } catch (_) {}
    return _session;
  }

  Future<UserSession?> restoreSession() async {
    if (_session != null) return _session;

    final String? token = await _readStoredToken();
    if (token == null || token.isEmpty) return null;
    _cachedToken = token;

    final UserSession? persisted = await _readPersistedSession();
    if (persisted != null) {
      _updateSession(persisted);
      return _session;
    }

    try {
      final UserSession fetched = await _fetchMe(token);
      _updateSession(fetched);
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
      if (e.statusCode == 401) {
        await _invalidateSession();
        return null;
      }
      rethrow;
    }

    final String? newAccess = data['access_token']?.toString();
    if (newAccess == null || newAccess.isEmpty) return null;

    _cachedToken = newAccess;
    try {
      await _secureStorage.write(key: _tokenKey, value: newAccess);
    } catch (_) {}

    final String? newRefresh = data['refresh_token']?.toString();
    if (newRefresh != null && newRefresh.isNotEmpty) {
      _cachedRefreshToken = newRefresh;
      try {
        await _secureStorage.write(key: _refreshKey, value: newRefresh);
      } catch (_) {}
    }

    // /login/refresh carries the keyring as well, so a silent refresh picks up
    // a rotated current version without waiting for the next full login.
    await _absorbKeyring(data);

    return newAccess;
  }

  /// The full set of NFC keys this device holds, or null when none are known.
  ///
  /// Prefer this over [getNfcEncryptionKey] for anything that reads a chip: it
  /// carries every live key version, so a wristband written under an older key
  /// still decrypts while a rotation is in progress.
  Future<NfcKeyring?> getNfcKeyring() async {
    if (_cachedKeyring?.isNotEmpty == true) return _cachedKeyring;

    // Restored session / cold start: rebuild from storage.
    if (kIsWeb) return _cachedKeyring;
    try {
      final String? raw = await _secureStorage.read(key: _nfcKeyringKey);
      if (raw != null && raw.isNotEmpty) {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final NfcKeyring? restored = NfcKeyring.fromJson(decoded);
          if (restored != null && restored.isNotEmpty) {
            _cachedKeyring = restored;
            return restored;
          }
        }
      }
    } catch (_) {}

    // Upgrade path: a device provisioned by a build that predates versioning
    // holds a bare single key. Treat it as key version 0, which is exactly what
    // its already-written tags decrypt with.
    try {
      final String? legacy = await _secureStorage.read(key: _nfcKeyKey);
      if (legacy != null && legacy.isNotEmpty) {
        final NfcKeyring restored = NfcKeyring.single(legacy);
        _cachedKeyring = restored;
        return restored;
      }
    } catch (_) {}

    return null;
  }

  /// The single key new writes use. Kept for call sites that only encrypt.
  Future<String?> getNfcEncryptionKey() async {
    if (_cachedNfcKey?.isNotEmpty == true) return _cachedNfcKey;
    final NfcKeyring? keyring = await getNfcKeyring();
    final String? current = keyring?.currentKey;
    if (current != null && current.isNotEmpty) return current;
    if (kIsWeb) return null;
    try {
      return await _secureStorage.read(key: _nfcKeyKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout({bool wipeLocalData = false}) async {
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
    } finally {
      await clearSession();
      if (wipeLocalData) {
        await wipeLocalPhi();
      }
    }
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedNfcKey = null;
    _cachedKeyring = null;
    _updateSession(null);

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
      await _secureStorage.delete(key: _nfcKeyringKey);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _sessionKey);
    } catch (_) {}

    try {
      final int pendingPatients = await _localDb.getUnsyncedCount();
      final int pendingEmergencyLogs = await _localDb
          .getUnsyncedEmergencyLogCount();
      if (pendingPatients == 0 && pendingEmergencyLogs == 0) {
        await _localDb.destroyEncryptionKey();
      }
    } catch (_) {}
  }

  Future<bool> wipeLocalPhi({bool force = false}) async {
    try {
      if (!force) {
        final int pendingPatients = await _localDb.getUnsyncedCount();
        final int pendingEmergencyLogs = await _localDb
            .getUnsyncedEmergencyLogCount();
        if (pendingPatients > 0 || pendingEmergencyLogs > 0) {
          return false;
        }
      }
      await _localDb.clearAll();
      await _localDb.destroyEncryptionKey();
      return true;
    } catch (e, stack) {
      AppLogger.e('Error limpiando la base local', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> _invalidateSession() async {
    await clearSession();
    _sessionExpired.value = true;
  }

  bool get hasToken => _cachedToken?.isNotEmpty == true;

  // ── Private ───────────────────────────────────────────────────────────────

  /// Reads NFC key material out of a login, refresh, or `/users/me` body and
  /// makes it the device's keyring.
  ///
  /// Silently does nothing when the response carries no key material, so a
  /// response that omits it never clears a keyring the device already holds.
  Future<void> _absorbKeyring(Map<String, dynamic> data) async {
    final NfcKeyring? keyring = NfcKeyring.fromResponse(data);
    if (keyring == null || keyring.isEmpty) return;

    _cachedKeyring = keyring;
    _cachedNfcKey = keyring.currentKey;
    if (kIsWeb) return;

    try {
      await _secureStorage.write(
        key: _nfcKeyringKey,
        value: jsonEncode(keyring.toJson()),
      );
    } catch (_) {}

    // The bare single key is superseded by the ring; drop it so the same
    // material is not left in two places.
    try {
      await _secureStorage.delete(key: _nfcKeyKey);
    } catch (_) {}
  }

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
      await _absorbKeyring(data);
      return UserSession.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    } catch (_) {}

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
