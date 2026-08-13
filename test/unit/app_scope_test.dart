// test/unit/app_scope_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockUserSession extends Mock implements UserSession {}

class _MockReachability extends Mock implements Reachability {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockPatientRepository patientRepository;
  late MockLocalDatabase localDatabase;
  late MockSyncEngine syncEngine;
  late MockUserSession userSession;
  late ValueNotifier<UserSession?> sessionNotifier;

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    patientRepository = MockPatientRepository();
    localDatabase = MockLocalDatabase();
    syncEngine = MockSyncEngine();
    userSession = MockUserSession();

    sessionNotifier = ValueNotifier<UserSession?>(null);
    when(() => authRepository.sessionNotifier).thenReturn(sessionNotifier);
  });

  /// Helper
  AppScope buildScope({
    AuthRepository? auth,
    UserRepository? user,
    PatientRepository? patient,
    LocalDatabase? db,
    SyncEngine? sync,
    Widget child = const SizedBox(),
  }) {
    final activeAuth = auth ?? authRepository;
    if (auth != null) {
      when(
        () => auth.sessionNotifier,
      ).thenReturn(ValueNotifier<UserSession?>(null));
    }

    return AppScope(
      authRepository: activeAuth,
      userRepository: user ?? userRepository,
      patientRepository: patient ?? patientRepository,
      localDatabase: db ?? localDatabase,
      syncEngine: sync ?? syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: activeAuth,
      ),
      reachability: _MockReachability(),
      child: child,
    );
  }

  group('AppScope.currentUser', () {
    test('1. retorna null cuando authRepository.currentUser es null', () {
      when(() => authRepository.currentUser).thenReturn(null);

      final scope = buildScope();

      expect(scope.currentUser, isNull);
      verify(() => authRepository.currentUser).called(1);
    });

    test('2. retorna la sesión expuesta por authRepository.currentUser', () {
      when(() => authRepository.currentUser).thenReturn(userSession);

      final scope = buildScope();

      expect(scope.currentUser, same(userSession));
    });
  });

  group('AppScope.of(context)', () {
    testWidgets(
      '3. retorna la instancia de AppScope cuando existe en el árbol',
      (tester) async {
        AppScope? retrievedScope;

        await tester.pumpWidget(
          MaterialApp(
            home: buildScope(
              child: Builder(
                builder: (context) {
                  retrievedScope = AppScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(retrievedScope, isNotNull);
      },
    );

    testWidgets('4. lanza StateError cuando no existe AppScope en el árbol', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(() => AppScope.of(context), throwsStateError);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('AppScope reactividad e inyección', () {
    testWidgets(
      '5. notifica a los dependientes cuando cambia el valor de sessionNotifier',
      (tester) async {
        when(
          () => authRepository.currentUser,
        ).thenAnswer((_) => sessionNotifier.value);

        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: buildScope(
              child: Builder(
                builder: (context) {
                  buildCount++;
                  final scope = AppScope.of(context);
                  return Text(scope.currentUser?.fullName ?? 'no-user');
                },
              ),
            ),
          ),
        );

        expect(find.text('no-user'), findsOneWidget);
        expect(buildCount, equals(1));

        // Simulamos inicio de sesión
        when(() => userSession.fullName).thenReturn('Dr. Ana');
        sessionNotifier.value = userSession;
        await tester.pump();

        expect(find.text('Dr. Ana'), findsOneWidget);
        expect(buildCount, equals(2));
      },
    );

    test('6. expone correctamente todas las dependencias inyectadas', () {
      final scope = buildScope();

      expect(scope.authRepository, same(authRepository));
      expect(scope.userRepository, same(userRepository));
      expect(scope.patientRepository, same(patientRepository));
      expect(scope.localDatabase, same(localDatabase));
      expect(scope.syncEngine, same(syncEngine));
      expect(scope.statsRepository, isNotNull);
      expect(scope.reachability, isNotNull);
    });

    test('7. asigna sessionNotifier de authRepository como notifier', () {
      final scope = buildScope();

      expect(scope.notifier, same(sessionNotifier));
    });
  });
}
