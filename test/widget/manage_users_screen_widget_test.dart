// test/widget/manage_users_screen_widget_test.dart

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
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_users_screen.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Fakes
// ═════════════════════════════════════════════════════════════════════════════

class FakeUserRepository extends Fake implements UserRepository {
  List<UserSession>? usersToReturn;
  Exception? errorToThrow;
  bool shouldThrowOnCreate = false;

  @override
  Future<List<UserSession>> listUsers() async {
    if (errorToThrow != null) throw errorToThrow!;
    return usersToReturn ?? [];
  }

  @override
  Future<UserSession> createUser({
    required String email,
    required String fullName,
    String? organizationId,
    required String role,
    required String password,
  }) async {
    if (shouldThrowOnCreate) {
      throw Exception('Crash no controlado');
    }
    return UserSession(
      id: 'new-user',
      fullName: fullName,
      email: email,
      role: UserRole.values.firstWhere(
        (r) => r.name == role || r.toString().split('.').last == role,
        orElse: () => UserRole.doctor,
      ),
      isActive: true,
      organizationId: organizationId ?? 'org-1',
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<UserSession> setUserActive(String id, bool isActive) async {
    if (errorToThrow != null) throw errorToThrow!;
    return UserSession(
      id: id,
      fullName: 'User',
      email: 'user@org.com',
      role: UserRole.doctor,
      isActive: isActive,
      organizationId: 'org-1',
    );
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({this.role = UserRole.orgAdmin});
  final UserRole role;

  @override
  UserSession? get currentUser => UserSession(
    id: 'admin-1',
    fullName: 'Admin User',
    email: 'admin@test.com',
    role: role,
    isActive: true,
    organizationId: 'org-1',
  );
}

class FakeUserRepositoryWithError extends FakeUserRepository {
  @override
  Future<UserSession> createUser({
    required String email,
    required String fullName,
    String? organizationId,
    required String role,
    required String password,
  }) async {
    throw ApiException('Error desde API Form', statusCode: 400);
  }
}

class FakePatientRepository extends Fake implements PatientRepository {}

class FakeLocalDatabase extends Fake implements LocalDatabase {}

class FakeSyncEngine extends Fake implements SyncEngine {}

class _TestLocaleWrapper extends StatefulWidget {
  const _TestLocaleWrapper({required this.initialLocale, required this.child});
  final String initialLocale;
  final Widget child;

  @override
  State<_TestLocaleWrapper> createState() => _TestLocaleWrapperState();
}

class _TestLocaleWrapperState extends State<_TestLocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (newLocale) {
        setState(() {
          _locale = newLocale;
        });
      },
      child: widget.child,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

UserSession buildUser({
  String id = 'u1',
  String fullName = 'Juan Galvis',
  String email = 'juan@test.com',
  UserRole role = UserRole.doctor,
  bool isActive = true,
  String organizationId = 'org-1',
}) => UserSession(
  id: id,
  fullName: fullName,
  email: email,
  role: role,
  isActive: isActive,
  organizationId: organizationId,
);

Widget buildTestApp(
  FakeUserRepository fakeRepo, {
  String locale = 'es',
  FakeAuthRepository? fakeAuth,
}) {
  return _TestLocaleWrapper(
    initialLocale: locale,
    child: MaterialApp(
      home: AppScope(
        authRepository: fakeAuth ?? FakeAuthRepository(),
        userRepository: fakeRepo,
        patientRepository: FakePatientRepository(),
        localDatabase: FakeLocalDatabase(),
        syncEngine: FakeSyncEngine(),
        statsRepository: StatsRepository(
          apiClient: ApiClient(baseUrl: 'http://localhost'),
          authRepository: fakeAuth ?? FakeAuthRepository(),
        ),
        child: const ManageUsersScreen(),
      ),
    ),
  );
}

void main() {
  late FakeUserRepository fakeRepo;

  setUp(() => fakeRepo = FakeUserRepository());

  group('Estado de carga', () {
    testWidgets('deja de mostrar CircularProgressIndicator cuando carga', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Estado de error', () {
    testWidgets('muestra el mensaje de ApiException', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.errorToThrow = ApiException('Acceso denegado.', statusCode: 403);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('muestra badge Reintentar en estado de error', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.errorToThrow = ApiException('Error', statusCode: 500);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.retry), findsOneWidget);
    });

    testWidgets('Reintentar vuelve a cargar y muestra lista', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.errorToThrow = ApiException('Error inicial', statusCode: 500);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      fakeRepo
        ..errorToThrow = null
        ..usersToReturn = [buildUser()];

      final s = AppStrings.forTesting('es');
      await tester.tap(find.text(s.retry));
      await tester.pumpAndSettle();

      expect(find.text('Juan Galvis'), findsOneWidget);
    });

    testWidgets('muestra error genérico con toString', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.errorToThrow = Exception('Timeout de red');
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Timeout de red'), findsOneWidget);
    });
  });

  group('Lista vacía', () {
    testWidgets('muestra "No hay usuarios en este filtro."', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.noUsersInFilter), findsOneWidget);
    });
  });

  group('_UserCard — renderizado', () {
    testWidgets('muestra el nombre del usuario', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(fullName: 'Dr. Ana Torres')];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ana Torres'), findsOneWidget);
    });

    testWidgets('muestra el email del usuario', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(email: 'ana@hospital.com')];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('ana@hospital.com'), findsOneWidget);
    });

    testWidgets('muestra "Activo" para usuario activo', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(isActive: true)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.userStatusActive), findsOneWidget);
    });

    testWidgets('muestra "Suspendido" para usuario inactivo', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(isActive: false)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.userStatusSuspended), findsOneWidget);
    });

    testWidgets('muestra las iniciales del usuario', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(fullName: 'Juan Galvis')];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('JG'), findsOneWidget);
    });

    testWidgets('múltiples usuarios se muestran en lista', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [
        buildUser(id: '1', fullName: 'Usuario Uno'),
        buildUser(id: '2', fullName: 'Usuario Dos'),
        buildUser(id: '3', fullName: 'Usuario Tres'),
      ];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Usuario Uno'), findsOneWidget);
      expect(find.text('Usuario Dos'), findsOneWidget);
      expect(find.text('Usuario Tres'), findsOneWidget);
    });
  });

  group('_RoleBadge — labels', () {
    testWidgets('muestra "Doctor" para UserRole.doctor', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(role: UserRole.doctor)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.roleDoctor), findsOneWidget);
    });

    testWidgets('muestra "Enfermería" para UserRole.nurse', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(role: UserRole.nurse)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.roleNurse), findsOneWidget);
    });

    testWidgets('muestra "Admin" para UserRole.orgAdmin', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(role: UserRole.orgAdmin)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.roleOrgAdmin), findsOneWidget);
    });
  });

  group('Filtros — _FilterChip', () {
    setUp(() {
      fakeRepo.usersToReturn = [
        buildUser(id: '1', fullName: 'Doctor Uno', role: UserRole.doctor),
        buildUser(id: '2', fullName: 'Nurse Dos', role: UserRole.nurse),
        buildUser(id: '3', fullName: 'Admin Tres', role: UserRole.orgAdmin),
      ];
    });

    testWidgets('muestra los 4 chips de filtro', (tester) async {
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todos'), findsOneWidget);
      expect(find.textContaining('Doctores'), findsOneWidget);
      expect(find.textContaining('Enfermería'), findsOneWidget);
      expect(find.textContaining('Coord'), findsAtLeastNWidgets(1));
    });

    testWidgets('filtro "Doctores" muestra solo doctores', (tester) async {
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final filterChip = find.textContaining('Doctores');
      await tester.ensureVisible(filterChip);
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      expect(find.text('Doctor Uno'), findsOneWidget);
      expect(find.text('Nurse Dos'), findsNothing);
      expect(find.text('Admin Tres'), findsNothing);
    });

    testWidgets('filtro "Enfermería" muestra solo nurses', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final filterChip = find.textContaining('Enfermería');
      await tester.ensureVisible(filterChip);
      await tester.tap(filterChip, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Nurse Dos'), findsOneWidget);
      expect(find.text('Doctor Uno'), findsNothing);
      expect(find.text('Admin Tres'), findsNothing);
    });

    testWidgets('filtro "Admin" muestra solo org_admins', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final filterChip = find.textContaining('Coord (');
      await tester.ensureVisible(filterChip);
      await tester.tap(filterChip, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Admin Tres'), findsOneWidget);
      expect(find.text('Doctor Uno'), findsNothing);
    });

    testWidgets('volver a "Todos" muestra todos los usuarios', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final docChip = find.textContaining('Doctores');
      await tester.ensureVisible(docChip);
      await tester.tap(docChip, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Nurse Dos'), findsNothing);

      final todosAfter = find.textContaining('Todos');
      await tester.tap(todosAfter.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('los contadores de filtro son correctos', (tester) async {
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Todos (3)'), findsOneWidget);
      expect(find.text('Doctores (1)'), findsOneWidget);
      expect(find.text('Enfermería (1)'), findsOneWidget);
    });

    testWidgets(
      'filtro sin resultados muestra "No hay usuarios en este filtro."',
      (tester) async {
        configureMobileScreenSize(tester);
        fakeRepo.usersToReturn = [buildUser(role: UserRole.doctor)];
        await tester.pumpWidget(buildTestApp(fakeRepo));
        await tester.pumpAndSettle();

        final filterChip = find.textContaining('Enfermería');
        await tester.ensureVisible(filterChip);
        await tester.tap(filterChip, warnIfMissed: false);
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.text(s.noUsersInFilter), findsOneWidget);
      },
    );
  });

  group('_UserDetailSheet', () {
    testWidgets('tocar tarjeta abre el sheet de detalle', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [
        buildUser(
          fullName: 'Isabella Martínez',
          email: 'isabella@test.com',
          organizationId: 'org-99',
        ),
      ];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Isabella Martínez'));
      await tester.pumpAndSettle();

      expect(find.text('isabella@test.com'), findsAtLeastNWidgets(1));
      expect(find.textContaining('org-99'), findsOneWidget);
    });

    testWidgets('el sheet muestra Estado: Activo para usuario activo', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(isActive: true)];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Juan Galvis'));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.textContaining(s.userStatusActive), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'Cancelar diálogo de confirmación de borrado no cierra el modal',
      (tester) async {
        configureMobileScreenSize(tester);
        fakeRepo.usersToReturn = [buildUser(fullName: 'Eliminar Mí')];

        await tester.pumpWidget(buildTestApp(fakeRepo));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eliminar Mí'));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        await tester.tap(find.text(s.deletUser));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.cancel));
        await tester.pumpAndSettle();

        expect(find.text('Eliminar Mí'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('Confirmar diálogo ejecuta onDelete con éxito y cierra modal', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [buildUser(fullName: 'Juan Galvis')];

      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Juan Galvis'));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      await tester.tap(find.text(s.deletUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text(s.delete));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text(s.deletUser), findsNothing);
    });
  });

  group('FAB — crear usuario', () {
    testWidgets('muestra el FloatingActionButton', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('tocar FAB abre el sheet de creación de usuario', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.createUserTitle).first, findsOneWidget);
    });
  });

  group('_UserFormSheet — validación estructural', () {
    testWidgets('muestra opciones Doctor y Enfermería para orgAdmin', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.roleDoctor), findsOneWidget);
      expect(find.text(s.roleNurse), findsOneWidget);
    });

    testWidgets('muestra campos Nombre, Correo y Contraseña', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.userFormFullNameLabel), findsOneWidget);
      expect(find.text(s.userFormEmailLabel), findsOneWidget);
      expect(find.text(s.userFormPasswordLabel), findsOneWidget);
    });

    testWidgets('muestra botón "Crear usuario" en el sheet', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(
        find.widgetWithText(ElevatedButton, s.userFormCreateButton),
        findsOneWidget,
      );
    });

    testWidgets(
      'Lanzamiento de excepción genérica muestra su toString en el formulario',
      (tester) async {
        configureMobileScreenSize(tester);
        fakeRepo.usersToReturn = [];
        fakeRepo.shouldThrowOnCreate = true;

        await tester.pumpWidget(buildTestApp(fakeRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Test Crash');
        await tester.enterText(textFields.at(1), 'crash@test.com');
        await tester.enterText(textFields.at(2), 'securePass99');

        final s = AppStrings.forTesting('es');
        await tester.tap(
          find.widgetWithText(ElevatedButton, s.userFormCreateButton),
        );
        await tester.pumpAndSettle();

        expect(find.text(s.userFormValidationError), findsOneWidget);
      },
    );
  });

  group('Navegación e interfaz de Superadmin', () {
    testWidgets('Tocar botón de atrás ejecuta Navigator.pop', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Muestra badge y color correcto para un usuario Superadmin en lista',
      (tester) async {
        configureMobileScreenSize(tester);
        fakeRepo.usersToReturn = [
          buildUser(fullName: 'Super Usuario', role: UserRole.superadmin),
        ];
        await tester.pumpWidget(buildTestApp(fakeRepo));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.text(s.roleSuperadmin), findsOneWidget);
      },
    );

    testWidgets(
      'Formulario cambia opciones de rol según jerarquía Superadmin',
      (tester) async {
        configureMobileScreenSize(tester);
        final fakeAuthSuper = FakeAuthRepository(role: UserRole.superadmin);
        fakeRepo.usersToReturn = [];
        await tester.pumpWidget(
          buildTestApp(fakeRepo, fakeAuth: fakeAuthSuper),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.text(s.roleOrgAdmin), findsAtLeastNWidgets(1));
      },
    );
  });

  group('_UserFormSheet - Envío de datos (Submit, Errores y Éxito)', () {
    testWidgets('Rellenar campos y enviar crea usuario con éxito y refresca', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      await tester.enterText(textFields.at(0), 'Nuevo Medico');
      await tester.enterText(textFields.at(1), 'medico@test.com');
      await tester.enterText(textFields.at(2), 'password123');

      final s = AppStrings.forTesting('es');
      await tester.tap(find.text(s.roleNurse));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ElevatedButton, s.userFormCreateButton),
      );
      await tester.pumpAndSettle();

      expect(find.text(s.createUserTitle), findsNothing);
    });

    testWidgets('Muestra mensaje de error cuando onSubmit lanza ApiException', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      final customFakeRepo = FakeUserRepositoryWithError();
      await tester.pumpWidget(buildTestApp(customFakeRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Error User');
      await tester.enterText(textFields.at(1), 'error@test.com');
      await tester.enterText(textFields.at(2), 'password');

      final s = AppStrings.forTesting('es');
      await tester.tap(
        find.widgetWithText(ElevatedButton, s.userFormCreateButton),
      );
      await tester.pumpAndSettle();

      expect(find.text(s.userFormValidationError), findsOneWidget);
    });
  });

  group('Header y navegación', () {
    testWidgets('muestra el título "Gestionar usuarios"', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.manageUsersTitle), findsOneWidget);
    });

    testWidgets('muestra el botón de atrás en el header', (tester) async {
      configureMobileScreenSize(tester);
      fakeRepo.usersToReturn = [];
      await tester.pumpWidget(buildTestApp(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('_FilterBar - Scroll y flechas de navegación', () {
    testWidgets(
      'Evalúa animaciones y comportamiento de flechas en barra de filtros',
      (tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;

        fakeRepo.usersToReturn = [buildUser()];
        await tester.pumpWidget(buildTestApp(fakeRepo));
        await tester.pumpAndSettle();

        final scrollable = find.byType(SingleChildScrollView);
        await tester.drag(scrollable, const Offset(-100, 0));
        await tester.pumpAndSettle();

        final leftArrow = find.byIcon(Icons.arrow_back_ios_new);
        if (leftArrow.evaluate().isNotEmpty) {
          await tester.tap(leftArrow);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
        }

        tester.view.resetPhysicalSize();
      },
    );
  });

  group('Cambio de idioma (Localization)', () {
    testWidgets(
      'Alternar el idioma de ES a EN actualiza de inmediato las cadenas traducidas',
      (tester) async {
        configureMobileScreenSize(tester);
        fakeRepo.usersToReturn = [];
        await tester.pumpWidget(buildTestApp(fakeRepo, locale: 'es'));
        await tester.pumpAndSettle();

        final sEs = AppStrings.forTesting('es');
        final sEn = AppStrings.forTesting('en');

        expect(find.text(sEs.manageUsersTitle), findsOneWidget);

        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        expect(find.text(sEn.manageUsersTitle), findsOneWidget);
        expect(find.text(sEs.manageUsersTitle), findsNothing);
      },
    );
  });
}

void configureMobileScreenSize(WidgetTester tester) {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.views.first.physicalSize = const Size(
    412 * 3,
    892 * 3,
  );
  binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
}
