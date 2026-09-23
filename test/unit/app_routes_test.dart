// test/unit/app_routes_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/routes/app_routes.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/brigade_stats_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_organizations_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_users_screen.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/loss_of_wristband_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/read_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/sync/presentation/sync_queue_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockStatsRepository extends Mock implements StatsRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockReachability extends Mock implements Reachability {}

UserSession _createSession(UserRole role) {
  return UserSession(
    id: 'u-123',
    email: 'test@example.com',
    fullName: 'Test User',
    role: role,
    organizationId: 'org-123',
  );
}

Widget buildTestableApp({
  required AuthRepository authRepository,
  required String initialRoute,
}) {
  final userRepo = MockUserRepository();
  final patientRepo = MockPatientRepository();
  final statsRepo = MockStatsRepository();
  final localDb = MockLocalDatabase();
  final syncEngine = MockSyncEngine();
  final reachability = MockReachability();

  when(() => syncEngine.isOnline).thenReturn(ValueNotifier<bool>(true));
  when(() => syncEngine.pendingCount).thenReturn(ValueNotifier<int>(0));
  when(() => syncEngine.blockedCount).thenReturn(ValueNotifier<int>(0));
  when(() => syncEngine.refreshPendingCount()).thenAnswer((_) async {});
  when(() => localDb.getUnsyncedRecords()).thenAnswer((_) async => []);

  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: AppScope(
      authRepository: authRepository,
      userRepository: userRepo,
      patientRepository: patientRepo,
      statsRepository: statsRepo,
      localDatabase: localDb,
      syncEngine: syncEngine,
      reachability: reachability,
      child: MaterialApp(
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(
      () => mockAuthRepository.sessionNotifier,
    ).thenReturn(ValueNotifier<UserSession?>(null));
  });

  group('AppRoutes Guard Tests', () {
    testWidgets('Redirige a LoginScreen cuando la sesión no está iniciada', (
      tester,
    ) async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(
        () => mockAuthRepository.sessionNotifier,
      ).thenReturn(ValueNotifier<UserSession?>(null));

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.manageOrgs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ManageOrganizationsScreen), findsNothing);
    });

    testWidgets(
      'Muestra Acceso Restringido cuando un médico intenta acceder a /admin/manage-orgs',
      (tester) async {
        final session = _createSession(UserRole.doctor);
        when(() => mockAuthRepository.currentUser).thenReturn(session);
        when(
          () => mockAuthRepository.sessionNotifier,
        ).thenReturn(ValueNotifier<UserSession?>(session));

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.manageOrgs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acceso Restringido'), findsOneWidget);
        expect(find.byType(ManageOrganizationsScreen), findsNothing);
      },
    );

    testWidgets('Permite el acceso a /admin/manage-users a un orgAdmin', (
      tester,
    ) async {
      final session = _createSession(UserRole.orgAdmin);
      when(() => mockAuthRepository.currentUser).thenReturn(session);
      when(
        () => mockAuthRepository.sessionNotifier,
      ).thenReturn(ValueNotifier<UserSession?>(session));

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.manageUsers,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManageUsersScreen), findsOneWidget);
    });

    testWidgets(
      'Permite el acceso a /admin/manage-orgs únicamente a Superadmin',
      (tester) async {
        final session = _createSession(UserRole.superadmin);
        when(() => mockAuthRepository.currentUser).thenReturn(session);
        when(
          () => mockAuthRepository.sessionNotifier,
        ).thenReturn(ValueNotifier<UserSession?>(session));

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.manageOrgs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ManageOrganizationsScreen), findsOneWidget);
      },
    );

    testWidgets('Muestra LoginScreen cuando la ruta es /login directamente', (
      tester,
    ) async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.login,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Permite acceso a /home cuando hay sesión iniciada', (
      tester,
    ) async {
      final session = _createSession(UserRole.doctor);
      when(() => mockAuthRepository.currentUser).thenReturn(session);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.home,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'Permite acceso a /nfc/read si el usuario puede leer pacientes',
      (tester) async {
        final session = _createSession(UserRole.doctor);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.readNfc,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReadNfcScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Permite acceso a /nfc/register si el usuario puede registrar',
      (tester) async {
        final session = _createSession(UserRole.nurse);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.registerNfc,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RegisterNfcScreen), findsOneWidget);
      },
    );

    testWidgets('Muestra Acceso Restringido en /nfc/register sin permisos', (
      tester,
    ) async {
      final session = _createSession(UserRole.superadmin);
      when(() => mockAuthRepository.currentUser).thenReturn(session);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.registerNfc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso Restringido'), findsOneWidget);
    });

    testWidgets(
      'Permite acceso a /nfc/loss-wristband si puede buscar pacientes',
      (tester) async {
        final session = _createSession(UserRole.nurse);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.lossWristband,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LossOfWristbandScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Muestra Acceso Restringido en /nfc/loss-wristband sin permisos',
      (tester) async {
        final session = _createSession(UserRole.superadmin);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.lossWristband,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acceso Restringido'), findsOneWidget);
      },
    );

    testWidgets('Permite acceso a /sync/queue si puede sincronizar', (
      tester,
    ) async {
      final session = _createSession(UserRole.doctor);
      when(() => mockAuthRepository.currentUser).thenReturn(session);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.syncQueue,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyncQueueScreen), findsOneWidget);
    });

    testWidgets('Muestra Acceso Restringido en /sync/queue sin permisos', (
      tester,
    ) async {
      final session = _createSession(UserRole.superadmin);
      when(() => mockAuthRepository.currentUser).thenReturn(session);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.syncQueue,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso Restringido'), findsOneWidget);
    });

    testWidgets(
      'Muestra Acceso Restringido en /admin/manage-users sin permisos',
      (tester) async {
        final session = _createSession(UserRole.doctor);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.manageUsers,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acceso Restringido'), findsOneWidget);
      },
    );

    testWidgets('Permite acceso a /admin/brigade-stats a Superadmin', (
      tester,
    ) async {
      final session = _createSession(UserRole.superadmin);
      when(() => mockAuthRepository.currentUser).thenReturn(session);

      await tester.pumpWidget(
        buildTestableApp(
          authRepository: mockAuthRepository,
          initialRoute: AppRoutes.brigadeStats,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrigadeStatsScreen), findsOneWidget);
    });

    testWidgets(
      'Muestra Acceso Restringido en /admin/brigade-stats si no es superadmin',
      (tester) async {
        final session = _createSession(UserRole.orgAdmin);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.brigadeStats,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acceso Restringido'), findsOneWidget);
      },
    );

    testWidgets(
      'Permite acceso a /admin/brigade-stats-org si puede ver analítica',
      (tester) async {
        final session = _createSession(UserRole.orgAdmin);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.brigadeStatsOrg,
          ),
        );
        await tester.pumpAndSettle();

        final finder = find.byType(BrigadeStatsScreen);
        expect(finder, findsOneWidget);

        final screen = tester.widget<BrigadeStatsScreen>(finder);
        expect(screen.scopeToOwnOrganization, isTrue);
      },
    );

    testWidgets(
      'Muestra Acceso Restringido en /admin/brigade-stats-org sin permisos de analítica',
      (tester) async {
        final session = _createSession(UserRole.nurse);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.brigadeStatsOrg,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acceso Restringido'), findsOneWidget);
      },
    );

    testWidgets(
      'Fallback por defecto dirige a HomeScreen para rutas no mapeadas',
      (tester) async {
        final session = _createSession(UserRole.doctor);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: '/ruta-desconocida',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });

  group('AppRoutes /nfc/read — permisos por rol', () {
    final deniedRoles = UserRole.values
        .where((UserRole r) => !r.canReadPatients && !r.canScanNfc)
        .toList();
    final scanOnlyRoles = UserRole.values
        .where((UserRole r) => !r.canReadPatients && r.canScanNfc)
        .toList();

    test('existe al menos un rol sin permiso de lectura ni escaneo NFC', () {
      expect(deniedRoles, isNotEmpty);
    });

    for (final UserRole role in deniedRoles) {
      testWidgets(
        'Muestra Acceso Restringido en /nfc/read para el rol ${role.name} '
        '(sin canReadPatients ni canScanNfc)',
        (tester) async {
          final session = _createSession(role);
          when(() => mockAuthRepository.currentUser).thenReturn(session);

          await tester.pumpWidget(
            buildTestableApp(
              authRepository: mockAuthRepository,
              initialRoute: AppRoutes.readNfc,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Acceso Restringido'), findsOneWidget);
          expect(find.byType(ReadNfcScreen), findsNothing);
        },
      );
    }

    for (final UserRole role in scanOnlyRoles) {
      testWidgets('Permite /nfc/read al rol ${role.name} por canScanNfc', (
        tester,
      ) async {
        final session = _createSession(role);
        when(() => mockAuthRepository.currentUser).thenReturn(session);

        await tester.pumpWidget(
          buildTestableApp(
            authRepository: mockAuthRepository,
            initialRoute: AppRoutes.readNfc,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReadNfcScreen), findsOneWidget);
      });
    }
  });
}
