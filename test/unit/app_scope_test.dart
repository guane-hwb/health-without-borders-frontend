// test/unit/app_scope_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockUserSession extends Mock implements UserSession {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockPatientRepository patientRepository;
  late MockLocalDatabase localDatabase;
  late MockSyncEngine syncEngine;
  late MockUserSession userSession;

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    patientRepository = MockPatientRepository();
    localDatabase = MockLocalDatabase();
    syncEngine = MockSyncEngine();
    userSession = MockUserSession();
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
    return AppScope(
      authRepository: auth ?? authRepository,
      userRepository: user ?? userRepository,
      patientRepository: patient ?? patientRepository,
      localDatabase: db ?? localDatabase,
      syncEngine: sync ?? syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: auth ?? authRepository,
      ),
      child: child,
    );
  }

  group('AppScope.currentUser', () {
    test('retorna null cuando authRepository.currentUser es null', () {
      when(() => authRepository.currentUser).thenReturn(null);

      final scope = buildScope();

      expect(scope.currentUser, isNull);
      verify(() => authRepository.currentUser).called(1);
    });

    test('retorna la sesión expuesta por authRepository.currentUser', () {
      when(() => authRepository.currentUser).thenReturn(userSession);

      final scope = buildScope();

      expect(scope.currentUser, same(userSession));
    });
  });

  group('AppScope.updateShouldNotify', () {
    test('retorna false cuando nada relevante cambió', () {
      final oldScope = buildScope();
      final newScope = buildScope();

      expect(newScope.updateShouldNotify(oldScope), isFalse);
    });

    test('retorna true cuando cambia authRepository', () {
      final oldScope = buildScope();
      final newScope = buildScope(auth: MockAuthRepository());

      expect(newScope.updateShouldNotify(oldScope), isTrue);
    });

    test('retorna true cuando cambia patientRepository', () {
      final oldScope = buildScope();
      final newScope = buildScope(patient: MockPatientRepository());

      expect(newScope.updateShouldNotify(oldScope), isTrue);
    });

    test(
      'retorna true cuando cambian authRepository y patientRepository a la vez',
      () {
        final oldScope = buildScope();
        final newScope = buildScope(
          auth: MockAuthRepository(),
          patient: MockPatientRepository(),
        );

        expect(newScope.updateShouldNotify(oldScope), isTrue);
      },
    );

    test('retorna false cuando solo cambian dependencias que NO se comparan '
        '(userRepository, localDatabase, syncEngine)', () {
      final oldScope = buildScope();
      final newScope = buildScope(
        user: MockUserRepository(),
        db: MockLocalDatabase(),
        sync: MockSyncEngine(),
      );

      expect(newScope.updateShouldNotify(oldScope), isFalse);
    });
  });
}
