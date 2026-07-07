// test/widget/auth_gate_widget_test.dart
//
// AuthGate routes the first screen based on restoreSession(): a brief splash
// while the (storage-only) restore runs, then HomeScreen if a session was
// restored or LoginScreen otherwise.

import 'dart:async';

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
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

/// Controllable AuthRepository fake. Only restoreSession/currentUser/logout are
/// exercised here; the rest is left to Fake's noSuchMethod (never called).
class _GateAuth extends Fake implements AuthRepository {
  _GateAuth({this.restoreResult, this.restoreFuture});

  final UserSession? restoreResult;
  final Future<UserSession?>? restoreFuture;
  UserSession? _current;

  @override
  UserSession? get currentUser => _current;

  @override
  Future<UserSession?> restoreSession() {
    if (restoreFuture != null) return restoreFuture!;
    // Mirror production: a restored session becomes the current user, which is
    // what HomeScreen reads via AppScope.
    _current = restoreResult;
    return Future<UserSession?>.value(restoreResult);
  }

  @override
  Future<void> logout() async {}
}

// Superadmin => HomeScreen renders the admin body (static cards, no sync card),
// so no local database access is triggered during the render.
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
    await tester.pump(); // build the FutureBuilder once (still pending)

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    // Resolve so nothing is left dangling.
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

  testWidgets('sesión restaurada → HomeScreen', (tester) async {
    final auth = _GateAuth(restoreResult: _superadmin());

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
