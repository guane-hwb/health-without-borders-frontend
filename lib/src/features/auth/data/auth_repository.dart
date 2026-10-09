// lib/src/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_codes.dart';
import '../../../core/nfc/nfc_keyring.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/user_session.dart';

class ForeignPendingDataException implements Exception {
  ForeignPendingDataException({
    required this.previousOwnerUserId,
    required this.newUserId,
    required this.pendingPatients,
    required this.pendingEmergencyLogs,
  });

  final String previousOwnerUserId;
  final String newUserId;
  final int pendingPatients;
  final int pendingEmergencyLogs;

  @override
  String toString() =>
      'ForeignPendingDataException(previousOwner: $previousOwnerUserId, '
      'newUser: $newUserId, pendingPatients: $pendingPatients, '
      'pendingEmergencyLogs: $pendingEmergencyLogs)';
}

class AuthRepository implements TokenProvider {
  AuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
    LocalDatabase? localDatabase,
    bool? forceWeb,
  }) : _apiClient = apiClient,
       _forceWeb = forceWeb,
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
  static const String clockMarkKey = _clockMarkKey;
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
  static const String _clockMarkKey = 'hwb_clock_mark';

  static const Duration clockRollbackTolerance = Duration(hours: 24);

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final LocalDatabase _localDb;
  final bool? _forceWeb;

  bool get _isWeb => _forceWeb ?? kIsWeb;

  String? _cachedToken;
  String? _cachedRefreshToken;
  NfcKeyring? _cachedKeyring;
  DateTime? _cachedClockMark;
  UserSession? _session;

  final ValueNotifier<UserSession?> _sessionNotifier =
      ValueNotifier<UserSession?>(null);
  ValueNotifier<UserSession?> get sessionNotifier => _sessionNotifier;

  Future<String?>? _refreshInFlight;

  final ValueNotifier<bool> _sessionExpired = ValueNotifier<bool>(false);
  ValueListenable<bool> get sessionExpired => _sessionExpired;

  final ValueNotifier<bool> _sessionWindowClosed = ValueNotifier<bool>(false);

  ValueListenable<bool> get sessionWindowClosed => _sessionWindowClosed;

  final ValueNotifier<String?> _accountInactiveCode = ValueNotifier<String?>(
    null,
  );

  ValueListenable<String?> get accountInactiveCode => _accountInactiveCode;

  UserSession? get currentUser => _session;

  VoidCallback? onSessionInvalidated;

  Future<void> handleAccountInactive(String code) async {
    _accountInactiveCode.value = code;
    if (_session == null && !hasToken) return;
    await _invalidateSession();
  }

  void _updateSession(UserSession? session) {
    _session = session;
    _sessionNotifier.value = session;
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<UserSession> login({
    required String email,
    required String password,
    bool rememberSession = true,
  }) async {
    _sessionExpired.value = false;
    _sessionWindowClosed.value = false;
    _accountInactiveCode.value = null;

    final Map<String, dynamic> tokenData = await _apiClient.postForm(
      path: '/api/v1/login/access-token',
      form: <String, String>{'username': email, 'password': password},
    );

    final String? accessToken = tokenData['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Login did not return an access token.');
    }

    UserSession fetchedSession;
    try {
      fetchedSession = await _fetchMe(accessToken);
    } catch (e) {
      await clearSession();
      rethrow;
    }
    if (tokenData['must_change_password'] == true) {
      fetchedSession = fetchedSession.copyWith(mustChangePassword: true);
    }

    String? lastUserId;
    try {
      lastUserId = await _secureStorage.read(key: _lastUserIdKey);
    } catch (_) {}

    if (lastUserId != null &&
        lastUserId.isNotEmpty &&
        lastUserId != fetchedSession.id) {
      final int pendingPatients = await _localDb.getUnsyncedCount();
      final int pendingEmergencyLogs = await _localDb
          .getUnsyncedEmergencyLogCount();
      if (pendingPatients == 0 && pendingEmergencyLogs == 0) {
        await _localDb.clearAll();
        await _localDb.destroyEncryptionKey();
      } else {
        AppLogger.e(
          'Login bloqueado: cambio de usuario detectado (de $lastUserId a '
          '${fetchedSession.id}) con $pendingPatients registro(s) y '
          '$pendingEmergencyLogs acceso(s) de emergencia pendientes de '
          '$lastUserId aún en el dispositivo.',
        );
        throw ForeignPendingDataException(
          previousOwnerUserId: lastUserId,
          newUserId: fetchedSession.id,
          pendingPatients: pendingPatients,
          pendingEmergencyLogs: pendingEmergencyLogs,
        );
      }
    }

    _cachedToken = accessToken;
    if (rememberSession) {
      try {
        await _secureStorage.write(key: _tokenKey, value: accessToken);
      } catch (_) {}
    }

    final String? refreshToken = tokenData['refresh_token']?.toString();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _cachedRefreshToken = refreshToken;
      await _anchorClockMark(refreshToken);
      if (rememberSession) {
        try {
          await _secureStorage.write(key: _refreshKey, value: refreshToken);
        } catch (_) {}
      }
    }

    await _absorbKeyring(tokenData);

    _updateSession(fetchedSession);

    if (_session!.id.isNotEmpty && rememberSession) {
      await _persistSession(_session!);
      try {
        await _secureStorage.write(key: _lastUserIdKey, value: _session!.id);
      } catch (_) {}
    }

    return _session!;
  }

  Future<List<LocalPatientEntry>> pendingForeignRecordsForReview() =>
      _localDb.getUnsyncedRecords(ownerUserId: _session?.id);

  Future<List<Map<String, Object?>>> pendingForeignEmergencyLogsForReview() =>
      _localDb.pendingEmergencyAccessLogs(ownerUserId: _session?.id);

  Future<void> discardForeignPendingData() async {
    await _localDb.clearAll();
    await _localDb.destroyEncryptionKey();
    try {
      await _secureStorage.delete(key: _lastUserIdKey);
    } catch (_) {}
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
    if (token == null || token.isEmpty) {
      if (_isWeb) await wipeLocalPhi(force: true);
      return null;
    }
    _cachedToken = token;

    await _refreshSessionWindowState();

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

  Future<void> _refreshSessionWindowState() async {
    final bool open = await _isSessionWindowOpen();
    if (open) return;

    await _forgetNfcKeyring();
    _sessionWindowClosed.value = true;
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
        // A password change while this refresh was in flight revoked the
        // token it sent and stored a new pair: the session is fine.
        final String? current = _cachedRefreshToken;
        if (current != null && current.isNotEmpty && current != refreshToken) {
          return _cachedToken;
        }
        if (ApiErrorCode.isAccountInactive(e.code)) {
          _accountInactiveCode.value = e.code;
        }
        await _invalidateSession();
        return null;
      }
      rethrow;
    }

    final String? newAccess = await _adoptTokenPair(data);
    if (newAccess == null) return null;

    final UserSession? session = _session;
    final bool mustChange = data['must_change_password'] == true;
    if (session != null &&
        data.containsKey('must_change_password') &&
        session.mustChangePassword != mustChange) {
      _updateSession(session.copyWith(mustChangePassword: mustChange));
      if (session.id.isNotEmpty) await _persistSession(_session!);
    }

    _sessionWindowClosed.value = false;

    return newAccess;
  }

  // ── Password ──────────────────────────────────────────────────────────────

  /// Changes the signed-in user's password (POST /users/me/password).
  ///
  /// The server ends every session of the user, this device's included, and
  /// answers with a new token pair and NFC keyring: they replace the stored
  /// ones, or the next request would get a 401.
  ///
  /// Throws [ApiException]: 400 when the current password is wrong (or the
  /// new one equals it), 422 when the new one breaks the policy, 429 when the
  /// attempts are paused (`login_paused`, with `retryAfter`).
  Future<UserSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String token = await getAccessToken();
    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/users/me/password',
      headers: <String, String>{'Authorization': 'Bearer $token'},
      body: <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    if (await _adoptTokenPair(data) == null) {
      throw ApiException('The password change did not return a token.');
    }
    _sessionWindowClosed.value = false;

    final UserSession? session = _session;
    if (session != null) {
      _updateSession(
        session.copyWith(
          mustChangePassword: data['must_change_password'] == true,
        ),
      );
      if (session.id.isNotEmpty) await _persistSession(_session!);
    }
    return _session!;
  }

  Future<NfcKeyring?> getNfcKeyring() async {
    if (!await _isSessionWindowOpen()) {
      await _forgetNfcKeyring();
      return null;
    }

    if (_cachedKeyring?.isNotEmpty == true) return _cachedKeyring;

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

  Future<bool> isNfcSessionExpired() async => !await _isSessionWindowOpen();

  Future<void> _forgetNfcKeyring() async {
    _cachedKeyring = null;
    if (kIsWeb) return;
    try {
      await _secureStorage.delete(key: _nfcKeyringKey);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _nfcKeyKey);
    } catch (_) {}
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
      if (wipeLocalData || _isWeb) {
        await wipeLocalPhi(force: _isWeb);
      }
    }
  }

  Future<void> clearSession() async {
    try {
      onSessionInvalidated?.call();
    } catch (e, stack) {
      AppLogger.e(
        'Error deteniendo el motor de sync al invalidar la sesión',
        error: e,
        stackTrace: stack,
      );
    }

    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedKeyring = null;
    _cachedClockMark = null;
    _updateSession(null);

    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }

  Future<bool> wipeLocalPhi({bool force = false}) async {
    try {
      if (!force) {
        final int pendingPatients = await _localDb.getUnsyncedCount(
          ownerUserId: _session?.id,
        );
        final int pendingEmergencyLogs = await _localDb
            .getUnsyncedEmergencyLogCount(ownerUserId: _session?.id);
        if (pendingPatients > 0 || pendingEmergencyLogs > 0) {
          return false;
        }
      }
      await _localDb.clearAll();
      final int remainingLogs = await _localDb.getUnsyncedEmergencyLogCount(
        ownerUserId: _session?.id,
      );
      if (remainingLogs == 0 || force) {
        await _localDb.destroyEncryptionKey();
      }
      return true;
    } catch (e, stack) {
      AppLogger.e('Error limpiando la base local', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> _invalidateSession() async {
    await clearSession();
    if (_isWeb) await wipeLocalPhi(force: true);
    _sessionWindowClosed.value = false;
    _sessionExpired.value = true;
  }

  bool get hasToken => _cachedToken?.isNotEmpty == true;

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _absorbKeyring(Map<String, dynamic> data) async {
    final NfcKeyring? keyring = NfcKeyring.fromResponse(data);
    if (keyring == null || keyring.isEmpty) return;

    _cachedKeyring = keyring;
    if (kIsWeb) return;

    try {
      await _secureStorage.write(
        key: _nfcKeyringKey,
        value: jsonEncode(keyring.toJson()),
      );
    } catch (_) {}

    try {
      await _secureStorage.delete(key: _nfcKeyKey);
    } catch (_) {}
  }

  /// Stores the access and refresh tokens and the NFC keyring of a token
  /// pair response. Returns the access token, or null when there is none.
  Future<String?> _adoptTokenPair(Map<String, dynamic> data) async {
    final String? access = data['access_token']?.toString();
    if (access == null || access.isEmpty) return null;

    _cachedToken = access;
    try {
      await _secureStorage.write(key: _tokenKey, value: access);
    } catch (_) {}

    final String? refresh = data['refresh_token']?.toString();
    if (refresh != null && refresh.isNotEmpty) {
      _cachedRefreshToken = refresh;
      await _anchorClockMark(refresh);
      try {
        await _secureStorage.write(key: _refreshKey, value: refresh);
      } catch (_) {}
    }

    await _absorbKeyring(data);
    return access;
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
    final data = await _apiClient.getJson(
      path: '/api/v1/users/me',
      headers: headers,
    );
    await _absorbKeyring(data);
    return UserSession.fromJson(data);
  }

  Map<String, dynamic>? _jwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Object? decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  DateTime? _jwtIssuedAt(String token) => _jwtInstant(token, 'iat');

  DateTime? _jwtExpiry(String token) => _jwtInstant(token, 'exp');

  DateTime? _jwtInstant(String token, String claim) {
    final Object? value = _jwtPayload(token)?[claim];
    final int? seconds = value is int
        ? value
        : int.tryParse(value?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  Future<void> _anchorClockMark(String refreshToken) async {
    final DateTime? issuedAt = _jwtIssuedAt(refreshToken);
    if (issuedAt == null) return;

    _cachedClockMark = issuedAt;
    if (kIsWeb) return;
    try {
      await _secureStorage.write(
        key: _clockMarkKey,
        value: issuedAt.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
  }

  Future<bool> _isSessionWindowOpen() async {
    final String? refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final DateTime? expiry = _jwtExpiry(refreshToken);
    if (expiry == null) return false;

    final DateTime now = DateTime.now().toUtc();
    if (await _clockMovedBackwards(now)) return false;
    await _recordClockMark(now);

    return now.isBefore(expiry);
  }

  Future<bool> _clockMovedBackwards(DateTime now) async {
    final DateTime? mark = await _readClockMark();
    if (mark == null) return false;
    return now.isBefore(mark.subtract(clockRollbackTolerance));
  }

  Future<DateTime?> _readClockMark() async {
    if (kIsWeb) return _cachedClockMark;
    if (_cachedClockMark != null) return _cachedClockMark;
    try {
      final String? raw = await _secureStorage.read(key: _clockMarkKey);
      if (raw == null || raw.isEmpty) return null;
      final int? millis = int.tryParse(raw);
      if (millis == null) return null;
      _cachedClockMark = DateTime.fromMillisecondsSinceEpoch(
        millis,
        isUtc: true,
      );
      return _cachedClockMark;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordClockMark(DateTime now) async {
    final DateTime? mark = _cachedClockMark;
    if (mark != null && !now.isAfter(mark)) return;

    _cachedClockMark = now;
    if (kIsWeb) return;
    try {
      await _secureStorage.write(
        key: _clockMarkKey,
        value: now.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
  }
}
