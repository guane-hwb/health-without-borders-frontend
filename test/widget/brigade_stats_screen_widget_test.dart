// test/widget/brigade_stats_screen_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/brigade_stats_screen.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

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
// HELPERS
// ============================================================================

Widget _buildScreen(FakeUserRepository userRepo, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: AppScope(
      authRepository: _FakeAuthRepository(),
      userRepository: userRepo,
      patientRepository: _FakePatientRepository(),
      localDatabase: _FakeLocalDatabase(),
      syncEngine: _FakeSyncEngine(),
      child: const MaterialApp(home: BrigadeStatsScreen()),
    ),
  );
}

OrgSummary _org(String id, String name) =>
    OrgSummary(id: id, name: name, isActive: true);

// ============================================================================
// TESTS
// ============================================================================

void main() {
  void configureMobileScreenSize(WidgetTester tester) {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      412 * 3,
      892 * 3,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  }

  group('BrigadeStatsScreen · estado loading', () {
    testWidgets(
      'muestra CircularProgressIndicator mientras la carga está en vuelo',
      (tester) async {
        configureMobileScreenSize(tester);
        final completer = Completer<List<OrgSummary>>();
        final repo = FakeUserRepository(orgsResult: completer.future);

        await tester.pumpWidget(_buildScreen(repo));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete([]);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('NO muestra secciones de stats durante loading', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final completer = Completer<List<OrgSummary>>();
      final repo = FakeUserRepository(orgsResult: completer.future);

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.tabSummary.toUpperCase()), findsNothing);
      expect(find.text(s.statsVaccineDistribution.toUpperCase()), findsNothing);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('muestra el título de pantalla durante loading', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final completer = Completer<List<OrgSummary>>();
      final repo = FakeUserRepository(orgsResult: completer.future);

      await tester.pumpWidget(_buildScreen(repo));

      final s = AppStrings.forTesting('es');
      expect(find.text(s.statsScreenTitle), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('BrigadeStatsScreen · estado error genérico', () {
    testWidgets('muestra ícono error_outline', (tester) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('Network failure'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('muestra el mensaje del error', (tester) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('Network failure'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Network failure'), findsOneWidget);
    });

    testWidgets('muestra botón "Reintentar" con ícono refresh', (tester) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('fallo'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tap en Reintentar vuelve a llamar listOrganizations', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('fallo'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final callsAntes = repo.callCount;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repo.callCount, greaterThan(callsAntes));
    });

    testWidgets('NO muestra secciones del dashboard en estado error', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('fallo'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.tabSummary.toUpperCase()), findsNothing);
    });

    testWidgets('NO muestra CircularProgressIndicator tras error', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: Exception('fallo'));
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('BrigadeStatsScreen · ApiException silenciosa', () {
    testWidgets('NO muestra pantalla de error cuando lanza ApiException', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: ApiException('Not Found', statusCode: 404),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('muestra las stats mock tras ApiException', (tester) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: ApiException('Not Found', statusCode: 404),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('1.3K'), findsOneWidget);
    });

    testWidgets('muestra secciones del dashboard tras ApiException', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: ApiException('Server Error', statusCode: 500),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.tabSummary.toUpperCase()), findsOneWidget);
    });

    testWidgets('no lanza excepción no controlada con ApiException', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: ApiException('error', statusCode: 403),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
  group('BrigadeStatsScreen · estado éxito · estructura', () {
    late FakeUserRepository repo;
    setUp(() => repo = FakeUserRepository(orgsResult: <OrgSummary>[]));

    testWidgets('muestra RefreshIndicator', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('muestra los 4 títulos de sección en mayúsculas', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.tabSummary.toUpperCase()), findsOneWidget);
      expect(
        find.text(s.statsVaccineDistribution.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(s.statsAllergyDistribution.toUpperCase()),
        findsOneWidget,
      );

      final verticalScroll = find.byType(Scrollable).first;
      final targetTitle = find.text(
        s.statsNationalityDistribution.toUpperCase(),
      );
      await tester.scrollUntilVisible(
        targetTitle,
        150.0,
        scrollable: verticalScroll,
      );

      expect(targetTitle, findsOneWidget);
    });

    testWidgets('_SectionTitle usa toUpperCase (versión mixta no existe)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.tabSummary), findsNothing);
      expect(find.text(s.tabSummary.toUpperCase()), findsOneWidget);
    });

    testWidgets('NO muestra spinner después de cargar', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('_KpiGrid · tarjetas KPI', () {
    late FakeUserRepository repo;
    setUp(() => repo = FakeUserRepository(orgsResult: <OrgSummary>[]));

    testWidgets('valor pacientes formateado "1.3K"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('1.3K'), findsOneWidget);
    });

    testWidgets('label "Pacientes atendidos"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.statsTotalPatients), findsOneWidget);
    });

    testWidgets('subtexto "↑ 12% este mes"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('↑ 12% este mes'), findsOneWidget);
    });

    testWidgets('valor vacunas "847" (sin K)', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('847'), findsOneWidget);
    });

    testWidgets('label "Vacunas administradas"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.statsTotalVaccines), findsOneWidget);
    });

    testWidgets('subtexto "en 5 tipos"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('en 5 tipos'), findsOneWidget);
    });

    testWidgets('valor alergias "203"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('203'), findsOneWidget);
    });

    testWidgets('label "Alergias registradas"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.statsTotalAllergies), findsOneWidget);
    });

    testWidgets('porcentaje de menores "31%"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('31%'), findsOneWidget);
    });

    testWidgets('label "Menores de edad"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.statsMinorsPercentage), findsOneWidget);
    });

    testWidgets('subtexto menores "398 pacientes" (round de 1284×31%)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('398 pacientes'), findsOneWidget);
    });

    testWidgets('los 4 íconos de KpiCard están presentes', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.vaccines), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });
  });

  group('_VaccineBarChart · barras de vacunas', () {
    late FakeUserRepository repo;
    setUp(() => repo = FakeUserRepository(orgsResult: <OrgSummary>[]));

    testWidgets('muestra los 5 nombres de vacuna', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Influenza Trivalente'), findsOneWidget);
      expect(find.text('COVID-19 (ARNm)'), findsOneWidget);
      expect(find.text('Hepatitis B'), findsOneWidget);
      expect(find.text('Sarampión (MMR)'), findsOneWidget);
      expect(find.text('Fiebre Amarilla'), findsOneWidget);
    });

    testWidgets('muestra los 5 conteos de vacunas', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('312'), findsAtLeastNWidgets(1));
      expect(find.text('228'), findsOneWidget);
      expect(find.text('147'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
    });

    testWidgets('renderiza exactamente 5 LinearProgressIndicator', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
    });
  });

  group('_AllergyChips · chips de alergias', () {
    late FakeUserRepository repo;
    setUp(() => repo = FakeUserRepository(orgsResult: <OrgSummary>[]));

    testWidgets('muestra los 8 chips con formato "Nombre (count)"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofeno (41)'), findsOneWidget);
      expect(find.text('Penicilina (38)'), findsOneWidget);
      expect(find.text('Mariscos (29)'), findsOneWidget);
      expect(find.text('Maní (24)'), findsOneWidget);
      expect(find.text('Polen (18)'), findsOneWidget);
      expect(find.text('Polvo (15)'), findsOneWidget);
      expect(find.text('Látex (12)'), findsOneWidget);
      expect(find.text('Picadura insecto (9)'), findsOneWidget);
    });
  });

  group('_NationalityList · lista de procedencia', () {
    late FakeUserRepository repo;
    setUp(() => repo = FakeUserRepository(orgsResult: <OrgSummary>[]));

    testWidgets('muestra los 5 países', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final targetCountry = find.text('Colombia');
      await tester.scrollUntilVisible(
        targetCountry,
        150.0,
        scrollable: find.byType(Scrollable).first,
      );

      expect(targetCountry, findsOneWidget);
      expect(find.text('Venezuela'), findsOneWidget);
      expect(find.text('Ecuador'), findsOneWidget);
      expect(find.text('Perú'), findsOneWidget);
      expect(find.text('Otros'), findsOneWidget);
    });

    testWidgets('muestra los conteos de pacientes por país', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final targetCount = find.text('542');
      await tester.scrollUntilVisible(
        targetCount,
        150.0,
        scrollable: find.byType(Scrollable).first,
      );

      expect(targetCount, findsOneWidget);
      expect(find.text('489'), findsOneWidget);
      expect(find.text('134'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
    });

    testWidgets('muestra las 5 banderas emoji', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final targetFlag = find.text('🇨🇴');
      await tester.scrollUntilVisible(
        targetFlag,
        150.0,
        scrollable: find.byType(Scrollable).first,
      );

      expect(targetFlag, findsOneWidget);
      expect(find.text('🇻🇪'), findsOneWidget);
      expect(find.text('🇪🇨'), findsOneWidget);
      expect(find.text('🇵🇪'), findsOneWidget);
      expect(find.text('🌍'), findsOneWidget);
    });

    testWidgets('muestra 4 Dividers (no hay divisor después del último país)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final targetCountry = find.text('Colombia');
      await tester.scrollUntilVisible(
        targetCountry,
        150.0,
        scrollable: find.byType(Scrollable).first,
      );

      final dividers = tester
          .widgetList<Divider>(find.byType(Divider))
          .toList();
      expect(dividers.length, 4);
    });
  });

  group('_OrgFilterBar · chips de filtro de organización', () {
    testWidgets('muestra sólo chip "Todas" cuando no hay orgs en el repo', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: <OrgSummary>[]);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Todas'), findsOneWidget);
    });

    testWidgets('muestra chip "Todas" + chips de orgs del repositorio', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: [_org('o1', 'Cruz Roja'), _org('o2', 'OPS')],
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Cruz Roja'), findsOneWidget);
      expect(find.text('OPS'), findsOneWidget);
    });

    testWidgets('tap en chip de org incrementa callCount (_load se relanza)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: [_org('o1', 'Cruz Roja')]);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final callsAntes = repo.callCount;
      await tester.tap(find.text('Cruz Roja'));
      await tester.pumpAndSettle();

      expect(repo.callCount, greaterThan(callsAntes));
    });

    testWidgets('tap en chip "Todas" no lanza excepción', (tester) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: [_org('o1', 'Cruz Roja')]);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('3 orgs → barra muestra 4 chips en total (Todas + 3)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(
        orgsResult: [
          _org('o1', 'Org A'),
          _org('o2', 'Org B'),
          _org('o3', 'Org C'),
        ],
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Org A'), findsOneWidget);
      expect(find.text('Org B'), findsOneWidget);
      expect(find.text('Org C'), findsOneWidget);
    });
  });

  group('BrigadeStatsScreen · pull-to-refresh', () {
    testWidgets('fling hacia abajo sobre ListView relanza _load', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final repo = FakeUserRepository(orgsResult: <OrgSummary>[]);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pumpAndSettle();

      final callsAntes = repo.callCount;

      final mainVerticalListView = find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.vertical,
      );

      await tester.fling(mainVerticalListView, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repo.callCount, greaterThan(callsAntes));
    });
  });
}
