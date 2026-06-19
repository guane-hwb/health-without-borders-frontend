// test/unit/auth/auth_repository_test.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

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

Map<String, dynamic> _meResponse({String email = 'doc@hwb.org'}) => {
  'email': email,
  'id': '42',
  'role': 'doctor',
  'full_name': 'Doctor Test',
};

AuthRepository _makeRepo({
  required MockApiClient api,
  required MockSecureStorage storage,
}) => AuthRepository(apiClient: api, secureStorage: storage);

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late MockApiClient api;
  late MockSecureStorage storage;
  late AuthRepository repo;

  setUp(() {
    api = MockApiClient();
    storage = MockSecureStorage();
    repo = _makeRepo(api: api, storage: storage);

    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
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
      'login también persiste nfc_encryption_key cuando está presente',
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

        verify(
          () => storage.write(
            key: AuthRepository.nfcKeyKey,
            value: 'super-secret-nfc',
          ),
        ).called(1);
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

    //   test(
    //     'sin sesión y _fetchMe lanza excepción genérica → devuelve null',
    //     () async {
    //       final jwt = _validJwt('x@y.com');
    //       when(
    //         () => storage.read(key: AuthRepository.tokenKey),
    //       ).thenAnswer((_) async => jwt);
    //       when(
    //         () => api.getJson(
    //           path: any(named: 'path'),
    //           headers: any(named: 'headers'),
    //         ),
    //       ).thenThrow(Exception('unexpected'));

    //       final user = await repo.getCurrentUser();

    //       expect(user, isNull);
    //     },
    //   );
    // });
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
  // getNfcEncryptionKey()
  // ───────────────────────────────────────────────────────────────────────────
  group('getNfcEncryptionKey()', () {
    test('devuelve la clave almacenada', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => 'my-nfc-key');

      final key = await repo.getNfcEncryptionKey();

      expect(key, 'my-nfc-key');
    });

    test('devuelve null cuando no hay clave', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenAnswer((_) async => null);

      final key = await repo.getNfcEncryptionKey();

      expect(key, isNull);
    });

    test('storage lanza excepción → devuelve null (silenciado)', () async {
      when(
        () => storage.read(key: AuthRepository.nfcKeyKey),
      ).thenThrow(Exception('hardware error'));

      final key = await repo.getNfcEncryptionKey();

      expect(key, isNull);
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

      // _emailFromJwt devuelve null → UserSession.fromEmail('user')
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
}
