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

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _buildJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  const sig = 'fakesig';
  return '$header.$body.$sig';
}

String _validJwt(String email) => _buildJwt({'sub': email, 'exp': 9999999999});

String _jwtNoSub() => _buildJwt({'user': 'x'});

/// A refresh token whose `exp` is [days] from now (negative = already expired).
String _refreshJwt({int days = 7}) => _buildJwt({
  'sub': 'doc@hwb.org',
  'type': 'refresh',
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
}) => AuthRepository(
  apiClient: api,
  secureStorage: storage,
  localDatabase: localDb,
);

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────
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
    repo = _makeRepo(api: api, storage: storage, localDb: localDb);

    when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
    when(
      () => localDb.getUnsyncedEmergencyLogCount(),
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
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 3);
      await repo.logout(wipeLocalData: true);
      verifyNever(() => localDb.clearAll());
    });

    test('logout(wipeLocalData: true) purga sólo con la cola vacía', () async {
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
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
        when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(),
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

  // ───────────────────────────────────────────────────────────────────────────
  // currentUser getter
  // ───────────────────────────────────────────────────────────────────────────
  group('currentUser', () {
    test('devuelve null antes de hacer login', () {
      expect(repo.currentUser, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // hasToken
  // ───────────────────────────────────────────────────────────────────────────
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

  // ───────────────────────────────────────────────────────────────────────────
  // login()
  // ───────────────────────────────────────────────────────────────────────────
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

        // Un backend sin versionado entrega sólo nfc_encryption_key: se guarda
        // como el anillo con la llave en la versión 0, que es exactamente con
        // la que descifran las pulseras ya escritas.
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

        // La llave suelta queda superada por el anillo: no se deja el mismo
        // material en dos lugares.
        verify(() => storage.delete(key: AuthRepository.nfcKeyKey)).called(1);
        verifyNever(
          () => storage.write(
            key: AuthRepository.nfcKeyKey,
            value: any(named: 'value'),
          ),
        );
      },
    );

    test('nfc_encryption_key vacía NO se persiste', () async {
      final jwt = _validJwt('a@b.com');
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer(
        (_) async => {'access_token': jwt, 'nfc_encryption_key': ''},
      );
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse());

      await repo.login(email: 'a@b.com', password: 'x');

      verifyNever(
        () => storage.write(
          key: AuthRepository.nfcKeyKey,
          value: any(named: 'value'),
        ),
      );
    });

    test('nfc_encryption_key null NO se persiste', () async {
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

      verifyNever(
        () => storage.write(
          key: AuthRepository.nfcKeyKey,
          value: any(named: 'value'),
        ),
      );
    });

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

    test(
      'storage.write lanza excepción → se silencia y login continúa',
      () async {
        final jwt = _validJwt('a@b.com');
        when(
          () => api.postForm(
            path: any(named: 'path'),
            form: any(named: 'form'),
          ),
        ).thenAnswer(
          (_) async => {'access_token': jwt, 'nfc_encryption_key': 'k'},
        );
        when(
          () => api.getJson(
            path: any(named: 'path'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => _meResponse());

        when(
          () => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('storage error'));

        final session = await repo.login(email: 'a@b.com', password: 'x');
        expect(session, isNotNull);
      },
    );

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
        when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(),
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
        when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 4);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(),
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

    test('usuario distinto con accesos de emergencia pendientes (aunque los '
        'pacientes ya estén al día): NO borra nada y bloquea login — el log comparte la '
        'misma clave de cifrado', () async {
      when(
        () => storage.read(key: AuthRepository.lastUserIdKey),
      ).thenAnswer((_) async => '11');
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(),
      ).thenAnswer((_) async => 1);
      stubLoginAs('doc@hwb.org');

      await expectLater(
        () => repo.login(email: 'doc@hwb.org', password: 'x'),
        throwsA(isA<ForeignPendingDataException>()),
      );

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

    test('sin usuario previo registrado (primer login del dispositivo): '
        'no dispara ningún borrado', () async {
      when(
        () => storage.read(key: AuthRepository.lastUserIdKey),
      ).thenAnswer((_) async => null);
      stubLoginAs('doc@hwb.org');

      await repo.login(email: 'doc@hwb.org', password: 'x');

      verifyNever(() => localDb.clearAll());
      verifyNever(() => localDb.destroyEncryptionKey());
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // refresh token persistence
  // ───────────────────────────────────────────────────────────────────────────
  group('refresh token', () {
    test('login persiste refresh_token cuando está presente', () async {
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

      await repo.login(email: 'a@b.com', password: 'x');

      verify(
        () =>
            storage.write(key: AuthRepository.refreshKey, value: 'refresh-xyz'),
      ).called(1);
    });

    test('refresh_token ausente NO se persiste', () async {
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

      verifyNever(
        () => storage.write(
          key: AuthRepository.refreshKey,
          value: any(named: 'value'),
        ),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // logout()
  // ───────────────────────────────────────────────────────────────────────────
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

      final captured = verify(
        () => api.postJson(
          path: captureAny(named: 'path'),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured[0], '/api/v1/logout');
      expect((captured[1] as Map)['refresh_token'], 'refresh-xyz');
      expect((captured[2] as Map)['Authorization'], 'Bearer $jwt');
      expect(repo.hasToken, isFalse);
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

  // ───────────────────────────────────────────────────────────────────────────
  // getAccessToken()
  // ───────────────────────────────────────────────────────────────────────────
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
      ).thenAnswer((_) async => _meResponse());

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

    test('sin caché lee de storage correctamente', () async {
      final jwt = _validJwt('c@d.com');
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => jwt);

      final token = await repo.getAccessToken();

      expect(token, jwt);
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

    test('storage devuelve cadena vacía → lanza ApiException 401', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => '');

      expect(
        () => repo.getAccessToken(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('storage.read lanza excepción → lanza ApiException 401', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenThrow(Exception('disk error'));

      expect(
        () => repo.getAccessToken(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // refreshAccessToken()
  // ───────────────────────────────────────────────────────────────────────────
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

    test(
      'error transitorio (500) → se relanza para reintento posterior',
      () async {
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => 'old-refresh');
        when(
          () => api.postJson(
            path: '/api/v1/login/refresh',
            body: any(named: 'body'),
          ),
        ).thenThrow(ApiException('Server error', statusCode: 500));

        await expectLater(
          repo.refreshAccessToken(),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 500)),
        );
      },
    );

    test('respuesta sin access_token → devuelve null', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'refresh_token': 'x'});

      final token = await repo.refreshAccessToken();

      expect(token, isNull);
    });

    test(
      'single-flight: dos llamadas concurrentes comparten un solo refresh',
      () async {
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => 'old-refresh');
        var calls = 0;
        when(
          () => api.postJson(
            path: '/api/v1/login/refresh',
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return {'access_token': 'new-access', 'refresh_token': 'new-refresh'};
        });

        final results = await Future.wait(<Future<String?>>[
          repo.refreshAccessToken(),
          repo.refreshAccessToken(),
        ]);

        expect(results, ['new-access', 'new-access']);
        expect(calls, 1);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // session expiry (forced re-auth)
  // ───────────────────────────────────────────────────────────────────────────
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
      verify(() => storage.delete(key: AuthRepository.sessionKey)).called(1);
    });

    test('error transitorio (500) NO invalida la sesión', () async {
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'old-refresh');
      when(
        () => api.postJson(
          path: '/api/v1/login/refresh',
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException('Server error', statusCode: 500));

      await expectLater(
        repo.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );

      expect(repo.sessionExpired.value, isFalse);
      verifyNever(() => storage.delete(key: AuthRepository.sessionKey));
    });

    test('un login exitoso limpia el estado de sesión expirada', () async {
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
      await repo.refreshAccessToken();
      expect(repo.sessionExpired.value, isTrue);

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
      ).thenAnswer((_) async => _meResponse(email: 'doc@hwb.org'));

      await repo.login(email: 'doc@hwb.org', password: 'x');

      expect(repo.sessionExpired.value, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // getCurrentUser()
  // ───────────────────────────────────────────────────────────────────────────
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
      'sin sesión y _fetchMe lanza excepción genérica → devuelve sesión fallback desde JWT',
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

        expect(user, isNotNull);
        expect(user?.email, 'x@y.com');
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Llave suelta heredada (sólo alcanzable vía el anillo)
  // ───────────────────────────────────────────────────────────────────────────
  group('llave suelta heredada', () {
    test('se devuelve como anillo de versión 0', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => 'my-nfc-key');
      // La llave sólo se entrega dentro de la ventana de sesión, así que el
      // caso positivo necesita un refresh token vigente.
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());

      final ring = await repo.getNfcKeyring();

      expect(ring, isNotNull);
      expect(ring!.keyFor(kLegacyNfcKeyVersion), 'my-nfc-key');
    });

    test('devuelve null cuando no hay clave', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => null);

      expect(await repo.getNfcKeyring(), isNull);
    });

    test('storage lanza excepción → devuelve null (silenciado)', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenThrow(Exception('hardware error'));

      expect(await repo.getNfcKeyring(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // clearSession()
  // ───────────────────────────────────────────────────────────────────────────
  group('clearSession()', () {
    test('limpia _cachedToken, _session e invoca ambas deletes', () async {
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
      verify(() => storage.delete(key: AuthRepository.tokenKey)).called(1);
      verify(() => storage.delete(key: AuthRepository.nfcKeyKey)).called(1);
    });

    test('storage.delete(tokenKey) lanza excepción → se silencia', () async {
      when(
        () => storage.delete(key: AuthRepository.tokenKey),
      ).thenThrow(Exception('disk error'));
      when(
        () => storage.delete(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async {});

      await expectLater(repo.clearSession(), completes);
    });

    test('storage.delete(nfcKeyKey) lanza excepción → se silencia', () async {
      when(
        () => storage.delete(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async {});
      when(
        () => storage.delete(key: AuthRepository.nfcKeyKey),
      ).thenThrow(Exception('disk error'));

      await expectLater(repo.clearSession(), completes);
    });

    test('clearSession funciona aunque no hubiera sesión activa', () async {
      await expectLater(repo.clearSession(), completes);
      expect(repo.currentUser, isNull);
    });

    test('clearSession borra la sesión persistida (sessionKey)', () async {
      await repo.clearSession();
      verify(() => storage.delete(key: AuthRepository.sessionKey)).called(1);
    });

    test(
      'clearSession CONSERVA la clave de cifrado local (v3-destruir-clave-rompe-log-breakglass)',
      () async {
        when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(),
        ).thenAnswer((_) async => 0);

        await repo.clearSession();

        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );

    test(
      'clearSession NO destruye la clave si quedan pacientes pendientes',
      () async {
        when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 1);
        when(
          () => localDb.getUnsyncedEmergencyLogCount(),
        ).thenAnswer((_) async => 0);

        await repo.clearSession();

        verifyNever(() => localDb.destroyEncryptionKey());
      },
    );

    test('clearSession NO destruye la clave si quedan accesos de emergencia '
        'pendientes, aunque los pacientes ya estén al día', () async {
      when(() => localDb.getUnsyncedCount()).thenAnswer((_) async => 0);
      when(
        () => localDb.getUnsyncedEmergencyLogCount(),
      ).thenAnswer((_) async => 3);

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
        ).thenAnswer((_) async => _validJwt('doc@hwb.org'));
        when(
          () => storage.read(key: AuthRepository.sessionKey),
        ).thenAnswer((_) async => null);
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

    test('sesión persistida corrupta → cae a /me', () async {
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => _validJwt('doc@hwb.org'));
      when(
        () => storage.read(key: AuthRepository.sessionKey),
      ).thenAnswer((_) async => 'not-json-{{{');
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'doc@hwb.org'));

      final session = await repo.restoreSession();

      expect(session?.email, 'doc@hwb.org');
    });

    test('sesión ya cacheada → devuelve sin leer storage', () async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': _validJwt('a@b.com')});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'a@b.com'));

      await repo.login(email: 'a@b.com', password: 'x');
      clearInteractions(storage);

      final session = await repo.restoreSession();

      expect(session?.email, 'a@b.com');
      verifyNever(() => storage.read(key: any(named: 'key')));
    });
  });

  group('session persistence', () {
    test('login persiste la sesión con el rol como wire string', () async {
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': _validJwt('doc@hwb.org')});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => _meResponse(email: 'doc@hwb.org'));

      await repo.login(email: 'doc@hwb.org', password: 'x');

      final List<dynamic> captured = verify(
        () => storage.write(
          key: AuthRepository.sessionKey,
          value: captureAny(named: 'value'),
        ),
      ).captured;
      expect(captured, isNotEmpty);
      final Map<String, dynamic> decoded =
          jsonDecode(captured.last as String) as Map<String, dynamic>;
      expect(decoded['id'], '42');
      expect(decoded['role'], 'doctor');
      expect(decoded['email'], 'doc@hwb.org');
    });
  });

  group('_fetchMe()', () {
    test('getJson exitoso → session con datos completos', () async {
      final jwt = _validJwt('full@hwb.org');
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
      ).thenAnswer((_) async => _meResponse(email: 'full@hwb.org'));

      final session = await repo.login(email: 'full@hwb.org', password: 'p');

      expect(session.email, 'full@hwb.org');
    });

    test('ApiException 404 → fallback a email del JWT', () async {
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

      final session = await repo.login(email: 'jwt@hwb.org', password: 'p');

      expect(session.email, 'jwt@hwb.org');
    });

    test('ApiException 403 → fallback a email del JWT', () async {
      final jwt = _validJwt('forbidden@hwb.org');
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
      ).thenThrow(ApiException('Forbidden', statusCode: 403));

      final session = await repo.login(
        email: 'forbidden@hwb.org',
        password: 'p',
      );

      expect(session.email, 'forbidden@hwb.org');
    });

    test('ApiException con statusCode != 404/403 → se relanza', () async {
      final jwt = _validJwt('err@hwb.org');
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
      ).thenThrow(ApiException('Server error', statusCode: 500));

      expect(
        () => repo.login(email: 'err@hwb.org', password: 'p'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 500)),
      );
    });

    test('excepción genérica en getJson → fallback a email del JWT', () async {
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

      final session = await repo.login(email: 'generic@hwb.org', password: 'p');

      expect(session.email, 'generic@hwb.org');
    });

    test('JWT sin sub → fallback a "user"', () async {
      final jwt = _jwtNoSub();
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

      final session = await repo.login(email: 'x@y.com', password: 'p');

      expect(session.email, 'user');
    });
  });

  group('_emailFromJwt()', () {
    test('JWT con 2 partes (sin firma) → fallback "user"', () async {
      final badJwt = 'header.payload';
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': badJwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(ApiException('Not found', statusCode: 404));

      final session = await repo.login(email: 'x@y.com', password: 'p');

      expect(session.email, 'user');
    });

    test('JWT con payload base64 inválido → fallback "user"', () async {
      final badJwt = 'aaa.!!!.ccc';
      when(
        () => api.postForm(
          path: any(named: 'path'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => {'access_token': badJwt});
      when(
        () => api.getJson(
          path: any(named: 'path'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(ApiException('Not found', statusCode: 404));

      final session = await repo.login(email: 'x@y.com', password: 'p');

      expect(session.email, 'user');
    });

    test('JWT válido con sub extrae email correctamente', () async {
      final jwt = _validJwt('real@email.com');
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

      final session = await repo.login(email: 'real@email.com', password: 'p');

      expect(session.email, 'real@email.com');
    });

    test('JWT payload con sub = null → fallback "user"', () async {
      final jwt = _buildJwt({'sub': null});
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

      final session = await repo.login(email: 'x@y.com', password: 'p');

      expect(session.email, 'user');
    });
  });

  group('Constructor', () {
    test(
      'instancia sin secureStorage usa FlutterSecureStorage por defecto',
      () {
        final r = AuthRepository(apiClient: MockApiClient());
        expect(r, isNotNull);
        expect(r.hasToken, isFalse);
        expect(r.currentUser, isNull);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // getNfcKeyring() — versionado de llaves NFC
  // ───────────────────────────────────────────────────────────────────────────
  group('getNfcKeyring()', () {
    const String keyV0 =
        '0000000000000000000000000000000000000000000000000000000000000000';
    const String keyV1 =
        '1111111111111111111111111111111111111111111111111111111111111111';

    test('login absorbe el anillo y lo deja disponible en memoria', () async {
      when(
        () => api.postForm(path: any(named: 'path'), form: any(named: 'form')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'access_token': _validJwt('doc@hwb.org'),
          'refresh_token': _refreshJwt(),
          'nfc_encryption_key': keyV1,
          'nfc_key_version': 1,
          'nfc_keyring': <String, dynamic>{'0': keyV0, '1': keyV1},
        },
      );
      when(
        () =>
            api.getJson(path: any(named: 'path'), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _meResponse());
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      await repo.login(email: 'doc@hwb.org', password: 'x');

      final ring = await repo.getNfcKeyring();
      expect(ring, isNotNull);
      expect(ring!.currentVersion, 1);
      expect(ring.keyFor(0), keyV0);
      expect(ring.keyFor(1), keyV1);
      // La llave de escritura sigue siendo la versión actual.
      expect(ring.currentKey, keyV1);
    });

    test('el anillo se persiste para que un arranque en frío lo recupere',
        () async {
      when(
        () => api.postForm(path: any(named: 'path'), form: any(named: 'form')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'access_token': _validJwt('doc@hwb.org'),
          'nfc_key_version': 1,
          'nfc_keyring': <String, dynamic>{'0': keyV0, '1': keyV1},
        },
      );
      when(
        () =>
            api.getJson(path: any(named: 'path'), headers: any(named: 'headers')),
      ).thenAnswer((_) async => _meResponse());
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      await repo.login(email: 'doc@hwb.org', password: 'x');

      verify(
        () => storage.write(
          key: AuthRepository.nfcKeyringKey,
          value: any(named: 'value'),
        ),
      ).called(1);
      // La llave suelta queda superada por el anillo.
      verify(() => storage.delete(key: AuthRepository.nfcKeyKey)).called(1);
    });

    test('reconstruye el anillo desde el almacenamiento', () async {
      final stored = jsonEncode(
        NfcKeyring(
          keys: <int, String>{0: keyV0, 1: keyV1},
          currentVersion: 1,
        ).toJson(),
      );
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => stored);
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());

      final ring = await repo.getNfcKeyring();

      expect(ring, isNotNull);
      expect(ring!.versions, <int>[0, 1]);
      expect(ring.currentVersion, 1);
    });

    test(
      'ruta de actualización: una llave suelta previa se lee como versión 0',
      () async {
        when(
          () => storage.read(key: AuthRepository.nfcKeyringKey),
        ).thenAnswer((_) async => null);
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => keyV0);
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt());

        final ring = await repo.getNfcKeyring();

        expect(ring, isNotNull);
        expect(ring!.currentVersion, kLegacyNfcKeyVersion);
        expect(ring.keyFor(0), keyV0);
      },
    );

    test('sin material de llave devuelve null', () async {
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      expect(await repo.getNfcKeyring(), isNull);
    });

    test('clearSession borra el anillo persistido', () async {
      await repo.clearSession();

      verify(() => storage.delete(key: AuthRepository.nfcKeyringKey)).called(1);
    });
  });


  // ───────────────────────────────────────────────────────────────────────────
  // Ventana de sesión de la llave NFC (exp del refresh token)
  // ───────────────────────────────────────────────────────────────────────────
  group('ventana de sesión del anillo NFC', () {
    const String keyV0 =
        '0000000000000000000000000000000000000000000000000000000000000000';

    String storedRing() => jsonEncode(NfcKeyring.single(keyV0).toJson());

    test('dentro de la ventana entrega el anillo', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt(days: 3));

      expect(await repo.getNfcKeyring(), isNotNull);
      expect(await repo.isNfcSessionExpired(), isFalse);
    });

    test('refresh token vencido: no entrega el anillo y lo borra', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt(days: -1));

      expect(await repo.getNfcKeyring(), isNull);
      expect(await repo.isNfcSessionExpired(), isTrue);

      // No basta con negar el acceso: el material se retira del disco.
      verify(
        () => storage.delete(key: AuthRepository.nfcKeyringKey),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => storage.delete(key: AuthRepository.nfcKeyKey),
      ).called(greaterThanOrEqualTo(1));
    });

    test('sin refresh token guardado se rechaza el anillo', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => null);

      // Sin refresh token la sesión no es renovable: se trata como vencida.
      expect(await repo.getNfcKeyring(), isNull);
      expect(await repo.isNfcSessionExpired(), isTrue);
    });

    test('refresh token ilegible se trata como vencido', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => 'no-es-un-jwt');

      expect(await repo.getNfcKeyring(), isNull);
    });

    test('refresh token sin claim exp se trata como vencido', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _buildJwt({'sub': 'doc@hwb.org'}));

      expect(await repo.getNfcKeyring(), isNull);
    });

    test(
      'la ventana también aplica a la llave suelta heredada',
      () async {
        when(
          () => storage.read(key: AuthRepository.nfcKeyringKey),
        ).thenAnswer((_) async => null);
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => keyV0);
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt(days: -1));

        expect(await repo.getNfcKeyring(), isNull);
      },
    );

    test(
      'ni el anillo ni la llave heredada salen fuera de la ventana',
      () async {
        when(
          () => storage.read(key: AuthRepository.nfcKeyringKey),
        ).thenAnswer((_) async => storedRing());
        when(
          () => storage.read(key: AuthRepository.nfcKeyKey),
        ).thenAnswer((_) async => keyV0);
        when(
          () => storage.read(key: AuthRepository.refreshKey),
        ).thenAnswer((_) async => _refreshJwt(days: -1));

        expect(await repo.getNfcKeyring(), isNull);
      },
    );
  });


  // ───────────────────────────────────────────────────────────────────────────
  // Ventana evaluada al restaurar, borrado no perezoso y reloj monótono
  // ───────────────────────────────────────────────────────────────────────────
  group('restoreSession y la ventana de sesión', () {
    const String keyV0 =
        '0000000000000000000000000000000000000000000000000000000000000000';

    String storedRing() => jsonEncode(NfcKeyring.single(keyV0).toJson());

    void stubStorage({required String? refresh, String? ring}) {
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(
        () => storage.read(key: AuthRepository.tokenKey),
      ).thenAnswer((_) async => _validJwt('doc@hwb.org'));
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => refresh);
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => ring);
    }

    test('dentro de la ventana no marca nada', () async {
      stubStorage(refresh: _refreshJwt(), ring: storedRing());

      await repo.restoreSession();

      expect(repo.sessionWindowClosed.value, isFalse);
      // La sesión no se fuerza al login: eso es sessionExpired, otra cosa.
      expect(repo.sessionExpired.value, isFalse);
    });

    test(
      'fuera de la ventana marca el estado pero conserva la sesión',
      () async {
        stubStorage(refresh: _refreshJwt(days: -1), ring: storedRing());

        final session = await repo.restoreSession();

        expect(repo.sessionWindowClosed.value, isTrue);
        // Se conserva el acceso a lo que ya está en el dispositivo: puede
        // haber registros sin sincronizar que la persona necesita ver.
        expect(session, isNotNull);
        expect(repo.sessionExpired.value, isFalse);
      },
    );

    test(
      'el anillo se borra al restaurar, sin esperar a que lo pidan',
      () async {
        stubStorage(refresh: _refreshJwt(days: -1), ring: storedRing());

        await repo.restoreSession();

        // Antes el material seguía en disco hasta que algo llamara a
        // getNfcKeyring(), que podía no ocurrir nunca.
        verify(
          () => storage.delete(key: AuthRepository.nfcKeyringKey),
        ).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('reloj movido hacia atrás', () {
    const String keyV0 =
        '0000000000000000000000000000000000000000000000000000000000000000';

    String storedRing() => jsonEncode(NfcKeyring.single(keyV0).toJson());

    String mark(Duration fromNow) => DateTime.now()
        .toUtc()
        .add(fromNow)
        .millisecondsSinceEpoch
        .toString();

    test('un retroceso dentro de la tolerancia no cierra la ventana', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());
      // La marca quedó 12 h adelante: dentro de las 24 h de holgura para
      // correcciones de NTP o cambios de zona horaria.
      when(
        () => storage.read(key: AuthRepository.clockMarkKey),
      ).thenAnswer((_) async => mark(const Duration(hours: 12)));

      expect(await repo.getNfcKeyring(), isNotNull);
    });

    test('un retroceso mayor a la tolerancia cierra la ventana', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());
      // La marca quedó 10 días adelante del reloj actual: alguien atrasó la
      // fecha para reabrir una ventana ya vencida.
      when(
        () => storage.read(key: AuthRepository.clockMarkKey),
      ).thenAnswer((_) async => mark(const Duration(days: 10)));

      expect(await repo.getNfcKeyring(), isNull);
      expect(await repo.isNfcSessionExpired(), isTrue);
    });

    test('una marca ilegible se ignora', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());
      when(
        () => storage.read(key: AuthRepository.clockMarkKey),
      ).thenAnswer((_) async => 'no-es-un-numero');

      expect(await repo.getNfcKeyring(), isNotNull);
    });

    test('la marca se persiste al evaluar la ventana', () async {
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(
        () => storage.read(key: AuthRepository.nfcKeyringKey),
      ).thenAnswer((_) async => storedRing());
      when(
        () => storage.read(key: AuthRepository.refreshKey),
      ).thenAnswer((_) async => _refreshJwt());

      await repo.getNfcKeyring();

      verify(
        () => storage.write(
          key: AuthRepository.clockMarkKey,
          value: any(named: 'value'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });

}
