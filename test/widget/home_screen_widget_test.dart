// test/widget/home_screen_widget_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers test
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  @override
  Future<String?> getNfcEncryptionKey() async => null;

  @override
  Future<NfcKeyring?> getNfcKeyring() async => null;

  @override
  Future<bool> isNfcSessionExpired() async => false;

  @override
  UserSession? currentUser;

  bool clearSessionCalled = false;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    return currentUser ?? UserSession.fromEmail(email);
  }

  @override
  Future<UserSession?> getCurrentUser() async => currentUser;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'test-token';

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<UserSession?> restoreSession() async => currentUser;

  @override
  ValueListenable<bool> get sessionExpired => ValueNotifier<bool>(false);

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    currentUser = null;
  }

  @override
  Future<void> logout({bool wipeLocalData = false}) async {
    await clearSession();
  }

  @override
  Future<bool> wipeLocalPhi({bool force = false}) async => true;

  @override
  bool get hasToken => currentUser != null;

  @override
  ValueNotifier<UserSession?> get sessionNotifier =>
      ValueNotifier<UserSession?>(currentUser);

  @override
  VoidCallback? onSessionInvalidated;

  @override
  Future<void> discardForeignPendingData() async {}

  @override
  Future<List<Map<String, Object?>>>
  pendingForeignEmergencyLogsForReview() async => <Map<String, Object?>>[];

  @override
  Future<List<LocalPatientEntry>> pendingForeignRecordsForReview() async =>
      <LocalPatientEntry>[];
}

class FakeLocalDatabase implements LocalDatabase {
  FakeLocalDatabase({this.pendingCount = 0});

  int pendingCount;

  @override
  Future<void> logEmergencyAccess({
    required String patientUid,
    String? patientName,
    String? userId,
    String reason = 'guardian_absent_offline',
    String? ownerUserId,
    String? organizationId,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs({
    String? ownerUserId,
  }) async => <Map<String, Object?>>[];

  @override
  Future<int> getUnsyncedEmergencyLogCount({String? ownerUserId}) async =>
      pendingCount;

  @override
  Future<int> getOrphanedEmergencyLogCount() async => 0;

  @override
  Future<int> getOrphanedPendingCount() async => 0;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> deleteRecord(String patientId) async {}

  @override
  Future<List<LocalPatientEntry>> getAllRecords({String? ownerUserId}) async =>
      <LocalPatientEntry>[];

  @override
  Future<List<MapEntry<String, String>>> getWebQuarantinedEntries() async =>
      <MapEntry<String, String>>[];

  @override
  List<String> get webQuarantinedKeysForTesting => <String>[];

  @override
  Future<int> getUnsyncedCount({String? ownerUserId}) async => pendingCount;

  @override
  Future<List<LocalPatientEntry>> getUnsyncedRecords({
    String? ownerUserId,
  }) async => <LocalPatientEntry>[];

  @override
  Future<void> markSyncError(
    String patientId,
    String error, {
    int? statusCode,
    int? revision,
  }) async {}

  @override
  Future<void> markSynced(
    String patientId, {
    String? createdAt,
    String? recordJson,
    int? revision,
  }) async {}

  @override
  Future<void> destroyEncryptionKey() async {}

  @override
  Future<void> markEmergencyLogsSynced(List<int> logIds) async {}

  @override
  Future<void> savePatient(
    PatientFullRecord record, {
    bool isSynced = false,
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
  }) async {}

  @override
  Future<NfcChipStatus?> getChipStatus(String patientId) async => null;

  @override
  Future<void> markChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {}

  @override
  Future<void> clearChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {}

  @override
  Future<void> purgeStalePermanentErrors({
    Duration maxAge = const Duration(days: 30),
  }) async {}

  @override
  Future<int> getBlockedCount({String? ownerUserId}) async => 0;

  @override
  Future<int> getRetryablePendingCount({String? ownerUserId}) async =>
      pendingCount;
}

/// Create a [UserSession] with the specified role.
UserSession _session(UserRole role, {String name = 'Ana Rodríguez'}) =>
    UserSession(
      id: 'uid-001',
      fullName: name,
      email: 'ana@hwb.org',
      role: role,
      organizationId: 'org-01',
    );

late FakeAuthRepository mockAuth;
late FakeLocalDatabase mockDb;

Widget _wrapHome({required UserSession? user}) {
  mockAuth.currentUser = user;

  final apiClient = ApiClient(baseUrl: 'https://example.com');
  final patientRepository = PatientRepository(
    apiClient: apiClient,
    authRepository: mockAuth,
  );
  final userRepository = UserRepository(
    apiClient: apiClient,
    authRepository: mockAuth,
  );
  final syncEngine = SyncEngine(
    patientRepository: patientRepository,
    localDatabase: mockDb,
  );

  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: AppScope(
      authRepository: mockAuth,
      userRepository: userRepository,
      patientRepository: patientRepository,
      localDatabase: mockDb,
      syncEngine: syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: mockAuth,
      ),
      reachability: Reachability(baseUrl: 'http://localhost'),
      child: MaterialApp(
        routes: {'/login': (_) => const LoginScreen()},
        home: const HomeScreen(),
      ),
    ),
  );
}

void _setUpMocks() {
  mockAuth = FakeAuthRepository();
  mockDb = FakeLocalDatabase(pendingCount: 0);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUp(_setUpMocks);

  // ── Group 1: Session-free redirection ───────────────────────────────────────
  group('HomeScreen — sin usuario activo', () {
    testWidgets('muestra LoginScreen cuando currentUser es null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapHome(user: null));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // ── Group 2: Header ───────────────────────────────────────────────────────
  group('HomeScreen — header', () {
    testWidgets('muestra el nombre completo del usuario', (tester) async {
      final user = _session(UserRole.doctor, name: 'Carlos Mejía');
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Mejía'), findsOneWidget);
    });

    testWidgets('muestra el saludo (no vacío)', (tester) async {
      final user = _session(UserRole.nurse);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      final greetingFinder = find.textContaining(',');
      expect(greetingFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('muestra el badge de rol', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('header tiene fondo con gradiente (Container decorado)', (
      tester,
    ) async {
      final user = _session(UserRole.nurse);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
      });
      expect(hasGradient, isTrue);
    });
  });

  // ── Group 3: Body superadmin ──────────────────────────────────────────────
  group('HomeScreen — body superadmin', () {
    testWidgets('muestra card de Gestionar organizaciones', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.business_outlined), findsOneWidget);
    });

    testWidgets('muestra card de Estadísticas de brigadas', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Estadísticas de brigadas'), findsOneWidget);
    });

    testWidgets('NO muestra card de Nuevo paciente para superadmin', (
      tester,
    ) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
    });

    testWidgets('muestra botón de cerrar sesión', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });
  });

  // ── Group 4: Body orgAdmin ────────────────────────────────────────────────
  group('HomeScreen — body orgAdmin', () {
    testWidgets('muestra card de Gestionar usuarios', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
    });

    testWidgets('NO muestra card de Historial de brigada', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history_rounded), findsNothing);
    });

    testWidgets('muestra card de Buscar paciente', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('NO muestra card de leer NFC para orgAdmin', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.nfc_rounded), findsNothing);
    });

    testWidgets('muestra card de Estadísticas de brigadas', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Estadísticas de brigadas'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    });
  });

  // ── Group 5: Body clínico (doctor / nurse) ────────────────────────────────
  group('HomeScreen — body clínico', () {
    for (final role in [UserRole.doctor, UserRole.nurse]) {
      testWidgets('$role — muestra card Leer NFC', (tester) async {
        final user = _session(role);
        await tester.pumpWidget(_wrapHome(user: user));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.nfc_rounded), findsOneWidget);
      });

      testWidgets('$role — muestra card Nuevo paciente', (tester) async {
        final user = _session(role);
        await tester.pumpWidget(_wrapHome(user: user));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
      });

      testWidgets('$role — muestra card Buscar paciente', (tester) async {
        final user = _session(role);
        await tester.pumpWidget(_wrapHome(user: user));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      });

      testWidgets('$role — muestra _SyncCard', (tester) async {
        final user = _session(role);
        await tester.pumpWidget(_wrapHome(user: user));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.cloud_done_outlined),
          findsOneWidget,
          reason: 'SyncCard con 0 pendientes muestra cloud_done',
        );
      });
    }
  });

  // ── Group 6: _SyncCard — state with pending ────────────────────────────
  group('_SyncCard — badge de pendientes', () {
    testWidgets(
      'sin pendientes muestra cloud_done y NO muestra badge numérico',
      (tester) async {
        mockDb.pendingCount = 0;
        final user = _session(UserRole.nurse);
        await tester.pumpWidget(_wrapHome(user: user));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      },
    );

    testWidgets('con 3 pendientes muestra cloud_upload y badge "3"', (
      tester,
    ) async {
      mockDb.pendingCount = 3;
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('el badge numérico está presente con pendientes', (
      tester,
    ) async {
      mockDb.pendingCount = 5;
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.textContaining('5'), findsWidgets);
    });
  });

  // ── Group 7: Logout dialog ────────────────────────────────────────────
  group('HomeScreen — logout dialog', () {
    Future<void> tapLogout(WidgetTester tester) async {
      final logoutIcon = find.byIcon(Icons.logout_rounded);
      await tester.scrollUntilVisible(logoutIcon, 80);
      await tester.ensureVisible(logoutIcon);
      await tester.pumpAndSettle();
      await tester.tap(logoutIcon);
      await tester.pumpAndSettle();
    }

    testWidgets('al tocar logout aparece el diálogo de confirmación', (
      tester,
    ) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      await tapLogout(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancelar en el diálogo NO llama clearSession', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      await tapLogout(tester);

      final cancelBtn = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          )
          .first;
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.clearSessionCalled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirmar logout llama clearSession', (tester) async {
      final user = _session(UserRole.nurse);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      await tapLogout(tester);

      final confirmBtn = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          )
          .last;
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.clearSessionCalled, isTrue);
    });

    testWidgets('el diálogo tiene exactamente 2 botones', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      await tapLogout(tester);

      final buttons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      expect(buttons, findsNWidgets(2));
    });

    testWidgets('el botón de confirmar usa color error (rojo)', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      await tapLogout(tester);

      final redText = find.byWidgetPredicate(
        (w) => w is Text && w.style?.color == AppColors.error,
      );
      expect(redText, findsOneWidget);
    });
  });

  // ── Group 8: Locale switcher ──────────────────────────────────────────────
  group('HomeScreen — selector de idioma', () {
    testWidgets('muestra botones ES y EN', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('ES'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });
  });

  // ── Group 9: ActionCard — visual structure ───────────────────────────────
  group('_ActionCard — estructura visual', () {
    testWidgets('cada card tiene ícono de flecha derecha', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right_rounded), findsAtLeastNWidgets(3));
    });

    testWidgets('cards tienen fondo blanco (AppColors.white)', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      final materials = tester.widgetList<Material>(find.byType(Material));
      final whiteCards = materials
          .where((m) => m.color == AppColors.white)
          .toList();
      expect(whiteCards.length, greaterThanOrEqualTo(3));
    });
  });
}
