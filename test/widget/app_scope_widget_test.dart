// test/widget/app_scope_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late MockPatientRepository patientRepository;
  late MockLocalDatabase localDatabase;
  late MockSyncEngine syncEngine;

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    patientRepository = MockPatientRepository();
    localDatabase = MockLocalDatabase();
    syncEngine = MockSyncEngine();
    when(() => authRepository.currentUser).thenReturn(null);
  });

  Widget wrapWithScope({
    required Widget child,
    AuthRepository? auth,
    PatientRepository? patient,
  }) {
    return AppScope(
      authRepository: auth ?? authRepository,
      userRepository: userRepository,
      patientRepository: patient ?? patientRepository,
      localDatabase: localDatabase,
      syncEngine: syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: auth ?? authRepository,
      ),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('AppScope.of localiza la instancia correcta en el árbol', (
    tester,
  ) async {
    late AppScope captured;

    await tester.pumpWidget(
      wrapWithScope(
        child: Builder(
          builder: (context) {
            captured = AppScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(captured.authRepository, same(authRepository));
    expect(captured.patientRepository, same(patientRepository));
    expect(captured.userRepository, same(userRepository));
    expect(captured.localDatabase, same(localDatabase));
    expect(captured.syncEngine, same(syncEngine));
  });

  testWidgets('AppScope.of lanza StateError si no hay AppScope ancestro', (
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

  testWidgets(
    'un widget dependiente se reconstruye cuando authRepository cambia',
    (tester) async {
      int buildCount = 0;

      final dependent = Builder(
        builder: (context) {
          AppScope.of(context);
          buildCount++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(wrapWithScope(child: dependent));
      expect(buildCount, 1);

      await tester.pumpWidget(
        wrapWithScope(child: dependent, auth: MockAuthRepository()),
      );
      expect(buildCount, 2);
    },
  );

  testWidgets('un widget dependiente NO se reconstruye si no cambian '
      'authRepository ni patientRepository', (tester) async {
    int buildCount = 0;

    final dependent = Builder(
      builder: (context) {
        AppScope.of(context);
        buildCount++;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(wrapWithScope(child: dependent));
    expect(buildCount, 1);

    await tester.pumpWidget(wrapWithScope(child: dependent));
    expect(buildCount, 1);
  });
}
