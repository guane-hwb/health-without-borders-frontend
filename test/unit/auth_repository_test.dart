// test/unit/auth_repository_test.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

String _buildJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  const sig = 'fakesig';
  return '$header.$body.$sig';
}

String _validJwt(String email) => _buildJwt({'sub': email, 'exp': 9999999999});

String _refreshJwt({int days = 7}) => _buildJwt({
  'sub': 'doc@hwb.org',
  'type': 'refresh',
  'iat': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
  'exp':
      DateTime.now().toUtc().add(Duration(days: days)).millisecondsSinceEpoch ~/
      1000,
});

Map<String, dynamic> _meResponse({String email = 'doc@hwb.org'}) => {
  'email': email,
  'id': '42',
  'role': 'doctor',
  'full_name': 'Doctor Test',
};

AuthRepository _makeRepo({
  required MockApiClient api,
  required MockSecureStorage storage,
  LocalDatabase? localDb,
  bool forceWeb = false,
}) => AuthRepository(
  apiClient: api,
  secureStorage: storage,
  localDatabase: localDb,
  forceWeb: forceWeb,
);

void main() {
  late MockApiClient api;
  late MockSecureStorage storage;
  late MockLocalDatabase localDb;
  late AuthRepository repo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    api = MockApiClient();
    storage = MockSecureStorage();
    localDb = MockLocalDatabase();
    repo = _makeRepo(
      api: api,
      storage: storage,
      localDb: localDb,
      forceWeb: false,
    );

    when(
      () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => 0);
    when(
      () => localDb.getUnsyncedEmergencyLogCount(
        ownerUserId: any(named: 'ownerUserId'),
      ),
    ).thenAnswer((_) async => 0);
    when(() => localDb.clearAll()).thenAnswer((_) async {});
    when(() => localDb.destroyEncryptionKey()).thenAnswer((_) async {});

    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => storage.deleteAll()).thenAnswer((_) async {});
  });

  group('la cola offline sobrevive al cierre de sesión', () {
    test('clearSession NUNCA borra la base local', () async {
      await repo.clearSession();
      verifyNever(() => localDb.clearAll());
    });

    test('logout() por defecto conserva la base local sin purgar', () async {
      await repo.logout();
      verifyNever(() => localDb.clearAll());
    });

    test('logout(wipeLocalData: true) no purga si quedan pendientes', () async {
      when(
        () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => 3);
      await repo.logout(wipeLocalData: true);
      verifyNever(() => localDb.clearAll());
    });

    test('logout(wipeLocalData: true) purga sólo con la cola vacía', () async {
      when(
        () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => 0);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 0);
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => _validJwt('a@b.com'));
      when(
        () => api.postJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await repo.logout(wipeLocalData: true);
      verify(() => localDb.clearAll()).called(1);
    });

    test(
      'logout(wipeLocalData: true) NO purga si quedan accesos de '
      'emergencia sin sincronizar, aunque los pacientes ya estén al día',
      () async {
        when(
          () =>
              localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => 2);
        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => _validJwt('a@b.com'));
        when(
          () => api.postJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => <String, dynamic>{});

        await repo.logout(wipeLocalData: true);

        verifyNever(() => localDb.clearAll());
        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );
  });

  group('currentUser', () {
    test('devuelve null antes de hacer login', () {
      expect(repo.currentUser, isNull);
    });
  });

  group('hasToken', () {
    test('false cuando no hay token en caché', () {
      expect(repo.hasToken, isFalse);
    });

    test('true después de hacer login exitoso', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'a@b.com'));

      await repo.login(email: 'a@b.com', password: '123');

      expect(repo.hasToken, isTrue);
    });

    test('false después de clearSession', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());

      await repo.login(email: 'a@b.com', password: 'x');
      await repo.clearSession();

      expect(repo.hasToken, isFalse);
    });
  });

  group('login()', () {
    test('login exitoso devuelve UserSession y persiste token', () async {
      final jwt = _validJwt('doc@hwb.org');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());

      final session = await repo.login(
        email: 'doc@hwb.org',
        password: 'secret',
      );

      expect(session.email, 'doc@hwb.org');
      expect(repo.currentUser, same(session));
      verify(
        () => storage.write(key: AuthRepository.tokenKey, value: jwt),
      ).called(1);
    });

    test(
      'login persiste el anillo NFC y retira la llave suelta previa',
      () async {
        final jwt = _validJwt('doc@hwb.org');
        when(
          () => api.postForm(
            path: any(named: 'path'),
            form: any(named: 'form'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': jwt,
            'nfc_encryption_key': 'super-secret-nfc',
          },
        );
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => _meResponse());

        await repo.login(email: 'doc@hwb.org', password: 'x');

        final List<Object?> captured = verify(
          () => storage.write(
            key: AuthRepository.nfcKeyringKey,
            value: captureAny(named: 'value'),
          ),
        ).captured;
        expect(captured, hasLength(1));

        final NfcKeyring? persisted = NfcKeyring.fromJson(
          jsonDecode(captured.single! as String) as Map<String, dynamic>,
        );
        expect(persisted, isNotNull);
        expect(persisted!.currentVersion, kLegacyNfcKeyVersion);
        expect(persisted.keyFor(0), 'super-secret-nfc');

        verify(() => storage.delete(key: AuthRepository.nfcKeyKey)).called(1);
      },
    );

    test('access_token null → lanza ApiException', () async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': null});

      expect(
        () => repo.login(email: 'x@y.com', password: 'p'),
        throwsA(isA<ApiException>()),
      );
    });

    test('access_token vacío → lanza ApiException', () async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': ''});

      expect(
        () => repo.login(email: 'x@y.com', password: 'p'),
        throwsA(isA<ApiException>()),
      );
    });

    test('postForm propaga su excepción', () async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenThrow(ApiException('Network error', statusCode: 500));

      expect(
        () => repo.login(email: 'x@y.com', password: 'p'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('login() — cambio de usuario', () {
    void stubLoginAs(String email) {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': _validJwt(email)});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: email));
    }

    test(
      'usuario distinto y sin nada pendiente: descarta la cola y la clave',
      () async {
        when(
          () => storage.read(key: AuthRepository.lastUserIdKey),
        ).thenAnswer((_) async => '11');
        when(
          () =>
              localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => 0);
        stubLoginAs('doc@hwb.org');

        await repo.login(email: 'doc@hwb.org', password: 'x');

        verify(() => localDb.clearAll()).called(1);
        verify(() => localDb.destroyEncryptionKey()).called(1);
        verify(
          () => storage.write(key: AuthRepository.lastUserIdKey, value: '42'),
        ).called(1);
      },
    );

    test(
      'usuario distinto con pacientes pendientes: NO borra nada y bloquea login',
      () async {
        when(
          () => storage.read(key: AuthRepository.lastUserIdKey),
        ).thenAnswer((_) async => '11');
        when(
          () =>
              localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => 4);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => 0);
        stubLoginAs('doc@hwb.org');

        await expectLater(
          () => repo.login(email: 'doc@hwb.org', password: 'x'),
          throwsA(isA<ForeignPendingDataException>()),
        );

        verifyNever(() => localDb.clearAll());
        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );

    test(
      'usuario distinto con accesos de emergencia pendientes: NO borra nada y bloquea login',
      () async {
        when(
          () => storage.read(key: AuthRepository.lastUserIdKey),
        ).thenAnswer((_) async => '11');
        when(
          () =>
              localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => 1);
        stubLoginAs('doc@hwb.org');

        await expectLater(
          () => repo.login(email: 'doc@hwb.org', password: 'x'),
          throwsA(isA<ForeignPendingDataException>()),
        );

        verifyNever(() => localDb.clearAll());
        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );

    test(
      'mismo usuario que vuelve a entrar: no dispara ningún borrado',
      () async {
        when(
          () => storage.read(key: AuthRepository.lastUserIdKey),
        ).thenAnswer((_) async => '42');
        stubLoginAs('doc@hwb.org');

        await repo.login(email: 'doc@hwb.org', password: 'x');

        verifyNever(() => localDb.clearAll());
        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );

    test('sin usuario previo registrado: no dispara ningún borrado', () async {
      when(
        () => storage.read(key: AuthRepository.lastUserIdKey),
      ).thenAnswer((_) async => null);
      stubLoginAs('doc@hwb.org');

      await repo.login(email: 'doc@hwb.org', password: 'x');

      verifyNever(() => localDb.clearAll());
      verifyNever(() => localDb.destroyEncryptionKey());
    });
  });

  group('logout()', () {
    test('revoca tokens en el servidor y limpia la sesión', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer(
        (_) async => {'access_token': jwt, 'refresh_token': 'refresh-xyz'},
      );
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());
      when(
        () => api.postJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await repo.login(email: 'a@b.com', password: 'x');
      await repo.logout();

      expect(repo.hasToken, isFalse);
      verify(() => storage.deleteAll()).called(greaterThanOrEqualTo(1));
    });

    test('limpia la sesión aunque el servidor falle (offline)', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt, 'refresh_token': 'r'});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());
      when(
        () => api.postJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException('offline', statusCode: 500));

      await repo.login(email: 'a@b.com', password: 'x');
      await repo.logout();

      expect(repo.hasToken, isFalse);
      verify(() => storage.deleteAll()).called(greaterThanOrEqualTo(1));
    });

    test('sin token no llama al servidor pero limpia la sesión', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => null);

      await repo.logout();

      verifyNever(
        () => api.postJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
      expect(repo.hasToken, isFalse);
    });
  });

  group('getAccessToken()', () {
    test('devuelve caché cuando no se pide forceRefresh', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'a@b.com'));

      await repo.login(email: 'a@b.com', password: 'x');
      clearInteractions(storage);

      final token = await repo.getAccessToken();

      expect(token, jwt);
      verifyNever(() => storage.read(key: any(named: 'key')));
    });

    test('forceRefresh=true ignora caché y lee de storage', () async {
      final jwt = _validJwt('b@c.com');
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => jwt);

      final token = await repo.getAccessToken(forceRefresh: true);

      expect(token, jwt);
      verify(() => storage.read(key: AuthRepository.tokenKey)).called(1);
    });

    test('storage devuelve null → lanza ApiException 401', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => null);

      expect(
        () => repo.getAccessToken(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('refreshAccessToken()', () {
    test('éxito: renueva el access token y persiste el par rotado', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => {
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        },
      );

      final token = await repo.refreshAccessToken();

      expect(token, 'new-access');
      verify(
        () => storage.write(key: AuthRepository.tokenKey, value: 'new-access'),
      ).called(1);
      verify(
        () =>
            storage.write(key: AuthRepository.refreshKey, value: 'new-refresh'),
      ).called(1);
    });

    test('sin refresh token almacenado → null sin llamar al backend', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => null);

      final token = await repo.refreshAccessToken();

      expect(token, isNull);
      verifyNever(
        () => api.postJson(
          path: any(named: 'path'),
          body: any(named: 'body'),
        ),
      );
    });

    test('refresh token expirado/revocado (401) → devuelve null', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        ApiException('Invalid or expired refresh token', statusCode: 401),
      );

      final token = await repo.refreshAccessToken();

      expect(token, isNull);
    });
  });

  group('session expiry (forced re-auth)', () {
    test('refresh 401 → invalida la sesión y emite sessionExpired', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenThrow(
        ApiException('Invalid or expired refresh token', statusCode: 401),
      );

      expect(repo.sessionExpired.value, isFalse);

      final token = await repo.refreshAccessToken();

      expect(token, isNull);
      expect(repo.sessionExpired.value, isTrue);
      expect(repo.currentUser, isNull);
      verify(() => storage.deleteAll()).called(greaterThanOrEqualTo(1));
    });
  });

  group('_fetchMe sin fallback', () {
    test(
      'ApiException 404 o 403 → propaga excepción y no crea sesión ficticia',
      () async {
        final jwt = _validJwt('jwt@hwb.org');
        when(
          () => api.postForm(
            path: any(named: 'path'),
            form: any(named: 'form'),
          ),
        ).thenAnswer((_) async => {'access_token': jwt});
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(ApiException('Not found', statusCode: 404));

        await expectLater(
          () => repo.login(email: 'jwt@hwb.org', password: 'p'),
          throwsA(isA<ApiException>()),
        );
        expect(repo.currentUser, isNull);
      },
    );

    test(
      'excepción genérica en getJson → propaga excepción y cancela login',
      () async {
        final jwt = _validJwt('generic@hwb.org');
        when(
          () => api.postForm(
            path: any(named: 'path'),
            form: any(named: 'form'),
          ),
        ).thenAnswer((_) async => {'access_token': jwt});
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(Exception('timeout'));

        await expectLater(
          () => repo.login(email: 'generic@hwb.org', password: 'p'),
          throwsA(isA<Exception>()),
        );
        expect(repo.currentUser, isNull);
      },
    );
  });

  group('getCurrentUser()', () {
    test('devuelve _session cacheada sin llamar a storage', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'a@b.com'));

      await repo.login(email: 'a@b.com', password: 'x');
      clearInteractions(storage);

      final user = await repo.getCurrentUser();

      expect(user?.email, 'a@b.com');
      verifyNever(() => storage.read(key: any(named: 'key')));
    });

    test('sin sesión: lee token y llama /me', () async {
      final jwt = _validJwt('fresh@hwb.org');
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => jwt);
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'fresh@hwb.org'));

      final user = await repo.getCurrentUser();

      expect(user?.email, 'fresh@hwb.org');
    });

    test('sin sesión y getAccessToken lanza → devuelve null', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => null);

      final user = await repo.getCurrentUser();

      expect(user, isNull);
    });

    test(
      'sin sesión y _fetchMe lanza excepción → devuelve null sin crear sesión ficticia',
      () async {
        final jwt = _validJwt('x@y.com');
        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => jwt);
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(Exception('unexpected'));

        final user = await repo.getCurrentUser();

        expect(user, isNull);
      },
    );
  });

  group('clearSession()', () {
    test('limpia _cachedToken, _session e invoca deleteAll', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': jwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());

      await repo.login(email: 'a@b.com', password: 'x');
      await repo.clearSession();

      expect(repo.currentUser, isNull);
      expect(repo.hasToken, isFalse);
      verify(() => storage.deleteAll()).called(greaterThanOrEqualTo(1));
    });

    test('clearSession CONSERVA la clave de cifrado local', () async {
      when(
        () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => 0);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 0);

      await repo.clearSession();

      verifyNever(() => localDb.destroyEncryptionKey());
    });
  });

  group('restoreSession()', () {
    String persistedJson({
      String id = '7',
      String email = 'admin@hwb.org',
      String fullName = 'Admin Real',
      String role = 'org_admin',
      String organizationId = 'org-1',
    }) => jsonEncode(<String, dynamic>{
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'organization_id': organizationId,
    });

    test('sin token persistido → null (debe ir a login)', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => null);

      final session = await repo.restoreSession();

      expect(session, isNull);
    });

    test(
      'con token + sesión persistida → restaura el rol REAL sin red',
      () async {
        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => _validJwt('admin@hwb.org'));
        when(
          () => storage.read(key: AuthRepository.sessionKey),
        ).thenAnswer((_) async => persistedJson());
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt(days: 2));

        final session = await repo.restoreSession();

        expect(session, isNotNull);
        expect(session!.role, UserRole.orgAdmin);
        expect(session.email, 'admin@hwb.org');
        expect(session.id, '7');
        expect(repo.currentUser, isNotNull);
        verifyNever(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        );
      },
    );

    test(
      'con token pero sin sesión persistida → cae a /me y la persiste',
      () async {
        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => _docJwt());
        when(
          () => storage.read(key: AuthRepository.sessionKey),
        ).thenAnswer((_) async => null);
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt(days: 2));
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => _meResponse(email: 'doc@hwb.org'));

        final session = await repo.restoreSession();

        expect(session?.email, 'doc@hwb.org');
        expect(session?.id, '42');
        verify(
          () => storage.write(
            key: AuthRepository.sessionKey,
            value: any(named: 'value'),
          ),
        ).called(1);
      },
    );

    test(
      'restoreSession y la ventana de sesión fuera de la ventana marca el estado pero conserva la sesión',
      () async {
        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => _validJwt('doc@hwb.org'));
        when(
          () => storage.read(key: AuthRepository.sessionKey),
        ).thenAnswer((_) async => persistedJson());
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt(days: -1));

        final session = await repo.restoreSession();

        expect(repo.sessionWindowClosed.value, isTrue);
        expect(session, isNotNull);
      },
    );
  });

  group('Foreign Data Methods & Session Callbacks', () {
    test('pendingForeignRecordsForReview queries local database', () async {
      when(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => []);

      final result = await repo.pendingForeignRecordsForReview();

      expect(result, isEmpty);
      verify(
        () =>
            localDb.getUnsyncedRecords(ownerUserId: any(named: 'ownerUserId')),
      ).called(1);
    });

    test(
      'pendingForeignEmergencyLogsForReview queries emergency logs',
      () async {
        when(
          () => localDb.pendingEmergencyAccessLogs(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => []);

        final result = await repo.pendingForeignEmergencyLogsForReview();

        expect(result, isEmpty);
        verify(
          () => localDb.pendingEmergencyAccessLogs(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).called(1);
      },
    );

    test(
      'discardForeignPendingData clears local db, encryption key and lastUserIdKey',
      () async {
        await repo.discardForeignPendingData();

        verify(() => localDb.clearAll()).called(1);
        verify(() => localDb.destroyEncryptionKey()).called(1);
        verify(
          () => storage.delete(key: AuthRepository.lastUserIdKey),
        ).called(1);
      },
    );

    test(
      'clearSession invokes onSessionInvalidated callback and handles error',
      () async {
        var callbackCalled = false;
        repo.onSessionInvalidated = () {
          callbackCalled = true;
        };

        await expectLater(repo.clearSession(), completes);
        expect(callbackCalled, isTrue);
      },
    );

    test(
      'wipeLocalPhi returns false and logs error when exception is thrown',
      () async {
        when(
          () =>
              localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
        ).thenThrow(Exception('Database locked'));

        final success = await repo.wipeLocalPhi();

        expect(success, isFalse);
      },
    );
  });
}

String _docJwt() => _validJwt('doc@hwb.org');
