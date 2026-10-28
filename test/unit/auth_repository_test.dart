// test/unit/auth_repository_test.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/api_error_codes.dart';
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

    test('usuario distinto con pacientes pendientes de otro: entra sin borrar '
        'nada (quedan aislados hasta que vuelva su dueño)', () async {
      when(
        () => storage.read(key: AuthRepository.lastUserIdKey),
      ).thenAnswer((_) async => '11');
      when(
        () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => 4);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 0);
      stubLoginAs('doc@hwb.org');

      final session = await repo.login(email: 'doc@hwb.org', password: 'x');

      expect(session.id, '42');
      expect(repo.currentUser, same(session));
      verifyNever(() => localDb.clearAll());
      verifyNever(() => localDb.destroyEncryptionKey());
    });

    test('usuario distinto con accesos de emergencia pendientes de otro: entra '
        'sin borrar nada', () async {
      when(
        () => storage.read(key: AuthRepository.lastUserIdKey),
      ).thenAnswer((_) async => '11');
      when(
        () => localDb.getUnsyncedCount(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer((_) async => 0);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(
          ownerUserId: any(named: 'ownerUserId'),
        ),
      ).thenAnswer((_) async => 1);
      stubLoginAs('doc@hwb.org');

      final session = await repo.login(email: 'doc@hwb.org', password: 'x');

      expect(session.id, '42');
      expect(repo.currentUser, same(session));
      verifyNever(() => localDb.clearAll());
      verifyNever(() => localDb.destroyEncryptionKey());
    });

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
      verify(() => storage.delete(key: AuthRepository.tokenKey)).called(1);
      verifyNever(() => storage.deleteAll());
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
      verify(() => storage.delete(key: AuthRepository.tokenKey)).called(1);
      verifyNever(() => storage.deleteAll());
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

  group('must_change_password y cambio de contraseña', () {
    final String loginRefresh = _refreshJwt();

    Future<void> signIn({bool tokenFlag = false, bool meFlag = false}) async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer(
        (_) async => {
          'access_token': _validJwt('doc@hwb.org'),
          'refresh_token': loginRefresh,
          'must_change_password': tokenFlag,
        },
      );
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => {..._meResponse(), 'must_change_password': meFlag},
      );
      await repo.login(email: 'doc@hwb.org', password: 'temporal');
    }

    void stubChange(Future<Map<String, dynamic>> Function() answer) {
      when(
        () => api.postJson(
          path: '/api/v1/users/me/password',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) => answer());
    }

    test('login: la marca llega del par de tokens', () async {
      await signIn(tokenFlag: true);
      expect(repo.currentUser!.mustChangePassword, isTrue);
    });

    test('login: la marca llega de /users/me', () async {
      await signIn(meFlag: true);
      expect(repo.currentUser!.mustChangePassword, isTrue);
    });

    test('login: sin marca, no hay cambio obligatorio', () async {
      await signIn();
      expect(repo.currentUser!.mustChangePassword, isFalse);
    });

    test('changePassword envía las dos contraseñas y adopta el par nuevo y '
        'el anillo NFC', () async {
      await signIn(tokenFlag: true);
      final String newRefresh = _refreshJwt(days: 6);
      stubChange(
        () async => {
          'access_token': 'access-after-change',
          'refresh_token': newRefresh,
          'nfc_keyring': {'2': 'AB' * 32},
          'nfc_key_version': 2,
          'must_change_password': false,
        },
      );

      final session = await repo.changePassword(
        currentPassword: 'temporal',
        newPassword: 'una-clave-larga-1',
      );

      final captured = verify(
        () => api.postJson(
          path: '/api/v1/users/me/password',
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      // Named arguments are captured in name order: body, then headers.
      expect(captured[0], {
        'current_password': 'temporal',
        'new_password': 'una-clave-larga-1',
      });
      expect(captured[1], {
        'Authorization': 'Bearer ${_validJwt('doc@hwb.org')}',
      });
      expect(session.mustChangePassword, isFalse);
      expect(repo.currentUser!.mustChangePassword, isFalse);
      expect(await repo.getAccessToken(), 'access-after-change');
      verify(
        () => storage.write(
          key: AuthRepository.tokenKey,
          value: 'access-after-change',
        ),
      ).called(1);
      verify(
        () => storage.write(key: AuthRepository.refreshKey, value: newRefresh),
      ).called(1);
      final keyring = verify(
        () => storage.write(
          key: AuthRepository.nfcKeyringKey,
          value: captureAny(named: 'value'),
        ),
      ).captured.last;
      expect(keyring as String, contains('"2"'));
      final persisted = verify(
        () => storage.write(
          key: AuthRepository.sessionKey,
          value: captureAny(named: 'value'),
        ),
      ).captured.last;
      expect(
        (jsonDecode(persisted as String)
            as Map<String, dynamic>)['must_change_password'],
        isFalse,
      );
    });

    test('un 400 se propaga y deja la sesión como estaba', () async {
      await signIn(tokenFlag: true);
      stubChange(
        () async => throw ApiException(
          'The current password is not correct.',
          statusCode: 400,
        ),
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'mala',
          newPassword: 'una-clave-larga-1',
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
      expect(repo.currentUser!.mustChangePassword, isTrue);
      expect(await repo.getAccessToken(), _validJwt('doc@hwb.org'));
    });

    test('una respuesta sin access_token es un error', () async {
      await signIn();
      stubChange(() async => <String, dynamic>{});

      await expectLater(
        repo.changePassword(currentPassword: 'a', newPassword: 'b'),
        throwsA(isA<ApiException>()),
      );
    });

    test('un refresh que estaba en vuelo durante el cambio no cierra la '
        'sesión: el cambio revocó su token y guardó uno nuevo', () async {
      await signIn();
      final Completer<Map<String, dynamic>> inFlight =
          Completer<Map<String, dynamic>>();
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) => inFlight.future);
      stubChange(
        () async => {
          'access_token': 'access-after-change',
          'refresh_token': _refreshJwt(days: 6),
        },
      );

      final Future<String?> refresh = repo.refreshAccessToken();
      await repo.changePassword(
        currentPassword: 'temporal',
        newPassword: 'una-clave-larga-1',
      );
      inFlight.completeError(
        ApiException('Invalid or expired refresh token', statusCode: 401),
      );

      expect(await refresh, 'access-after-change');
      expect(repo.currentUser, isNotNull);
      expect(repo.sessionExpired.value, isFalse);
    });

    test(
      'el refresh actualiza la marca solo si la respuesta la trae',
      () async {
        await signIn(tokenFlag: true);
        when(
          () => api.postJson(
            path: '/api/v1/login/refresh',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => {'access_token': 'a2', 'refresh_token': _refreshJwt()},
        );
        await repo.refreshAccessToken();
        expect(repo.currentUser!.mustChangePassword, isTrue);

        when(
          () => api.postJson(
            path: '/api/v1/login/refresh',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': 'a3',
            'refresh_token': _refreshJwt(),
            'must_change_password': false,
          },
        );
        await repo.refreshAccessToken();
        expect(repo.currentUser!.mustChangePassword, isFalse);
      },
    );
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
      verify(() => storage.delete(key: AuthRepository.refreshKey)).called(1);
      verifyNever(() => storage.deleteAll());
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
    test('en el teléfono borra solo las llaves de la sesión', () async {
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
      for (final String key in <String>[
        AuthRepository.tokenKey,
        AuthRepository.refreshKey,
        AuthRepository.nfcKeyKey,
        AuthRepository.nfcKeyringKey,
        AuthRepository.clockMarkKey,
        AuthRepository.sessionKey,
      ]) {
        verify(() => storage.delete(key: key)).called(1);
      }
      // On Android deleteAll() would also take the keys of the local
      // database (same storage file); hwb_last_user_id says whose rows stay.
      verifyNever(() => storage.deleteAll());
      verifyNever(() => storage.delete(key: AuthRepository.lastUserIdKey));
    });

    test('en la web borra todo el almacén', () async {
      final webRepo = _makeRepo(
        api: api,
        storage: storage,
        localDb: localDb,
        forceWeb: true,
      );

      await webRepo.clearSession();

      verify(() => storage.deleteAll()).called(1);
      verifyNever(() => storage.delete(key: AuthRepository.tokenKey));
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

  group('Session Callbacks', () {
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

  void stubLogin({
    Map<String, dynamic> token = const <String, dynamic>{},
    String email = 'doc@hwb.org',
  }) {
    when(
      () => api.postForm(
        path: any(named: 'path'),
        form: any(named: 'form'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'access_token': _validJwt(email),
        ...token,
      },
    );
    when(
      () => api.getJson(
        path: any(named: 'path'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => _meResponse(email: email));
  }

  void stubStoredRefresh(String refreshJwt) {
    when(
      () => storage.read(key: AuthRepository.refreshKey),
    ).thenAnswer((_) async => refreshJwt);
  }

  String jwtAt({required Duration iat, required Duration exp}) {
    final DateTime now = DateTime.now().toUtc();
    return _buildJwt(<String, dynamic>{
      'sub': 'doc@hwb.org',
      'type': 'refresh',
      'iat': now.add(iat).millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(exp).millisecondsSinceEpoch ~/ 1000,
    });
  }

  String inactiveAccountCode() {
    const List<String> candidates = <String>[
      'account_inactive',
      'ACCOUNT_INACTIVE',
      'user_inactive',
      'USER_INACTIVE',
      'inactive_account',
      'inactive_user',
      'account_disabled',
      'ACCOUNT_DISABLED',
      'user_disabled',
      'organization_inactive',
      'ORGANIZATION_INACTIVE',
      'org_inactive',
    ];
    for (final String code in candidates) {
      if (ApiErrorCode.isAccountInactive(code)) return code;
    }
    fail(
      'Ningún candidato es reconocido por ApiErrorCode.isAccountInactive: '
      'agregue el código real a inactiveAccountCode().',
    );
  }

  group('cuenta inactiva y sesión restaurada', () {
    test('accountInactiveCode empieza en null', () {
      expect(repo.accountInactiveCode.value, isNull);
    });

    test(
      'handleAccountInactive sin sesión ni token solo guarda el código',
      () async {
        await repo.handleAccountInactive('ACCOUNT_X');

        expect(repo.accountInactiveCode.value, 'ACCOUNT_X');
        expect(repo.sessionExpired.value, isFalse);
        verifyNever(() => storage.delete(key: any(named: 'key')));
      },
    );

    test('handleAccountInactive con token invalida la sesión', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => _validJwt('doc@hwb.org'));
      await repo.getAccessToken();
      expect(repo.hasToken, isTrue);

      await repo.handleAccountInactive('ACCOUNT_X');

      expect(repo.accountInactiveCode.value, 'ACCOUNT_X');
      expect(repo.sessionExpired.value, isTrue);
      expect(repo.hasToken, isFalse);
      expect(repo.currentUser, isNull);
    });

    test(
      'handleAccountInactive con sesión activa también la invalida',
      () async {
        stubLogin();
        await repo.login(email: 'doc@hwb.org', password: 'x');

        await repo.handleAccountInactive('ACCOUNT_X');

        expect(repo.sessionExpired.value, isTrue);
        expect(repo.currentUser, isNull);
      },
    );

    test('un refresh 401 con código de cuenta inactiva lo publica', () async {
      final String code = inactiveAccountCode();
      stubStoredRefresh('old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException('Cuenta inactiva', statusCode: 401, code: code));

      final String? token = await repo.refreshAccessToken();

      expect(token, isNull);
      expect(repo.accountInactiveCode.value, code);
      expect(repo.sessionExpired.value, isTrue);
    });

    test(
      'isSessionRestoredFromStorage: false al inicio y true al restaurar',
      () async {
        expect(repo.isSessionRestoredFromStorage, isFalse);

        when(
          () => storage.read(key: AuthRepository.tokenKey),
        ).thenAnswer((_) async => _validJwt('admin@hwb.org'));
        when(() => storage.read(key: AuthRepository.sessionKey)).thenAnswer(
          (_) async => jsonEncode(<String, dynamic>{
            'id': '7',
            'email': 'admin@hwb.org',
            'full_name': 'Admin Real',
            'role': 'org_admin',
            'organization_id': 'org-1',
          }),
        );
        stubStoredRefresh(_refreshJwt(days: 2));

        await repo.restoreSession();

        expect(repo.isSessionRestoredFromStorage, isTrue);
      },
    );
  });

  group('login() sin recordar la sesión', () {
    test(
      'borra token, refresh y sesión persistidos en vez de guardarlos',
      () async {
        stubLogin(token: <String, dynamic>{'refresh_token': _refreshJwt()});

        final UserSession session = await repo.login(
          email: 'doc@hwb.org',
          password: 'secret',
          rememberSession: false,
        );

        expect(session.id, '42');
        verify(() => storage.delete(key: AuthRepository.tokenKey)).called(1);
        verify(() => storage.delete(key: AuthRepository.refreshKey)).called(1);
        verify(() => storage.delete(key: AuthRepository.sessionKey)).called(1);
        verifyNever(
          () => storage.write(
            key: AuthRepository.tokenKey,
            value: any(named: 'value'),
          ),
        );
        verifyNever(
          () => storage.write(
            key: AuthRepository.sessionKey,
            value: any(named: 'value'),
          ),
        );
      },
    );

    test('tolera que el almacén falle al borrar', () async {
      stubLogin(token: <String, dynamic>{'refresh_token': _refreshJwt()});
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenThrow(Exception('almacén no disponible'));

      final UserSession session = await repo.login(
        email: 'doc@hwb.org',
        password: 'secret',
        rememberSession: false,
      );

      expect(session.email, 'doc@hwb.org');
    });
  });

  group('verifyLocalLockPassword()', () {
    const String lockKey = 'hwb_local_lock_hash';

    test('sin sesión devuelve false', () async {
      expect(await repo.verifyLocalLockPassword('secret'), isFalse);
    });

    test('con sesión sin email devuelve false', () async {
      stubLogin(email: '');
      await repo.login(email: '', password: 'secret');

      expect(await repo.verifyLocalLockPassword('secret'), isFalse);
    });

    test('sin hash guardado devuelve false', () async {
      stubLogin();
      await repo.login(email: 'doc@hwb.org', password: 'secret');
      when(() => storage.read(key: lockKey)).thenAnswer((_) async => null);

      expect(await repo.verifyLocalLockPassword('secret'), isFalse);
    });

    test('con hash guardado vacío devuelve false', () async {
      stubLogin();
      await repo.login(email: 'doc@hwb.org', password: 'secret');
      when(() => storage.read(key: lockKey)).thenAnswer((_) async => '');

      expect(await repo.verifyLocalLockPassword('secret'), isFalse);
    });

    test('acepta la contraseña correcta y rechaza la incorrecta', () async {
      stubLogin();
      await repo.login(email: 'doc@hwb.org', password: 'secret');
      final String hash =
          verify(
                () => storage.write(
                  key: lockKey,
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      when(() => storage.read(key: lockKey)).thenAnswer((_) async => hash);

      expect(await repo.verifyLocalLockPassword('secret'), isTrue);
      expect(await repo.verifyLocalLockPassword('otra-clave'), isFalse);
    });

    test('si el almacén falla al leer devuelve false', () async {
      stubLogin();
      await repo.login(email: 'doc@hwb.org', password: 'secret');
      when(
        () => storage.read(key: lockKey),
      ).thenThrow(Exception('llavero bloqueado'));

      expect(await repo.verifyLocalLockPassword('secret'), isFalse);
    });
  });

  group('datos pendientes de otro usuario', () {
    test(
      'pendingForeignRecordsForReview consulta con el id de la sesión',
      () async {
        when(
          () => localDb.getUnsyncedRecords(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => <LocalPatientEntry>[]);

        expect(await repo.pendingForeignRecordsForReview(), isEmpty);
        verify(() => localDb.getUnsyncedRecords(ownerUserId: null)).called(1);

        stubLogin();
        await repo.login(email: 'doc@hwb.org', password: 'x');
        await repo.pendingForeignRecordsForReview();
        verify(() => localDb.getUnsyncedRecords(ownerUserId: '42')).called(1);
      },
    );

    test(
      'pendingForeignEmergencyLogsForReview consulta con el id de la sesión',
      () async {
        when(
          () => localDb.pendingEmergencyAccessLogs(
            ownerUserId: any(named: 'ownerUserId'),
          ),
        ).thenAnswer((_) async => <Map<String, Object?>>[]);

        expect(await repo.pendingForeignEmergencyLogsForReview(), isEmpty);
        verify(
          () => localDb.pendingEmergencyAccessLogs(ownerUserId: null),
        ).called(1);

        stubLogin();
        await repo.login(email: 'doc@hwb.org', password: 'x');
        await repo.pendingForeignEmergencyLogsForReview();
        verify(
          () => localDb.pendingEmergencyAccessLogs(ownerUserId: '42'),
        ).called(1);
      },
    );

    test(
      'discardForeignPendingData borra la base, la llave y el último usuario',
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
      'discardForeignPendingData tolera que falle el borrado del usuario',
      () async {
        when(
          () => storage.delete(key: AuthRepository.lastUserIdKey),
        ).thenThrow(Exception('almacén no disponible'));

        await expectLater(repo.discardForeignPendingData(), completes);
        verify(() => localDb.destroyEncryptionKey()).called(1);
      },
    );
  });

  group('getNfcKeyring()', () {
    test(
      'fuera de la ventana de sesión olvida el anillo y devuelve null',
      () async {
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => null);

        expect(await repo.getNfcKeyring(), isNull);
        verify(
          () => storage.delete(key: AuthRepository.nfcKeyringKey),
        ).called(1);
        verify(() => storage.delete(key: AuthRepository.nfcKeyKey)).called(1);
      },
    );

    test('devuelve el anillo en caché sin leer del almacén', () async {
      stubLogin(
        token: <String, dynamic>{
          'refresh_token': _refreshJwt(),
          'nfc_encryption_key': 'cached-nfc',
        },
      );
      await repo.login(email: 'doc@hwb.org', password: 'x');

      final NfcKeyring? keyring = await repo.getNfcKeyring();

      expect(keyring, isNotNull);
      expect(keyring!.keyFor(0), 'cached-nfc');
      verifyNever(() => storage.read(key: AuthRepository.nfcKeyringKey));
    });

    test('restaura el anillo guardado y lo deja en caché', () async {
      stubStoredRefresh(_refreshJwt());
      when(() => storage.read(key: AuthRepository.nfcKeyringKey)).thenAnswer(
        (_) async => jsonEncode(NfcKeyring.single('stored-nfc').toJson()),
      );

      final NfcKeyring? first = await repo.getNfcKeyring();
      final NfcKeyring? second = await repo.getNfcKeyring();

      expect(first, isNotNull);
      expect(first!.keyFor(0), 'stored-nfc');
      expect(second, same(first));
      verify(() => storage.read(key: AuthRepository.nfcKeyringKey)).called(1);
    });

    test(
      'un anillo guardado que no es un mapa cae a la llave heredada',
      () async {
        stubStoredRefresh(_refreshJwt());
        when(
          () => storage.read(key: AuthRepository.nfcKeyringKey),
        ).thenAnswer((_) async => jsonEncode(<int>[1, 2, 3]));
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => 'legacy-nfc');

        final NfcKeyring? keyring = await repo.getNfcKeyring();

        expect(keyring, isNotNull);
        expect(keyring!.keyFor(0), 'legacy-nfc');
      },
    );

    test('un anillo guardado vacío cae a la llave heredada', () async {
      stubStoredRefresh(_refreshJwt());
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => jsonEncode(<String, dynamic>{}));
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => 'legacy-nfc');

      final NfcKeyring? keyring = await repo.getNfcKeyring();

      expect(keyring?.keyFor(0), 'legacy-nfc');
    });

    test(
      'un anillo guardado con JSON inválido cae a la llave heredada',
      () async {
        stubStoredRefresh(_refreshJwt());
        when(
          () => storage.read(key: AuthRepository.nfcKeyringKey),
        ).thenAnswer((_) async => 'esto no es json');
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => 'legacy-nfc');

        final NfcKeyring? keyring = await repo.getNfcKeyring();

        expect(keyring?.keyFor(0), 'legacy-nfc');
      },
    );

    test('sin anillo ni llave heredada devuelve null', () async {
      stubStoredRefresh(_refreshJwt());
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => null);
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => '');

      expect(await repo.getNfcKeyring(), isNull);
    });

    test('si falla la lectura de la llave heredada devuelve null', () async {
      stubStoredRefresh(_refreshJwt());
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => '');
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenThrow(Exception('llavero bloqueado'));

      expect(await repo.getNfcKeyring(), isNull);
    });
  });

  group('isNfcSessionExpired() y marca de reloj', () {
    const String clockKey = 'hwb_clock_mark';

    test('false con refresh vigente', () async {
      stubStoredRefresh(_refreshJwt());

      expect(await repo.isNfcSessionExpired(), isFalse);
    });

    test('true sin refresh token', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => null);

      expect(await repo.isNfcSessionExpired(), isTrue);
    });

    test('lee la marca de reloj guardada y la acepta si es reciente', () async {
      stubStoredRefresh(_refreshJwt());
      when(() => storage.read(key: clockKey)).thenAnswer(
        (_) async => DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
      );

      expect(await repo.isNfcSessionExpired(), isFalse);
      verify(() => storage.read(key: clockKey)).called(1);
    });

    test('una marca guardada vacía se ignora', () async {
      stubStoredRefresh(_refreshJwt());
      when(() => storage.read(key: clockKey)).thenAnswer((_) async => '');

      expect(await repo.isNfcSessionExpired(), isFalse);
    });

    test('una marca guardada no numérica se ignora', () async {
      stubStoredRefresh(_refreshJwt());
      when(() => storage.read(key: clockKey)).thenAnswer((_) async => 'abc');

      expect(await repo.isNfcSessionExpired(), isFalse);
    });

    test('si falla la lectura de la marca se ignora', () async {
      stubStoredRefresh(_refreshJwt());
      when(
        () => storage.read(key: clockKey),
      ).thenThrow(Exception('llavero bloqueado'));

      expect(await repo.isNfcSessionExpired(), isFalse);
    });

    test(
      'una marca guardada muy en el futuro detecta el reloj atrasado',
      () async {
        stubStoredRefresh(_refreshJwt());
        when(() => storage.read(key: clockKey)).thenAnswer(
          (_) async => DateTime.now()
              .toUtc()
              .add(const Duration(days: 10))
              .millisecondsSinceEpoch
              .toString(),
        );

        expect(await repo.isNfcSessionExpired(), isTrue);
      },
    );

    test(
      'un refresh emitido en el futuro lejano detecta el reloj atrasado',
      () async {
        stubLogin(
          token: <String, dynamic>{
            'refresh_token': jwtAt(
              iat: const Duration(days: 10),
              exp: const Duration(days: 20),
            ),
          },
        );
        await repo.login(email: 'doc@hwb.org', password: 'x');

        expect(await repo.isNfcSessionExpired(), isTrue);
      },
    );

    test(
      'una marca dentro de la tolerancia no cuenta como reloj atrasado',
      () async {
        stubLogin(
          token: <String, dynamic>{
            // Emitido 1 h en el futuro: dentro de las 24 h de tolerancia.
            'refresh_token': jwtAt(
              iat: const Duration(hours: 1),
              exp: const Duration(days: 20),
            ),
          },
        );
        await repo.login(email: 'doc@hwb.org', password: 'x');

        expect(await repo.isNfcSessionExpired(), isFalse);
        // Segunda consulta: la marca en caché no es anterior a "ahora".
        expect(await repo.isNfcSessionExpired(), isFalse);
      },
    );
  });

  group('clearSession() con callback defectuoso', () {
    test('registra el error y sigue limpiando la sesión', () async {
      repo.onSessionInvalidated = () => throw StateError('motor de sync caído');

      await expectLater(repo.clearSession(), completes);

      expect(repo.currentUser, isNull);
      expect(repo.hasToken, isFalse);
    });
  });

  group('modo web (forceWeb)', () {
    late AuthRepository webRepo;

    setUp(() {
      webRepo = _makeRepo(
        api: api,
        storage: storage,
        localDb: localDb,
        forceWeb: true,
      );
    });

    test(
      'getNfcKeyring sin anillo en memoria devuelve null sin leer el almacén',
      () async {
        stubStoredRefresh(_refreshJwt());
        when(() => storage.read(key: AuthRepository.nfcKeyringKey)).thenAnswer(
          (_) async => jsonEncode(NfcKeyring.single('stored-nfc').toJson()),
        );
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => 'legacy-nfc');

        expect(await webRepo.getNfcKeyring(), isNull);
        expect(await webRepo.getNfcKeyring(), isNull);

        verifyNever(() => storage.read(key: AuthRepository.nfcKeyringKey));
        verifyNever(() => storage.read(key: AuthRepository.nfcKeyKey));
      },
    );

    test('getNfcKeyring devuelve el anillo de la sesión en memoria', () async {
      stubLogin(
        token: <String, dynamic>{
          'refresh_token': _refreshJwt(),
          'nfc_encryption_key': 'web-nfc',
        },
      );
      await webRepo.login(email: 'doc@hwb.org', password: 'x');

      final NfcKeyring? keyring = await webRepo.getNfcKeyring();

      expect(keyring, isNotNull);
      expect(keyring!.keyFor(0), 'web-nfc');
      verifyNever(() => storage.read(key: AuthRepository.nfcKeyringKey));
    });

    test('la marca de reloj guardada no se lee del almacén', () async {
      stubStoredRefresh(_refreshJwt());
      when(() => storage.read(key: AuthRepository.clockMarkKey)).thenAnswer(
        (_) async => DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch
            .toString(),
      );

      expect(await webRepo.isNfcSessionExpired(), isFalse);
      verifyNever(() => storage.read(key: AuthRepository.clockMarkKey));
    });

    test('la marca en memoria sigue detectando un reloj atrasado', () async {
      stubStoredRefresh(_refreshJwt());

      expect(await webRepo.isNfcSessionExpired(), isFalse);
      expect(await webRepo.isNfcSessionExpired(), isFalse);
      verifyNever(() => storage.read(key: AuthRepository.clockMarkKey));
    });
  });
}

String _docJwt() => _validJwt('doc@hwb.org');
