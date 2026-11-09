// test/widget/auth_gate_widget_test.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/auth_gate.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/lock_gate.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

/// Controllable AuthRepository fake.
class _GateAuth extends Fake implements AuthRepository {
  _GateAuth({
    this.restoreResult,
    this.restoreFuture,
    bool initiallyLocked = false,
  }) {
    _current = restoreResult;
    _sessionNotifier = ValueNotifier<UserSession?>(restoreResult);
    _isLocalLocked = ValueNotifier<bool>(initiallyLocked);
  }

  final UserSession? restoreResult;
  final Future<UserSession?>? restoreFuture;
  UserSession? _current;
  late final ValueNotifier<UserSession?> _sessionNotifier;
  late final ValueNotifier<bool> _isLocalLocked;

  @override
  UserSession? get currentUser => _current;

  @override
  ValueNotifier<UserSession?> get sessionNotifier => _sessionNotifier;

  @override
  ValueListenable<bool> get isLocalLocked => _isLocalLocked;

  @override
  void setLocalLocked(bool locked) {
    _isLocalLocked.value = locked;
  }

  @override
  Future<UserSession?> restoreSession() {
    if (restoreFuture != null) return restoreFuture!;
    return Future<UserSession?>.value(restoreResult);
  }

  @override
  Future<void> logout({bool wipeLocalData = false}) async {}
}

UserSession _superadmin() => UserSession(
  id: 'uid-sa',
  email: 'root@hwb.org',
  fullName: 'Root Admin',
  role: UserRole.superadmin,
  organizationId: 'org-0',
);

Widget _wrap(_GateAuth auth) {
  final apiClient = ApiClient(baseUrl: 'https://example.com');
  final userRepository = UserRepository(
    apiClient: apiClient,
    authRepository: auth,
  );
  final patientRepository = PatientRepository(
    apiClient: apiClient,
    authRepository: auth,
  );
  final syncEngine = SyncEngine(
    patientRepository: patientRepository,
    localDatabase: LocalDatabase.instance,
  );

  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: AppScope(
      authRepository: auth,
      userRepository: userRepository,
      patientRepository: patientRepository,
      localDatabase: LocalDatabase.instance,
      syncEngine: syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: auth,
      ),
      reachability: Reachability(baseUrl: 'http://localhost'),
      child: MaterialApp(home: AuthGate(authRepository: auth)),
    ),
  );
}

void main() {
  testWidgets('muestra el splash mientras la restauración está pendiente', (
    tester,
  ) async {
    final completer = Completer<UserSession?>();
    final auth = _GateAuth(restoreFuture: completer.future);

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    completer.complete(null);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('sin sesión restaurable → LoginScreen', (tester) async {
    final auth = _GateAuth(restoreResult: null);

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('sesión restaurada con bloqueo activo → LockScreen', (
    tester,
  ) async {
    final auth = _GateAuth(restoreResult: _superadmin(), initiallyLocked: true);

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('sesión restaurada y desbloqueada → HomeScreen', (tester) async {
    final auth = _GateAuth(
      restoreResult: _superadmin(),
      initiallyLocked: false,
    );

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
