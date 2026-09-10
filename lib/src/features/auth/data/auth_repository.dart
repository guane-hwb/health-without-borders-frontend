// lib/src/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
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
             webOptions: WebOptions(useSessionStorage: false),
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

  /// How far the device clock may legitimately move backwards before it is
  /// treated as tampering rather than a correction.
  ///
  /// NTP corrections and timezone changes move the clock by minutes or hours;
  /// a day of slack absorbs those without letting someone reopen an expired
  /// window by setting the date back a week.
  static const Duration clockRollbackTolerance = Duration(hours: 24);

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final LocalDatabase _localDb;

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

  /// True when the session window has lapsed but the session was still
  /// restored locally.
  ///
  /// Distinct from [sessionExpired], which forces a return to the login
  /// screen: here the person keeps access to what is already on the device
  /// (pending records above all) while anything needing the network or an NFC
  /// key is refused until they reconnect.
  ValueListenable<bool> get sessionWindowClosed => _sessionWindowClosed;

  UserSession? get currentUser => _session;

  VoidCallback? onSessionInvalidated;

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
    _sessionWindowClosed.value = false;

    final Map<String, dynamic> tokenData = await _apiClient.postForm(
      path: '/api/v1/login/access-token',
      form: <String, String>{'username': email, 'password': password},
    );

    final String? accessToken = tokenData['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Login did not return an access token.');
    }

    final UserSession fetchedSession = await _fetchMe(accessToken);

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

    _updateSession(fetchedSession);

    if (_session!.id.isNotEmpty) {
      await _persistSession(_session!);
      try {
        await _secureStorage.write(key: _lastUserIdKey, value: _session!.id);
      } catch (_) {}
    }

    return _session!;
  }

  Future<List<LocalPatientEntry>> pendingForeignRecordsForReview() =>
      _localDb.getUnsyncedRecords();

  Future<List<Map<String, Object?>>> pendingForeignEmergencyLogsForReview() =>
      _localDb.pendingEmergencyAccessLogs();

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
    if (token == null || token.isEmpty) return null;
    _cachedToken = token;

    // Evaluate the window on restore instead of waiting for something to ask
    // for the keyring. Until now a cold start outside the window looked like a
    // healthy session and only NFC reported otherwise; and the key stayed on
    // disk for as long as nobody happened to call getNfcKeyring().
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

  /// Brings [sessionExpired] and the stored keyring in line with the window.
  ///
  /// The session is still restored when the window has closed: the device may
  /// hold unsynced records that the health worker needs to see, and forcing a
  /// logout could strand them behind the different-user guard. What it cannot
  /// do is act as if nothing happened, so the flag is raised and the key
  /// material is dropped now rather than whenever it is next requested.
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

    // A new refresh token means a new `exp`: the window is open again.
    _sessionWindowClosed.value = false;

    return newAccess;
  }

  /// The full set of NFC keys this device holds, or null when none are known.
  ///
  /// Carries every live key version, so a wristband written under an older key
  /// still decrypts while a rotation is in progress. Always build the codec
  /// from this rather than a single key: a codec built from a bare key stamps
  /// version 0 into the payload while encrypting with whatever the current key
  /// is, which after a rotation produces a chip no reader can decrypt.
  Future<NfcKeyring?> getNfcKeyring() async {
    // The keyring is only valid inside the session window. Checking here — the
    // one place the key is handed out — means no screen can bypass it, and the
    // check reads the refresh token's `exp` locally, so it still holds offline.
    if (!await _isSessionWindowOpen()) {
      await _forgetNfcKeyring();
      return null;
    }

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

  /// Whether NFC is unavailable because the session window closed, as opposed
  /// to no key ever having been delivered. Lets the NFC screens tell the user
  /// to log in again instead of reporting a reader failure.
  Future<bool> isNfcSessionExpired() async => !await _isSessionWindowOpen();

  /// Drops the keyring from memory and from disk.
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
      if (wipeLocalData) {
        await wipeLocalPhi();
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
      final int remainingLogs = await _localDb.getUnsyncedEmergencyLogCount();
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
    // clearSession() already drops the keyring from memory and disk.
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

  String? _emailFromJwt(String token) => _jwtPayload(token)?['sub']?.toString();

  /// Decodes a JWT's payload without verifying its signature.
  ///
  /// Reading a claim is not the same as trusting the token: verification needs
  /// the server's secret and is the backend's job. This is only used to read
  /// claims the device can act on locally — which is what makes the NFC key
  /// window work with no connectivity.
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

  /// The `exp` claim of [token] as a UTC instant, or null when unreadable.
  DateTime? _jwtExpiry(String token) {
    final Object? exp = _jwtPayload(token)?['exp'];
    final int? seconds = exp is int ? exp : int.tryParse(exp?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  /// Whether the refresh token still bounds a live session.
  ///
  /// The NFC keyring is only handed out inside this window. A device with no
  /// refresh token has no renewable session, so it is treated as outside the
  /// window rather than given the benefit of the doubt.
  Future<bool> _isSessionWindowOpen() async {
    final String? refreshToken = await _getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final DateTime? expiry = _jwtExpiry(refreshToken);
    // An unreadable refresh token cannot prove a live session either.
    if (expiry == null) return false;

    final DateTime now = DateTime.now().toUtc();
    if (await _clockMovedBackwards(now)) return false;
    await _recordClockMark(now);

    return now.isBefore(expiry);
  }

  /// Whether the device clock is behind the furthest point already observed by
  /// more than [clockRollbackTolerance].
  ///
  /// The window is judged against the device clock, so setting the date back
  /// would otherwise reopen an expired session. A stored high-water mark makes
  /// that visible: time is not supposed to run backwards.
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

  /// Moves the high-water mark forward. Never backwards, which is the point.
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
