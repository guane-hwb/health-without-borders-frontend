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
}
