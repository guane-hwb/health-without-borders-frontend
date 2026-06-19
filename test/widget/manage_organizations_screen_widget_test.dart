// test/widget/manage_organizations_screen_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_organizations_screen.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

// ============================================================================
// FAKES
// ============================================================================

class _StubAuth implements AuthRepository {
  @override
  UserSession? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _StubPatients implements PatientRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _StubDb implements LocalDatabase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _StubSync implements SyncEngine {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _FakeRepo implements UserRepository {
  _FakeRepo({Future<List<OrgSummary>> Function()? listOrgs})
    : _listOrgs = listOrgs ?? (() async => []);

  final Future<List<OrgSummary>> Function() _listOrgs;
  int listCallCount = 0;

  @override
  Future<List<OrgSummary>> listOrganizations() {
    listCallCount++;
    return _listOrgs();
  }

  @override
  Future<OrgSummary> createOrganization(String name) =>
      throw UnimplementedError();

  @override
  Future<UserSession> createOrgAdminUser({
    required String fullName,
    required String email,
    required String password,
    required String organizationId,
  }) => throw UnimplementedError();

  @override
  Future<UserSession> getMe() => throw UnimplementedError();
  @override
  Future<List<UserSession>> listUsers() => throw UnimplementedError();
  @override
  Future<UserSession> createUser({
    required String email,
    required String fullName,
    required String role,
    required String password,
    String? organizationId,
  }) => throw UnimplementedError();
}

// ── Helper ─────────────────────────────────────────────────────────

Widget _build(_FakeRepo repo, {String locale = 'es'}) => AppLocale(
  locale: locale,
  setLocale: (_) {},
  child: MaterialApp(
    home: AppScope(
      authRepository: _StubAuth(),
      userRepository: repo,
      patientRepository: _StubPatients(),
      localDatabase: _StubDb(),
      syncEngine: _StubSync(),
      child: const Scaffold(body: ManageOrganizationsScreen()),
    ),
  ),
);

const _activa = OrgSummary(id: '1', name: 'Cruz Roja', isActive: true);
const _inactiva = OrgSummary(id: '2', name: 'Bomberos', isActive: false);

Future<void> _openSheet(WidgetTester t) async {
  await t.tap(find.byType(FloatingActionButton));
  await t.pumpAndSettle();
}

// ═════════════════════════════════════════════════════════════════════════════
// TESTS
// =============================================================================

void main() {
  void configureMobileScreenSize(WidgetTester tester) {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      412 * 3,
      892 * 3,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  }

  group('Carga inicial', () {
    testWidgets('muestra spinner mientras carga', (t) async {
      configureMobileScreenSize(t);
      final completer = Completer<List<OrgSummary>>();
      final repo = _FakeRepo(listOrgs: () => completer.future);

      await t.pumpWidget(_build(repo));
      await t.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([]);
    });

    testWidgets('termina de cargar e infla la vista', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Lista vacía', () {
    testWidgets('muestra texto "No hay organizaciones"', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.text('No hay organizaciones registradas.'), findsOneWidget);
    });
  });

  group('_OrgCard', () {
    testWidgets('muestra nombre, iniciales y badge Activo', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => [_activa]);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.text('Cruz Roja'), findsOneWidget);
      expect(find.text('CR'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('muestra badge Inactivo', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => [_inactiva]);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.userStatusSuspended), findsOneWidget);
    });

    testWidgets('iniciales de una sola palabra → primeras 2 letras', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(
        listOrgs: () async => [
          const OrgSummary(id: '3', name: 'Omega', isActive: true),
        ],
      );
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.text('OM'), findsOneWidget);
    });

    testWidgets('lista con múltiples cards sin overflow', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(
        listOrgs: () async => List.generate(
          5,
          (i) => OrgSummary(id: '$i', name: 'Org $i', isActive: i.isEven),
        ),
      );
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Errores al cargar', () {
    testWidgets('ApiException muestra mensaje y botón Reintentar', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(
        listOrgs: () async =>
            throw ApiException('Sin conexión', statusCode: 503),
      );
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('excepción genérica muestra su toString', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => throw Exception('Timeout'));
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      expect(find.textContaining('Timeout'), findsOneWidget);
    });

    testWidgets('Reintentar llama de nuevo al repo y muestra los datos', (
      t,
    ) async {
      configureMobileScreenSize(t);
      int calls = 0;
      final repo = _FakeRepo(
        listOrgs: () async {
          calls++;
          if (calls == 1) throw ApiException('Fallo', statusCode: 500);
          return [_activa];
        },
      );
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();

      expect(find.text('Cruz Roja'), findsOneWidget);
      expect(calls, 2);
    });
  });

  group('Pull-to-refresh', () {
    testWidgets('campo estático asincrónico jala al repo al hacer fling', (
      t,
    ) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => [_activa]);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      await t.fling(find.text('Cruz Roja'), const Offset(0, 400), 800);
      await t.pumpAndSettle();

      expect(repo.listCallCount, greaterThanOrEqualTo(2));
    });
  });

  group('FloatingActionButton', () {
    testWidgets('abre el sheet con el título y el step 1', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      final s = AppStrings.forTesting('es');
      expect(find.text(s.orgsCreateOrgTitle), findsOneWidget);

      final expectedStep1Header =
          '${s.step} 1 — ${s.orgsFieldNameLabel.replaceAll(" *", "")}';
      expect(find.text(expectedStep1Header), findsOneWidget);
    });
  });

  group('Estructura de inputs en los modales', () {
    testWidgets('Paso 1 renderiza etiqueta e input de organización', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      final s = AppStrings.forTesting('es');
      expect(find.text(s.orgsFieldNameLabel), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Ej. Cruz Roja Seccional Norte'),
        findsOneWidget,
      );
    });

    testWidgets('Paso 1 muestra botón Cancelar', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      final s = AppStrings.forTesting('es');
      expect(find.text(s.cancel), findsOneWidget);
    });

    testWidgets('Paso 1 renderiza botón Continue harcodeado', (t) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Indicador de pasos dibuja exactamente 2 esferas de progreso', (
      t,
    ) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => []);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });
  });
}
