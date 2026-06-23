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
  _FakeRepo({Future<List<OrgSummary>> Function()? listOrgs, this.onCreateOrg})
    : _listOrgs = listOrgs ?? (() async => []);

  final Future<List<OrgSummary>> Function() _listOrgs;
  final Future<OrgSummary> Function(String)? onCreateOrg;
  int listCallCount = 0;

  @override
  Future<List<OrgSummary>> listOrganizations() async {
    listCallCount++;
    return _listOrgs();
  }

  @override
  Future<OrgSummary> createOrganization(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (onCreateOrg != null) return onCreateOrg!(name);
    return OrgSummary(id: 'new-org-123', name: name, isActive: true);
  }

  @override
  Future<UserSession> createOrgAdminUser({
    required String fullName,
    required String email,
    required String password,
    required String organizationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return UserSession(
      id: 'admin-123',
      fullName: fullName,
      email: email,
      role: UserRole.orgAdmin,
      isActive: true,
      organizationId: organizationId,
    );
  }

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
  child: AppScope(
    authRepository: _StubAuth(),
    userRepository: repo,
    patientRepository: _StubPatients(),
    localDatabase: _StubDb(),
    syncEngine: _StubSync(),
    child: const MaterialApp(home: Scaffold(body: ManageOrganizationsScreen())),
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

  group('Navegación general y Cancelación', () {
    testWidgets('Tocar botón de atrás en el header ejecuta Navigator.pop', (
      t,
    ) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
      await t.tap(backBtn);
      await t.pumpAndSettle();
    });

    testWidgets('Tocar botón Cancelar en Paso 1 cierra el BottomSheet', (
      t,
    ) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      final s = AppStrings.forTesting('es');
      final cancelBtn = find.widgetWithText(OutlinedButton, s.cancel);

      await t.tap(cancelBtn);
      await t.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Flujo completo de _CreateOrgSheet', () {
    testWidgets('Flujo exitoso paso a paso e inserción en la lista reactiva', (
      t,
    ) async {
      configureMobileScreenSize(t);

      final repo = _FakeRepo(
        listOrgs: () async => [],
        onCreateOrg: (name) async =>
            OrgSummary(id: 'new-org-123', name: name, isActive: true),
      );

      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();
      await _openSheet(t);

      final s = AppStrings.forTesting('es');
      final sheetFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_CreateOrgSheet',
      );

      final continueBtn = find.descendant(
        of: sheetFinder,
        matching: find.widgetWithText(ElevatedButton, 'Continue'),
      );
      await t.tap(continueBtn);
      await t.pumpAndSettle();

      expect(find.text(s.userFormRequiredFieldsError), findsOneWidget);

      final orgField = find.descendant(
        of: sheetFinder,
        matching: find.byType(TextField),
      );
      await t.enterText(orgField, 'Hospital General');
      await t.pumpAndSettle();

      await t.tap(continueBtn);
      await t.pumpAndSettle();

      expect(find.textContaining('2'), findsOneWidget);

      final backBtnStep2 = find.descendant(
        of: sheetFinder,
        matching: find.widgetWithText(OutlinedButton, s.back),
      );

      await t.ensureVisible(backBtnStep2);
      await t.tap(backBtnStep2);
      await t.pumpAndSettle();
      expect(find.textContaining('1'), findsOneWidget);

      final orgFieldBack = find.descendant(
        of: sheetFinder,
        matching: find.byType(TextField),
      );
      await t.enterText(orgFieldBack, 'Hospital General');
      await t.pumpAndSettle();

      final continueBtnAgain = find.descendant(
        of: sheetFinder,
        matching: find.widgetWithText(ElevatedButton, 'Continue'),
      );
      await t.tap(continueBtnAgain);
      await t.pumpAndSettle();

      final submitBtn = find
          .descendant(
            of: sheetFinder,
            matching: find.widgetWithText(ElevatedButton, s.orgsCreateOrgTitle),
          )
          .last;

      await t.ensureVisible(submitBtn);
      await t.pumpAndSettle();

      await t.tap(submitBtn);
      await t.pumpAndSettle();

      expect(find.text(s.userFormRequiredFieldsError), findsOneWidget);

      final fieldsStep2 = find.descendant(
        of: sheetFinder,
        matching: find.byType(TextField),
      );
      expect(fieldsStep2, findsNWidgets(3));

      await t.enterText(fieldsStep2.at(0), 'Admin Name');
      await t.enterText(fieldsStep2.at(1), 'admin@hospital.com');
      await t.enterText(fieldsStep2.at(2), '123');
      await t.pumpAndSettle();

      await t.ensureVisible(submitBtn);
      await t.tap(submitBtn);
      await t.pumpAndSettle();

      expect(
        find.text(s.passwordTooShort.replaceAll('6', '8')),
        findsOneWidget,
      );

      final visibilityBtn = find.byIcon(Icons.visibility_off);
      await t.tap(visibilityBtn);
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Seteamos la contraseña válida final
      await t.enterText(fieldsStep2.at(2), 'passwordSeguro123');
      await t.pumpAndSettle();

      await t.ensureVisible(submitBtn);
      await t.runAsync(() async {
        await t.tap(submitBtn);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await t.pumpAndSettle();

      expect(find.text('Hospital General'), findsAtLeastNWidgets(1));

      final saveBtn = find.descendant(
        of: sheetFinder,
        matching: find.widgetWithText(ElevatedButton, s.save),
      );
      await t.tap(saveBtn);
      await t.pumpAndSettle();
    });

    testWidgets(
      'Manejo de errores ApiException y Excepción Genérica en Paso 2',
      (t) async {
        configureMobileScreenSize(t);

        int errorMode = 0;
        final repo = _FakeRepo(
          listOrgs: () async => [],
          onCreateOrg: (name) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            if (errorMode == 0) {
              throw ApiException('Error desde Servidor', statusCode: 400);
            }
            throw Exception('Fallo de red inesperado');
          },
        );

        await t.pumpWidget(_build(repo));
        await t.pumpAndSettle();
        await _openSheet(t);

        final s = AppStrings.forTesting('es');
        final sheetFinder = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_CreateOrgSheet',
        );

        final orgField = find.descendant(
          of: sheetFinder,
          matching: find.byType(TextField),
        );
        await t.enterText(orgField, 'Clínica Central');
        await t.pumpAndSettle();

        final continueBtn = find.descendant(
          of: sheetFinder,
          matching: find.widgetWithText(ElevatedButton, 'Continue'),
        );
        await t.tap(continueBtn);
        await t.pumpAndSettle();

        final fieldsStep2Err = find.descendant(
          of: sheetFinder,
          matching: find.byType(TextField),
        );
        expect(fieldsStep2Err, findsNWidgets(3));

        await t.enterText(fieldsStep2Err.at(0), 'Carlos');
        await t.enterText(fieldsStep2Err.at(1), 'carlos@test.com');
        await t.enterText(fieldsStep2Err.at(2), '12345678');
        await t.pumpAndSettle();

        final submitBtnErr = find
            .descendant(
              of: sheetFinder,
              matching: find.widgetWithText(
                ElevatedButton,
                s.orgsCreateOrgTitle,
              ),
            )
            .last;
        await t.ensureVisible(submitBtnErr);
        await t.pumpAndSettle();

        errorMode = 0;
        await t.runAsync(() async {
          await t.tap(submitBtnErr);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await t.pumpAndSettle();
        expect(find.text(s.userFormValidationError), findsOneWidget);

        errorMode = 1;
        await t.ensureVisible(submitBtnErr);
        await t.runAsync(() async {
          await t.tap(submitBtnErr);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await t.pumpAndSettle();

        expect(find.text(s.userFormValidationError), findsOneWidget);
      },
    );
  });

  group('_OrgDetailSheet y flujos de eliminación', () {
    testWidgets(
      'Abre detalle de organización y cancela el diálogo de eliminación',
      (t) async {
        configureMobileScreenSize(t);
        final repo = _FakeRepo(listOrgs: () async => [_activa]);
        await t.pumpWidget(_build(repo));
        await t.pumpAndSettle();

        await t.tap(find.text('Cruz Roja'));
        await t.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.text('1'), findsOneWidget);

        await t.tap(find.widgetWithText(OutlinedButton, s.orgDeleteButton));
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(TextButton, s.cancel));
        await t.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('Confirma eliminación exitosa con recarga de pantalla', (
      t,
    ) async {
      configureMobileScreenSize(t);
      final repo = _FakeRepo(listOrgs: () async => [_activa]);
      await t.pumpWidget(_build(repo));
      await t.pumpAndSettle();

      await t.tap(find.text('Cruz Roja'));
      await t.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      await t.tap(find.widgetWithText(OutlinedButton, s.orgDeleteButton));
      await t.pumpAndSettle();

      await t.tap(find.widgetWithText(TextButton, s.delete));

      await t.pump(const Duration(milliseconds: 900));
      await t.pumpAndSettle();

      expect(find.text('1'), findsNothing);
    });
  });
}
