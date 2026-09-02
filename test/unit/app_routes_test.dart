// test/unit/app_routes_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/routes/app_routes.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_organizations_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/presentation/manage_users_screen.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

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

  return AppScope(
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
  );
}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AppRoutes Guard Tests', () {
    testWidgets('Redirige a LoginScreen cuando la sesión no está iniciada', (
      tester,
    ) async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);

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
  });
}
