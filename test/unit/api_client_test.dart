// test/unit/api_client_test.dart
//
// Exercises the auto-refresh interceptor baked into ApiClient: on a 401 from a
// protected route it renews the access token once (via the injected
// TokenProvider) and replays the request with the fresh bearer. Public routes
// (login / refresh) never trigger a refresh, and without a provider a 401
// simply propagates.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';

void main() {
  const baseUrl = 'https://api.example.com';

  ApiClient buildClient(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ApiClient(baseUrl: baseUrl, client: MockClient(handler));
  }

  // ── ApiException ─────────────────────────────────────────────────────────

  group('ApiException', () {
    test('toString incluye statusCode y message', () {
      final exception = ApiException('algo falló', statusCode: 500);

      expect(
        exception.toString(),
        'ApiException(statusCode: 500, message: algo falló)',
      );
    });

    test('permite statusCode nulo', () {
      final exception = ApiException('sin status');

      expect(exception.statusCode, isNull);
      expect(exception.message, 'sin status');
      expect(
        exception.toString(),
        'ApiException(statusCode: null, message: sin status)',
      );
    });
  });

  // ── Constructor ───────────────────────────────────────────────────────────

  group('ApiClient - constructor', () {
    test('usa un http.Client real cuando no se inyecta uno', () {
      final client = ApiClient(baseUrl: baseUrl);

      expect(client.baseUrl, baseUrl);
    });

    test('usa el client inyectado cuando se provee', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final result = await client.getJson(path: '/ping');

      expect(result, {'ok': true});
    });
  });

  // ── postForm ─────────────────────────────────────────────────────────────

  group('postForm', () {
    test('retorna el mapa decodificado en 2xx', () async {
      final client = buildClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/form');
        expect(request.headers['X-Custom'], 'y');
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final result = await client.postForm(
        path: '/form',
        form: {'a': '1'},
        headers: {'X-Custom': 'y'},
      );

      expect(result, {'ok': true});
    });

    test('lanza ApiException en error con detail', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'detail': 'campo inválido'}), 422);
      });

      await expectLater(
        () => client.postForm(path: '/form', form: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'campo inválido'),
        ),
      );
    });
  });

  // ── postJson ───────────────────────────────────────────────────────────

  group('postJson', () {
    test('retorna el mapa decodificado en 2xx', () async {
      final client = buildClient((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {'name': 'ana'});
        return http.Response(jsonEncode({'id': 1}), 201);
      });

      final result = await client.postJson(
        path: '/patients',
        body: {'name': 'ana'},
      );

      expect(result, {'id': 1});
    });

    test('2xx con body vacío retorna mapa vacío', () async {
      final client = buildClient((request) async => http.Response('', 204));

      final result = await client.postJson(path: '/x', body: {});

      expect(result, <String, dynamic>{});
    });

    test('2xx con payload que no es un mapa lanza ApiException', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode([1, 2, 3]), 200);
      });

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Unexpected response payload format.',
          ),
        ),
      );
    });

    test('2xx con body no-JSON lanza ApiException', () async {
      final client = buildClient((request) async {
        return http.Response('<html>not json</html>', 200);
      });

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'error con body no decodificable usa el fallback por statusCode',
      () async {
        final client = buildClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        await expectLater(
          () => client.postJson(path: '/x', body: {}),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error (HTTP 500)'),
            ),
          ),
        );
      },
    );

    test('error con mapa JSON sin detail usa el fallback (401)', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'other': 'x'}), 401);
      });

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Session expired. Please sign in again.',
          ),
        ),
      );
    });

    test('error con payload no-mapa (lista) usa el fallback (403)', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode([1, 2]), 403);
      });

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Access denied (HTTP 403).',
          ),
        ),
      );
    });

    test('404 usa el mensaje "Not found"', () async {
      final client = buildClient((request) async => http.Response('', 404));

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Not found (HTTP 404).',
          ),
        ),
      );
    });

    test('otro status (ej. 418) usa el mensaje genérico', () async {
      final client = buildClient((request) async => http.Response('', 418));

      await expectLater(
        () => client.postJson(path: '/x', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Request failed (HTTP 418).',
          ),
        ),
      );
    });
  });

  // ── getJson ──────────────────────────────────────────────────────────────

  group('getJson', () {
    test('agrega queryParams y headers, retorna el mapa', () async {
      final client = buildClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.queryParameters, {'q': 'abc'});
        expect(request.headers['X-Token'], 'tok');
        return http.Response(jsonEncode({'found': true}), 200);
      });

      final result = await client.getJson(
        path: '/search',
        queryParams: {'q': 'abc'},
        headers: {'X-Token': 'tok'},
      );

      expect(result, {'found': true});
    });
  });

  // ── getJsonList ─────────────────────────────────────────────────────────

  group('getJsonList', () {
    test('retorna la lista decodificada en 2xx', () async {
      final client = buildClient((request) async {
        expect(request.method, 'GET');
        return http.Response(jsonEncode([1, 2, 3]), 200);
      });

      final result = await client.getJsonList(path: '/items');

      expect(result, [1, 2, 3]);
    });

    test('2xx con body vacío retorna lista vacía', () async {
      final client = buildClient((request) async => http.Response('', 200));

      final result = await client.getJsonList(path: '/items');

      expect(result, <dynamic>[]);
    });

    test('2xx con payload que no es lista lanza ApiException', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'a': 1}), 200);
      });

      await expectLater(
        () => client.getJsonList(path: '/items'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Expected a JSON array but got something else.',
          ),
        ),
      );
    });

    test('2xx con body no-JSON lanza ApiException', () async {
      final client = buildClient((request) async {
        return http.Response('not-json', 200);
      });

      await expectLater(
        () => client.getJsonList(path: '/items'),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'error con detail en el body lanza ApiException con ese mensaje',
      () async {
        final client = buildClient((request) async {
          return http.Response(jsonEncode({'detail': 'no autorizado'}), 401);
        });

        await expectLater(
          () => client.getJsonList(path: '/items'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message', 'no autorizado')
                .having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'error con mapa sin detail usa el fallback por statusCode (500)',
      () async {
        final client = buildClient((request) async {
          return http.Response(jsonEncode({'other': 'x'}), 500);
        });

        await expectLater(
          () => client.getJsonList(path: '/items'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error (HTTP 500)'),
            ),
          ),
        );
      },
    );

    test(
      'error con payload no-mapa (lista) usa el fallback por statusCode (403)',
      () async {
        final client = buildClient((request) async {
          return http.Response(jsonEncode([1, 2]), 403);
        });

        await expectLater(
          () => client.getJsonList(path: '/items'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Access denied (HTTP 403).',
            ),
          ),
        );
      },
    );
  });

  // ── patchJson ────────────────────────────────────────────────────────────

  group('patchJson', () {
    test('retorna el mapa decodificado en 2xx', () async {
      final client = buildClient((request) async {
        expect(request.method, 'PATCH');
        expect(jsonDecode(request.body), {'name': 'nuevo'});
        return http.Response(jsonEncode({'updated': true}), 200);
      });

      final result = await client.patchJson(
        path: '/patients/1',
        body: {'name': 'nuevo'},
      );

      expect(result, {'updated': true});
    });

    test('error lanza ApiException', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'detail': 'no válido'}), 400);
      });

      await expectLater(
        () => client.patchJson(path: '/x', body: {}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── delete ───────────────────────────────────────────────────────────────

  group('delete', () {
    test('2xx sin body no lanza (retorna void)', () async {
      final client = buildClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      });

      await expectLater(client.delete(path: '/patients/1'), completes);
    });

    test(
      'error con detail en el body lanza ApiException con ese mensaje',
      () async {
        final client = buildClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'no se puede borrar'}),
            409,
          );
        });

        await expectLater(
          () => client.delete(path: '/patients/1'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message', 'no se puede borrar')
                .having((e) => e.statusCode, 'statusCode', 409),
          ),
        );
      },
    );

    test('error con body vacío usa el fallback por statusCode', () async {
      final client = buildClient((request) async => http.Response('', 500));

      await expectLater(
        () => client.delete(path: '/patients/1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Server error (HTTP 500)'),
          ),
        ),
      );
    });

    test('error con body no-JSON usa el fallback por statusCode', () async {
      final client = buildClient((request) async {
        return http.Response('<html>error</html>', 502);
      });

      await expectLater(
        () => client.delete(path: '/patients/1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Server error (HTTP 502)'),
          ),
        ),
      );
    });

    test('error con payload JSON que no es mapa usa el fallback', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode([1, 2]), 403);
      });

      await expectLater(
        () => client.delete(path: '/patients/1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Access denied (HTTP 403).',
          ),
        ),
      );
    });

    test('error con mapa sin detail usa el fallback por statusCode', () async {
      final client = buildClient((request) async {
        return http.Response(jsonEncode({'other': 'x'}), 404);
      });

      await expectLater(
        () => client.delete(path: '/patients/1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Not found (HTTP 404).',
          ),
        ),
      );
    });
  });

  group('ApiClient auto-refresh interceptor', () {
    test('on 401 for a protected route: refreshes once and replays the '
        'request with the new token', () async {
      final List<String> sentAuth = <String>[];
      int hits = 0;

      final client = MockClient((http.Request request) async {
        hits++;
        sentAuth.add(request.headers['authorization'] ?? '');
        if (hits == 1) {
          return _json(<String, dynamic>{'detail': 'expired'}, 401);
        }
        return _json(<String, dynamic>{'ok': true}, 200);
      });

      final provider = _FakeTokenProvider('new-token');
      final api = ApiClient(baseUrl: 'https://api.test', client: client)
        ..tokenProvider = provider;

      final result = await api.getJson(
        path: '/api/v1/patients/scan/abc',
        headers: <String, String>{'Authorization': 'Bearer stale-token'},
      );

      expect(result, <String, dynamic>{'ok': true});
      expect(hits, 2);
      expect(provider.calls, 1);
      expect(sentAuth[0], 'Bearer stale-token');
      expect(sentAuth[1], 'Bearer new-token');
    });

    test(
      'on 401 when refresh yields null: does not retry, propagates 401',
      () async {
        int hits = 0;
        final client = MockClient((http.Request request) async {
          hits++;
          return _json(<String, dynamic>{'detail': 'expired'}, 401);
        });

        final provider = _FakeTokenProvider(null);
        final api = ApiClient(baseUrl: 'https://api.test', client: client)
          ..tokenProvider = provider;

        await expectLater(
          api.getJson(
            path: '/api/v1/patients/scan/abc',
            headers: <String, String>{'Authorization': 'Bearer x'},
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
        expect(hits, 1);
        expect(provider.calls, 1);
      },
    );

    test(
      'never refreshes on the public /login/refresh route (no recursion)',
      () async {
        int hits = 0;
        final client = MockClient((http.Request request) async {
          hits++;
          return _json(<String, dynamic>{'detail': 'invalid'}, 401);
        });

        final provider = _FakeTokenProvider('new-token');
        final api = ApiClient(baseUrl: 'https://api.test', client: client)
          ..tokenProvider = provider;

        await expectLater(
          api.postJson(
            path: '/api/v1/login/refresh',
            body: <String, dynamic>{'refresh_token': 'r'},
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
        expect(hits, 1);
        expect(provider.calls, 0);
      },
    );

    test('never refreshes on the public /login/access-token route', () async {
      int hits = 0;
      final client = MockClient((http.Request request) async {
        hits++;
        return _json(<String, dynamic>{'detail': 'bad creds'}, 401);
      });

      final provider = _FakeTokenProvider('new-token');
      final api = ApiClient(baseUrl: 'https://api.test', client: client)
        ..tokenProvider = provider;

      await expectLater(
        api.postForm(
          path: '/api/v1/login/access-token',
          form: <String, String>{'username': 'u', 'password': 'p'},
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(hits, 1);
      expect(provider.calls, 0);
    });

    test('without a token provider, a 401 propagates unchanged', () async {
      int hits = 0;
      final client = MockClient((http.Request request) async {
        hits++;
        return _json(<String, dynamic>{'detail': 'expired'}, 401);
      });

      final api = ApiClient(baseUrl: 'https://api.test', client: client);

      await expectLater(
        api.getJson(
          path: '/api/v1/users/me',
          headers: <String, String>{'Authorization': 'Bearer x'},
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(hits, 1);
    });

    test('a successful response never triggers a refresh', () async {
      int hits = 0;
      final client = MockClient((http.Request request) async {
        hits++;
        return _json(<String, dynamic>{'ok': true}, 200);
      });

      final provider = _FakeTokenProvider('new-token');
      final api = ApiClient(baseUrl: 'https://api.test', client: client)
        ..tokenProvider = provider;

      final r = await api.getJson(path: '/api/v1/users/me');
      expect(r, <String, dynamic>{'ok': true});
      expect(hits, 1);
      expect(provider.calls, 0);
    });

    test('if the replay also returns 401, it surfaces without a second '
        'refresh (no loop)', () async {
      int hits = 0;
      final client = MockClient((http.Request request) async {
        hits++;
        return _json(<String, dynamic>{'detail': 'still expired'}, 401);
      });

      final provider = _FakeTokenProvider('new-token');
      final api = ApiClient(baseUrl: 'https://api.test', client: client)
        ..tokenProvider = provider;

      await expectLater(
        api.postJson(
          path: '/api/v1/patients/sync',
          body: <String, dynamic>{'x': 1},
          headers: <String, String>{'Authorization': 'Bearer x'},
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(hits, 2);
      expect(provider.calls, 1);
    });
  });

  group('Redirecciones — el Bearer no debe salir del host del backend', () {
    test('un 3xx cross-host aborta con ApiException', () async {
      final capturedHosts = <String>[];

      final client = ApiClient(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          capturedHosts.add(request.url.host);
          if (request.url.host == 'api.example.com') {
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://exfil.example/api/v1/patients/sync',
              },
            );
          }
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }),
      );

      await expectLater(
        client.postJson(
          path: '/api/v1/patients/sync',
          body: const {'patientId': 'p-1'},
          headers: const {'Authorization': 'Bearer jwt-del-clinico'},
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 302),
        ),
      );

      expect(capturedHosts, ['api.example.com']);
      expect(capturedHosts, isNot(contains('exfil.example')));
    });
  });
}

// Helpers used by the tests below ------------------------------------------------

http.Response _json(Map<String, dynamic> body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class _FakeTokenProvider implements TokenProvider {
  _FakeTokenProvider(this.token);

  final String? token;
  int calls = 0;

  @override
  Future<String?> refreshAccessToken() async {
    calls++;
    return token;
  }
}
