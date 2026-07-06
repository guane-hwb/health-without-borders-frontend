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

class _FakeTokenProvider implements TokenProvider {
  _FakeTokenProvider(this._result);

  final String? _result;
  int calls = 0;

  @override
  Future<String?> refreshAccessToken() async {
    calls++;
    return _result;
  }
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

void main() {
  group('ApiClient auto-refresh interceptor', () {
    test('on 401 for a protected route: refreshes once and replays the '
        'request with the new token', () async {
      final List<String> sentAuth = <String>[];
      int hits = 0;

      final client = MockClient((http.Request request) async {
        hits++;
        sentAuth.add(request.headers['authorization'] ?? '');
        if (hits == 1) return _json(<String, dynamic>{'detail': 'expired'}, 401);
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

    test('on 401 when refresh yields null: does not retry, propagates 401',
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
    });

    test('never refreshes on the public /login/refresh route (no recursion)',
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
    });

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
      expect(hits, 2); // original + exactly one replay
      expect(provider.calls, 1); // refreshed once, no loop
    });
  });
}
