// test/unit/reachability_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

void main() {
  const baseUrl = 'https://api.example.com';

  group('Reachability', () {
    test(
      'usa un http.Client real cuando no se inyecta uno (constructor por defecto)',
      () {
        final reachability = Reachability(baseUrl: baseUrl);

        expect(reachability.baseUrl, baseUrl);
      },
    );

    test(
      'retorna true cuando el servidor responde 2xx y content-type incluye application/json',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), '$baseUrl/health-check');
          return http.Response(
            '{"status":"ok"}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final reachability = Reachability(baseUrl: baseUrl, client: client);
        final isReachable = await reachability.probe();

        expect(isReachable, isTrue);
      },
    );

    test('retorna false si el statusCode es menor a 200 (ej. 100)', () async {
      final client = MockClient((request) async {
        return http.Response(
          '',
          100,
          headers: {'content-type': 'application/json'},
        );
      });

      final reachability = Reachability(baseUrl: baseUrl, client: client);
      final isReachable = await reachability.probe();

      expect(isReachable, isFalse);
    });

    test(
      'retorna false si el statusCode es mayor o igual a 300 (ej. 500)',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            'Error',
            500,
            headers: {'content-type': 'application/json'},
          );
        });

        final reachability = Reachability(baseUrl: baseUrl, client: client);
        final isReachable = await reachability.probe();

        expect(isReachable, isFalse);
      },
    );

    test(
      'retorna false si el content-type NO contiene application/json',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            'OK',
            200,
            headers: {'content-type': 'text/html'},
          );
        });

        final reachability = Reachability(baseUrl: baseUrl, client: client);
        final isReachable = await reachability.probe();

        expect(isReachable, isFalse);
      },
    );

    test('retorna false si el header content-type no está presente', () async {
      final client = MockClient((request) async {
        return http.Response('OK', 200, headers: {});
      });

      final reachability = Reachability(baseUrl: baseUrl, client: client);
      final isReachable = await reachability.probe();

      expect(isReachable, isFalse);
    });

    test(
      'retorna false y captura la excepción cuando ocurre un error de red/timeout',
      () async {
        final client = MockClient((request) async {
          throw TimeoutException('Sonda agotó el tiempo de espera');
        });

        final reachability = Reachability(baseUrl: baseUrl, client: client);
        final isReachable = await reachability.probe();

        expect(isReachable, isFalse);
      },
    );
  });
}
