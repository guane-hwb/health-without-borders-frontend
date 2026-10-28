// test/unit/api_client_logout_no_refresh_test.dart
//
// fe-oct26-logout-deja-refresh-rotado: /logout con el access caducado no debe
// disparar el refresco automático (rotaría el refresh sin revocar el nuevo).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _CountingTokenProvider implements TokenProvider {
  int refreshCalls = 0;

  @override
  Future<String?> refreshAccessToken() async {
    refreshCalls++;
    return 'new-access-token';
  }
}

void main() {
  late _CountingTokenProvider tokens;

  ApiClient clientAnswering(http.Response Function(http.Request) handler) {
    final ApiClient client = ApiClient(
      baseUrl: 'https://api.example.org',
      client: MockClient((http.Request r) async => handler(r)),
    );
    client.tokenProvider = tokens;
    return client;
  }

  setUp(() => tokens = _CountingTokenProvider());

  test('un 401 en /logout no refresca el token ni reintenta', () async {
    int requests = 0;
    final ApiClient client = clientAnswering((http.Request r) {
      requests++;
      return http.Response(
        jsonEncode(<String, String>{'detail': 'expired'}),
        401,
      );
    });

    await expectLater(
      client.postJson(
        path: '/api/v1/logout',
        body: <String, dynamic>{'refresh_token': 'old-refresh'},
        headers: <String, String>{'Authorization': 'Bearer expired'},
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );

    expect(tokens.refreshCalls, 0);
    expect(requests, 1);
  });

  test(
    'control: un 401 en una ruta normal sí refresca y reintenta una vez',
    () async {
      int requests = 0;
      final ApiClient client = clientAnswering((http.Request r) {
        requests++;
        if (r.headers['Authorization'] == 'Bearer new-access-token') {
          return http.Response(jsonEncode(<String, dynamic>{'ok': true}), 200);
        }
        return http.Response(
          jsonEncode(<String, String>{'detail': 'expired'}),
          401,
        );
      });

      final Map<String, dynamic> result = await client.getJson(
        path: '/api/v1/patients',
        headers: <String, String>{'Authorization': 'Bearer expired'},
      );

      expect(result['ok'], true);
      expect(tokens.refreshCalls, 1);
      expect(requests, 2);
    },
  );
}
