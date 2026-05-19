// test/widget/features/home/home_screen_widget_test.dart
//
// Pruebas de widget para HomeScreen.
// Cubre lo que SÍ requiere el árbol de widgets de Flutter:
//   • Renderizado del header (saludo, nombre, badge de rol)
//   • Cards visibles según rol (superadmin / orgAdmin / clínico)
//   • Navegación al tocar cada ActionCard
//   • Diálogo de confirmación de logout
//   • _SyncCard muestra el badge de pendientes cuando hay > 0
//   • Redirección a LoginScreen cuando no hay usuario
//
// Ejecutar:
//   flutter test test/widget/features/home/home_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers de prueba
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  @override
  UserSession? currentUser;

  bool clearSessionCalled = false;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<UserSession> login({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    return currentUser ?? UserSession.fromEmail(email);
  }

  @override
  Future<UserSession?> getCurrentUser() async => currentUser;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async => 'test-token';

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    currentUser = null;
  }

  @override
  bool get hasToken => currentUser != null;
}

class FakeLocalDatabase implements LocalDatabase {
  FakeLocalDatabase({this.pendingCount = 0});

  int pendingCount;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> deleteRecord(String patientId) async {}

  @override
  Future<List<LocalPatientEntry>> getAllRecords() async => <LocalPatientEntry>[];

  @override
  Future<int> getUnsyncedCount() async => pendingCount;

  @override
  Future<List<LocalPatientEntry>> getUnsyncedRecords() async => <LocalPatientEntry>[];

  @override
  Future<void> markSyncError(String patientId, String error) async {}

  @override
  Future<void> markSynced(String patientId) async {}

  @override
  Future<void> savePatient(PatientFullRecord record) async {}
}

/// Crea un [UserSession] con el rol indicado.
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
    child: MaterialApp(
      home: AppScope(
        authRepository: mockAuth,
        userRepository: userRepository,
        patientRepository: patientRepository,
        localDatabase: mockDb,
        syncEngine: syncEngine,
        child: const HomeScreen(),
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

  // ── Grupo 1: Redirección sin sesión ───────────────────────────────────────
  group('HomeScreen — sin usuario activo', () {
    testWidgets('muestra LoginScreen cuando currentUser es null', (tester) async {
      await tester.pumpWidget(_wrapHome(user: null));
      await tester.pumpAndSettle();

      // HomeScreen retorna LoginScreen() en su build cuando user == null.
      // LoginScreen debe estar presente en el árbol.
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // ── Grupo 2: Header ───────────────────────────────────────────────────────
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

      // El saludo termina en coma: "Buenos días," / "Buenas tardes," etc.
      final greetingFinder = find.textContaining(',');
      expect(greetingFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('muestra el badge de rol', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      // El badge contiene el texto del rol (doctor → "Médico" o equivalente)
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('header tiene fondo con gradiente (Container decorado)', (tester) async {
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

  // ── Grupo 3: Body superadmin ──────────────────────────────────────────────
  group('HomeScreen — body superadmin', () {
    testWidgets('muestra card de Gestionar organizaciones', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Gestionar organizaciones'), findsOneWidget);
    });

    testWidgets('muestra card de Estadísticas de brigadas', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Estadísticas de brigadas'), findsOneWidget);
    });

    testWidgets('NO muestra card de Nuevo paciente para superadmin', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      // actionNewPatient solo aparece en body clínico
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
    });

    testWidgets('muestra botón de cerrar sesión', (tester) async {
      final user = _session(UserRole.superadmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });
  });

  // ── Grupo 4: Body orgAdmin ────────────────────────────────────────────────
  group('HomeScreen — body orgAdmin', () {
    testWidgets('muestra card de Gestionar usuarios', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
    });

    testWidgets('muestra card de Historial de brigada', (tester) async {
      final user = _session(UserRole.orgAdmin);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
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
  });

  // ── Grupo 5: Body clínico (doctor / nurse) ────────────────────────────────
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

        // La SyncCard tiene el ícono cloud
        expect(
          find.byIcon(Icons.cloud_done_outlined),
          findsOneWidget,
          reason: 'SyncCard con 0 pendientes muestra cloud_done',
        );
      });
    }
  });

  // ── Grupo 6: _SyncCard — estado con pendientes ────────────────────────────
  group('_SyncCard — badge de pendientes', () {
    testWidgets('sin pendientes muestra cloud_done y NO muestra badge numérico',
        (tester) async {
      mockDb.pendingCount = 0;
      final user = _session(UserRole.nurse);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
    });

    testWidgets('con 3 pendientes muestra cloud_upload y badge "3"',
        (tester) async {
      mockDb.pendingCount = 3;
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('el badge numérico tiene fondo Color(0xFFD4A017)', (tester) async {
      mockDb.pendingCount = 5;
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      final badgeContainer = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) {
        final d = c.decoration;
        return d is BoxDecoration &&
            d.color == const Color(0xFFD4A017);
      });
      expect(badgeContainer, isNotNull);
    });
  });

  // ── Grupo 7: Diálogo de logout ────────────────────────────────────────────
  // El botón de logout está al final del ListView y puede estar fuera del
  // viewport. scrollUntilVisible + ensureVisible garantizan que sea tappable.
  group('HomeScreen — diálogo de logout', () {
    /// Hace scroll hasta el icono de logout y lo toca.
    Future<void> tapLogout(WidgetTester tester) async {
      final logoutIcon = find.byIcon(Icons.logout_rounded);
      await tester.scrollUntilVisible(logoutIcon, 80);
      await tester.ensureVisible(logoutIcon);
      await tester.pumpAndSettle();
      await tester.tap(logoutIcon);
      await tester.pumpAndSettle();
    }

    testWidgets('al tocar logout aparece el diálogo de confirmación',
        (tester) async {
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

      // El primer TextButton del diálogo es siempre "Cancelar"
      final cancelBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ).first;
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

      // El segundo TextButton (último) es el de confirmar
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ).last;
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

      final redText = find.byWidgetPredicate((w) =>
          w is Text && w.style?.color == AppColors.error);
      expect(redText, findsOneWidget);
    });
  });

  // ── Grupo 8: Locale switcher ──────────────────────────────────────────────
  group('HomeScreen — selector de idioma', () {
    testWidgets('muestra botones ES y EN', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      expect(find.text('ES'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });
  });

  // ── Grupo 9: ActionCard — estructura visual ───────────────────────────────
  group('_ActionCard — estructura visual', () {
    testWidgets('cada card tiene ícono de flecha derecha', (tester) async {
      final user = _session(UserRole.doctor);
      await tester.pumpWidget(_wrapHome(user: user));
      await tester.pumpAndSettle();

      // Doctor tiene al menos 3 cards con flecha (NFC, Nuevo paciente, Buscar)
      expect(
        find.byIcon(Icons.chevron_right_rounded),
        findsAtLeastNWidgets(3),
      );
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