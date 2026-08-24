// test/unit/stats_repository_test.dart
//
// Exercises StatsRepository against a mock HTTP client: query-string
// construction, response parsing, and the translation of transport failures
// into StatsUnavailableException.
//
// That translation is the reason this class exists rather than the screen
// calling ApiClient directly. The presentation layer must not import
// `dart:io` — this app also builds for web, where the library is absent — so
// a SocketException can never be allowed to reach it.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';

const String _baseUrl = 'https://api.example.com';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(apiClient: ApiClient(baseUrl: _baseUrl));

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async => 'tok-123';
}

Map<String, dynamic> _payload() => <String, dynamic>{
  'scope': {'organization_id': 'o1', 'organization_name': 'Org A'},
  'generated_at': '2026-07-09T14:22:01-05:00',
  'window': {'date_from': null, 'date_to': null},
  'totals': {
    'patients': 12,
    'patients_with_birth_date': 10,
    'minors': 4,
    'minors_pct': 40.0,
    'vaccine_doses': 30,
    'allergies': 5,
    'encounters': 8,
  },
  'trend': {
    'period': 'month',
    'patients': {'current': 3, 'previous': 0, 'delta_pct': null},
    'vaccine_doses': {'current': 9, 'previous': 4, 'delta_pct': 125.0},
    'encounters': {'current': 2, 'previous': 2, 'delta_pct': 0.0},
  },
  'vaccines': [
    {'code': '141', 'name': 'Influenza', 'count': 20},
  ],
  'allergies': [
    {'allergen': 'Maní', 'category': '02', 'count': 3},
  ],
  'allergies_others': 1,
  'nationalities': [
    {'code': 'COL', 'count': 9},
  ],
  'nationalities_others': 2,
};

StatsRepository _repo(
  Future<http.Response> Function(http.Request request) handler, {
  List<Uri>? captured,
}) {
  final client = MockClient((request) {
    captured?.add(request.url);
    return handler(request);
  });
  return StatsRepository(
    apiClient: ApiClient(baseUrl: _baseUrl, client: client),
    authRepository: _FakeAuthRepository(),
  );
}

http.Response _ok() => http.Response(
  jsonEncode(_payload()),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('formatDate', () {
    test('zero-pads month and day', () {
      expect(StatsRepository.formatDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(StatsRepository.formatDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('fetchOverview — request', () {
    test('sends no query parameters when nothing is scoped', () async {
      final captured = <Uri>[];
      final repo = _repo((_) async => _ok(), captured: captured);

      await repo.fetchOverview();

      expect(captured.single.path, '/api/v1/stats/overview');
      expect(captured.single.queryParameters, isEmpty);
    });

    test('sends organization_id when a superadmin scopes the view', () async {
      final captured = <Uri>[];
      final repo = _repo((_) async => _ok(), captured: captured);

      await repo.fetchOverview(organizationId: 'org-42');

      expect(captured.single.queryParameters, {'organization_id': 'org-42'});
    });

    test('sends the date window in yyyy-MM-dd', () async {
      final captured = <Uri>[];
      final repo = _repo((_) async => _ok(), captured: captured);

      await repo.fetchOverview(
        dateFrom: DateTime(2026, 6, 1),
        dateTo: DateTime(2026, 6, 30),
      );

      expect(captured.single.queryParameters, {
        'date_from': '2026-06-01',
        'date_to': '2026-06-30',
      });
    });

    test('sends the bearer token', () async {
      String? auth;
      final repo = _repo((request) async {
        auth = request.headers['Authorization'];
        return _ok();
      });

      await repo.fetchOverview();

      expect(auth, 'Bearer tok-123');
    });
  });

  group('fetchOverview — response', () {
    test('parses the payload into a BrigadeStats', () async {
      final repo = _repo((_) async => _ok());

      final stats = await repo.fetchOverview();

      expect(stats.scope.organizationName, 'Org A');
      expect(stats.totals.patients, 12);
      expect(stats.totals.encounters, 8);
      expect(stats.trend.patients.deltaPct, isNull);
      expect(stats.trend.vaccineDoses.deltaPct, closeTo(125.0, 0.001));
      expect(stats.vaccines.single.name, 'Influenza');
      expect(stats.nationalitiesOthers, 2);
      expect(stats.isEmpty, isFalse);
    });
  });

  group('fetchOverview — failures', () {
    test('a 403 surfaces as an ApiException, not as unavailability', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode({'detail': 'Not enough privileges to view statistics.'}),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        repo.fetchOverview(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('a transport failure becomes StatsUnavailableException', () async {
      final repo = _repo((_) async => throw http.ClientException('no route'));

      await expectLater(
        repo.fetchOverview(),
        throwsA(isA<StatsUnavailableException>()),
      );
    });

    test('a timeout becomes StatsUnavailableException', () async {
      final repo = _repo((_) async => throw TimeoutException('slow'));

      await expectLater(
        repo.fetchOverview(),
        throwsA(isA<StatsUnavailableException>()),
      );
    });

    test('the original cause is preserved for logging', () async {
      final repo = _repo((_) async => throw http.ClientException('no route'));

      try {
        await repo.fetchOverview();
        fail('expected StatsUnavailableException');
      } on StatsUnavailableException catch (e) {
        expect(e.cause, isA<http.ClientException>());
        expect(e.toString(), contains('no route'));
      }
    });
  });
}
