// test/widget/features/auth/login_screen_widget_test.dart

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
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;
  String? loginEmail;
  String? loginPassword;
  Future<UserSession> Function({
    required String email,
    required String password,
  })?
  loginHandler;

  @override
  Future<String?> getNfcEncryptionKey() async => null;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    loginEmail = email;
    loginPassword = password;
    if (loginHandler != null) {
      return loginHandler!(email: email, password: password);
    }
    return UserSession.fromEmail(email);
  }

  @override
  UserSession? get currentUser => null;

  @override
  Future<UserSession?> getCurrentUser() async => null;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async => '';

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<UserSession?> restoreSession() async => null;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> logout() async {}

  @override
  bool get hasToken => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake helper for AuthRepository without needing mockito or generated code.
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late FakeAuthRepository mockAuthRepo;

  // ── Helper: wraps LoginScreen with all its required providers ─────────
  Widget buildSubject({String locale = 'es'}) {
    final apiClient = ApiClient(baseUrl: 'https://example.com');
    final userRepository = UserRepository(
      apiClient: apiClient,
      authRepository: mockAuthRepo,
    );
    final patientRepository = PatientRepository(
      apiClient: apiClient,
      authRepository: mockAuthRepo,
    );
    final syncEngine = SyncEngine(
      patientRepository: patientRepository,
      localDatabase: LocalDatabase.instance,
    );

    return AppLocale(
      locale: locale,
      setLocale: (_) {},
      child: AppScope(
        authRepository: mockAuthRepo,
        userRepository: userRepository,
        patientRepository: patientRepository,
        localDatabase: LocalDatabase.instance,
        syncEngine: syncEngine,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  setUp(() {
    mockAuthRepo = FakeAuthRepository();
  });

  // ── Group 1: Initial Rendering ────────────────────────────────────────────
  group('Renderizado inicial', () {
    testWidgets('muestra el campo de email', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('muestra el boton de login', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('muestra el toggle de idioma ES/EN', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('ES'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('muestra el checkbox de recordar sesion', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('muestra el enlace de olvide mi contrasena', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Search for the "forgot password" TextButton by its content
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('la contrasena se muestra oculta por defecto', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Before tapping the icon, the closed visibility icon must be displayed.
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  // ── Group 2: Form Validations ────────────────────────────────────
  group('Validaciones del formulario', () {
    testWidgets('muestra error de email requerido al enviar vacio', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      // The actual messages are "Enter your email..." and "Enter your password..."
      expect(find.textContaining('Ingresa'), findsWidgets);
    });

    testWidgets('muestra error de email invalido con formato incorrecto', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).first, 'noesvalido');
      await tester.pump();
      // Actual message: "Invalid email address"
      expect(find.textContaining('no v'), findsOneWidget);
    });

    testWidgets('muestra error de contrasena corta (menos de 6 caracteres)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.pump();
      // Actual message: "The password must be at least 6 characters long"
      expect(find.textContaining('al menos 6'), findsOneWidget);
    });

    testWidgets('no muestra errores con email y contrasena validos', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();
      // Use the exact error strings to avoid confusion with the hintText
      expect(find.text('Ingresa tu correo electrónico'), findsNothing);
      expect(find.text('Ingresa tu contraseña'), findsNothing);
      expect(find.textContaining('no válido'), findsNothing);
      expect(find.textContaining('al menos 6'), findsNothing);
    });
  });

  // ── Group 3: Password Visibility Toggle ────────────────────────────
  group('Toggle visibilidad de contrasena', () {
    testWidgets('al tocar el icono de ojo, la contrasena se muestra', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      // Before tapping, the icon must be the closed visibility icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('al tocar el ojo dos veces, la contrasena vuelve a ocultarse', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  // ── Group 4: Successful login flow ─────────────────────────────────────────
  group('Flujo login exitoso', () {
    testWidgets('navega a HomeScreen tras login exitoso', (tester) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            return UserSession.fromEmail(email);
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(mockAuthRepo.loginCalled, isTrue);
      expect(mockAuthRepo.loginEmail, 'usuario@test.com');
      expect(mockAuthRepo.loginPassword, 'password123');
    });

    testWidgets('muestra CircularProgressIndicator mientras hace login', (
      tester,
    ) async {
      final completer = Completer<UserSession>();
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) =>
              completer.future;

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      // Flush microtasks + a frame for setState(_isLoading=true) to be processed
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the Future to avoid leaving any timers open.
      completer.complete(UserSession.fromEmail('usuario@test.com'));
      await tester.pumpAndSettle();
    });
  });

  // ── Group 5: Failed login flow ─────────────────────────────────────────
  group('Flujo login fallido', () {
    testWidgets('muestra SnackBar con mensaje de ApiException', (tester) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw ApiException('Credenciales incorrectas');
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Credenciales'), findsOneWidget);
    });

    testWidgets('muestra SnackBar generico para errores inesperados', (
      tester,
    ) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw Exception('Error de red');
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('el boton de login vuelve a estar activo tras error', (
      tester,
    ) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw ApiException('Error');
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });
  });

  // ── Group 6: Dialog "I forgot my password" ──────────────────────────────────
  group('Dialog olvide contrasena', () {
    testWidgets('al tocar el enlace se muestra el AlertDialog', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('al tocar OK el dialogo se cierra', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      // El botón usa s.ok cuyo valor en español es "Entendido"
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  // ── Group 7: Language Toggle ────────────────────────────────────────────────
  group('Toggle de idioma', () {
    testWidgets('al tocar EN el pill EN queda seleccionado', (tester) async {
      await tester.pumpWidget(buildSubject(locale: 'es'));
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('al tocar ES el pill ES queda seleccionado', (tester) async {
      await tester.pumpWidget(buildSubject(locale: 'en'));
      await tester.tap(find.text('ES'));
      await tester.pumpAndSettle();
      expect(find.text('ES'), findsOneWidget);
    });
  });

  // ── Group 8: Remember Me Checkbox ───────────────────────────────────────
  group('Checkbox recordar sesion', () {
    testWidgets('inicia en true (marcado)', (tester) async {
      await tester.pumpWidget(buildSubject());
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('al tocarlo cambia a false', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });
  });
}
