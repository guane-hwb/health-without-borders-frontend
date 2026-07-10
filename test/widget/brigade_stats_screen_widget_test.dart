// test/widget/brigade_stats_screen_widget_test.dart
//
// Widget tests for BrigadeStatsScreen against a fake StatsRepository.
//
// The screen previously fell back to hard-coded figures whenever the API threw,
// which meant a 403 rendered 1,284 imaginary patients. These tests pin the
// failure paths so that can never come back.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/domain/brigade_stats.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/brigade_stats_screen.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

// ============================================================================
// FAKES
// ============================================================================

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(apiClient: _NoOpApiClient());

  @override
  UserSession? get currentUser => null;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'fake-token';
}

class FakeUserRepository extends UserRepository {
  FakeUserRepository({required this.orgsResult})
    : super(apiClient: _NoOpApiClient(), authRepository: _FakeAuthRepository());

  final Object orgsResult;
  int callCount = 0;

  @override
  Future<List<OrgSummary>> listOrganizations() async {
    callCount++;
    final result = orgsResult;
    if (result is Future<List<OrgSummary>>) return result;
    if (result is Exception) throw result;
    return result as List<OrgSummary>;
  }
}

/// Extends rather than implements, so a new method on [StatsRepository] does
/// not silently leave this fake unimplemented.
class FakeStatsRepository extends StatsRepository {
  FakeStatsRepository(this.result)
    : super(apiClient: _NoOpApiClient(), authRepository: _FakeAuthRepository());

  /// A [BrigadeStats] to return, or an [Object] to throw.
  final Object result;

  int callCount = 0;
  final List<String?> requestedOrgIds = <String?>[];

  @override
  Future<BrigadeStats> fetchOverview({
    String? organizationId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    callCount++;
    requestedOrgIds.add(organizationId);
    final r = result;
    if (r is BrigadeStats) return r;
    throw r;
  }
}

class _FakePatientRepository extends PatientRepository {
  _FakePatientRepository()
    : super(apiClient: _NoOpApiClient(), authRepository: _FakeAuthRepository());
}

class _FakeLocalDatabase implements LocalDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncEngine extends SyncEngine {
  _FakeSyncEngine()
    : super(
        patientRepository: _FakePatientRepository(),
        localDatabase: _FakeLocalDatabase(),
      );
}

// ============================================================================
// FIXTURES
// ============================================================================

OrgSummary _org(String id, String name) =>
    OrgSummary(id: id, name: name, isActive: true);

BrigadeStats _stats({
  int patients = 1284,
  Object? patientsDelta = 11.8,
  String period = 'month',
  int vaccineDoses = 847,
  int allergies = 203,
  int encounters = 512,
  int allergiesOthers = 0,
  int nationalitiesOthers = 0,
}) => BrigadeStats.fromJson(<String, dynamic>{
  'scope': {'organization_id': null, 'organization_name': null},
  'generated_at': '2026-07-09T14:22:01-05:00',
  'window': {'date_from': null, 'date_to': null},
  'totals': {
    'patients': patients,
    'patients_with_birth_date': 1240,
    'minors': 384,
    'minors_pct': 31.0,
    'vaccine_doses': vaccineDoses,
    'allergies': allergies,
    'encounters': encounters,
  },
  'trend': {
    'period': period,
    'patients': {'current': 142, 'previous': 127, 'delta_pct': patientsDelta},
    'vaccine_doses': {'current': 98, 'previous': 90, 'delta_pct': 8.9},
    'encounters': {'current': 61, 'previous': 70, 'delta_pct': -12.9},
  },
  'vaccines': [
    {'code': '141', 'name': 'Influenza Trivalente', 'count': 312},
    {'code': '208', 'name': 'COVID-19 (ARNm)', 'count': 228},
  ],
  'allergies': [
    {'allergen': 'Ibuprofeno', 'category': '01', 'count': 41},
    {'allergen': 'Mariscos', 'category': '02', 'count': 29},
  ],
  'allergies_others': allergiesOthers,
  'nationalities': [
    {'code': 'COL', 'count': 542},
    {'code': 'VEN', 'count': 489},
  ],
  'nationalities_others': nationalitiesOthers,
});

BrigadeStats _emptyStats() => BrigadeStats.fromJson(<String, dynamic>{});

// ============================================================================
// HELPERS
// ============================================================================

/// Widening the surface is what makes "does this render" assertions mean what
/// they say, but a ListView is still lazy — see [_settle] for the rest.
Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(screen);
  await tester.pumpAndSettle();
}


/// Scrolls the screen's ListView until [finder] is on screen, then asserts it.
///
/// A ListView is lazy: widening the test surface is not enough, because the
/// viewport height comes from the Scaffold, not the surface, so off-screen
/// rows are never built. This drives the scrollable the way a user would.
Future<void> _expectAfterScroll(WidgetTester tester, Finder finder) async {
  // If the row is already on screen, scrollUntilVisible would have nothing to
  // do and can throw; only scroll when it is genuinely off screen.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
}

Widget _buildScreen({
  required FakeUserRepository userRepo,
  required FakeStatsRepository statsRepo,
  bool scopeToOwnOrganization = false,
  String locale = 'es',
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: AppScope(
      authRepository: _FakeAuthRepository(),
      userRepository: userRepo,
      patientRepository: _FakePatientRepository(),
      localDatabase: _FakeLocalDatabase(),
      syncEngine: _FakeSyncEngine(),
      statsRepository: statsRepo,
      child: MaterialApp(
        home: BrigadeStatsScreen(
          scopeToOwnOrganization: scopeToOwnOrganization,
        ),
      ),
    ),
  );
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  group('superadmin view', () {
    testWidgets('renders the figures returned by the API', (tester) async {
      final statsRepo = FakeStatsRepository(_stats());
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: [_org('o1', 'Org A')]),
          statsRepo: statsRepo,
        ),
      );

      expect(statsRepo.callCount, 1);
      expect(statsRepo.requestedOrgIds, [null]);
      // Above the fold.
      expect(find.text('1.3K'), findsOneWidget); // 1284 patients
      expect(find.text('31%'), findsOneWidget); // minors_pct
      // Further down the ListView; scroll each into view before asserting.
      await _expectAfterScroll(tester, find.text('Influenza Trivalente'));
      await _expectAfterScroll(tester, find.text('Ibuprofeno (41)'));
      await _expectAfterScroll(tester, find.text('Colombia'));
    });

    testWidgets('shows the organization filter with an "all" chip', (
      tester,
    ) async {
      final userRepo = FakeUserRepository(
        orgsResult: [_org('o1', 'Org A'), _org('o2', 'Org B')],
      );
      await _pump(
        tester,
        _buildScreen(userRepo: userRepo, statsRepo: FakeStatsRepository(_stats())),
      );

      expect(userRepo.callCount, 1);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Org A'), findsOneWidget);
      expect(find.text('Org B'), findsOneWidget);
    });

    testWidgets('tapping an organization chip refetches scoped to that org', (
      tester,
    ) async {
      final statsRepo = FakeStatsRepository(_stats());
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: [_org('o2', 'Org B')]),
          statsRepo: statsRepo,
        ),
      );

      await tester.tap(find.text('Org B'));
      await tester.pumpAndSettle();

      expect(statsRepo.callCount, 2);
      expect(statsRepo.requestedOrgIds, [null, 'o2']);
    });

    testWidgets('re-tapping the selected chip does not refetch', (tester) async {
      final statsRepo = FakeStatsRepository(_stats());
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: [_org('o1', 'Org A')]),
          statsRepo: statsRepo,
        ),
      );

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();

      expect(statsRepo.callCount, 1);
    });
  });

  group('org_admin view', () {
    testWidgets('hides the filter and never lists organizations', (
      tester,
    ) async {
      final userRepo = FakeUserRepository(
        orgsResult: Exception('listOrganizations must not be called'),
      );
      final statsRepo = FakeStatsRepository(_stats());

      await _pump(
        tester,
        _buildScreen(
          userRepo: userRepo,
          statsRepo: statsRepo,
          scopeToOwnOrganization: true,
        ),
      );

      // listOrganizations is superadmin-only; calling it would answer 403.
      expect(userRepo.callCount, 0);
      expect(find.text('Todas'), findsNothing);
      expect(statsRepo.requestedOrgIds, [null]);
      expect(find.text('1.3K'), findsOneWidget);
    });

    testWidgets('uses the organization-scoped title', (tester) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats()),
          scopeToOwnOrganization: true,
        ),
      );

      expect(find.text('Estadísticas de mi Organización'), findsOneWidget);
      expect(find.text('Estadísticas Globales'), findsNothing);
    });
  });

  group('trend sub-labels', () {
    testWidgets('a real delta renders with a direction arrow', (tester) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(patientsDelta: 11.8)),
        ),
      );

      expect(find.text('↑ 11.8% vs. mes anterior'), findsOneWidget);
      expect(find.text('↓ 12.9% vs. mes anterior'), findsOneWidget);
    });

    testWidgets('a null delta renders an em dash, never a fabricated percent', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(patientsDelta: null)),
        ),
      );

      expect(find.text('— sin referencia previa'), findsOneWidget);
      expect(find.text('↑ 100.0% vs. mes anterior'), findsNothing);
    });

    testWidgets('a custom window compares against the previous period', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(period: 'custom')),
        ),
      );

      expect(find.text('↑ 11.8% vs. período anterior'), findsOneWidget);
      expect(find.textContaining('vs. mes anterior'), findsNothing);
    });
  });

  group('failure states', () {
    testWidgets('a 403 shows the forbidden message and no retry button', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(
            ApiException('Not enough privileges', statusCode: 403),
          ),
        ),
      );

      expect(
        find.text('Tu rol no tiene acceso a las estadísticas.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
      // The mock must never resurface.
      expect(find.text('1.3K'), findsNothing);
    });

    testWidgets('an unreachable backend shows the offline hint and a retry', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(
            StatsUnavailableException('no route to host'),
          ),
        ),
      );

      expect(find.textContaining('requieren conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      // The mock must never resurface.
      expect(find.text('1.3K'), findsNothing);
    });

    testWidgets('a 500 surfaces the backend detail and offers a retry', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(
            ApiException('boom', statusCode: 500),
          ),
        ),
      );

      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('retry re-invokes the repository', (tester) async {
      final statsRepo = FakeStatsRepository(
        ApiException('boom', statusCode: 500),
      );
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: statsRepo,
        ),
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(statsRepo.callCount, 2);
    });
  });

  group('empty state', () {
    testWidgets('an organization with no data shows a message, not zeroed bars', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_emptyStats()),
          scopeToOwnOrganization: true,
        ),
      );

      expect(find.text('Aún no hay datos para este período.'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('truncated buckets', () {
    testWidgets('allergies_others renders as a "+N más" chip', (tester) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(allergiesOthers: 7)),
        ),
      );

      await _expectAfterScroll(tester, find.text('+7 más'));
    });

    testWidgets('nationalities_others renders as an "Otros" row', (
      tester,
    ) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(nationalitiesOthers: 12)),
        ),
      );

      await _expectAfterScroll(tester, find.text('Otros'));
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('a zero others bucket adds no row or chip', (tester) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats()),
        ),
      );

      expect(find.text('Otros'), findsNothing);
      expect(find.textContaining('más'), findsNothing);
    });
  });

  group('localization', () {
    testWidgets('English locale renders English sub-labels', (tester) async {
      await _pump(
        tester,
        _buildScreen(
          userRepo: FakeUserRepository(orgsResult: <OrgSummary>[]),
          statsRepo: FakeStatsRepository(_stats(patientsDelta: null)),
          locale: 'en',
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('— no prior data'), findsOneWidget);
    });
  });
}
