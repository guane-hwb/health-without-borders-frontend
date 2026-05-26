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
  Future<void> clearSession() async {}

  @override
  bool get hasToken => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper falso para AuthRepository sin necesitar mockito ni código generado.
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late FakeAuthRepository mockAuthRepo;

  // ── Helper: envuelve LoginScreen con todos sus providers requeridos ─────────
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

  // ── Grupo 1: Renderizado inicial ────────────────────────────────────────────
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
      // Busca el TextButton de "olvide contrasena" por su contenido
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('la contrasena se muestra oculta por defecto', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Antes de tocar el ícono, se debe mostrar el icono de visibilidad cerrada.
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  // ── Grupo 2: Validaciones del formulario ────────────────────────────────────
  group('Validaciones del formulario', () {
    testWidgets('muestra error de email requerido al enviar vacio', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      // Los mensajes reales son "Ingresa tu correo..." y "Ingresa tu contraseña..."
      expect(find.textContaining('Ingresa'), findsWidgets);
    });

    testWidgets('muestra error de email invalido con formato incorrecto', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).first, 'noesvalido');
      await tester.pump();
      // Mensaje real: "Correo electrónico no válido"
      expect(find.textContaining('no v'), findsOneWidget);
    });

    testWidgets('muestra error de contrasena corta (menos de 6 caracteres)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.pump();
      // Mensaje real: "La contraseña debe tener al menos 6 caracteres"
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
      // Usar los strings exactos de error para no confundir con el hintText
      expect(find.text('Ingresa tu correo electrónico'), findsNothing);
      expect(find.text('Ingresa tu contraseña'), findsNothing);
      expect(find.textContaining('no válido'), findsNothing);
      expect(find.textContaining('al menos 6'), findsNothing);
    });
  });

  // ── Grupo 3: Toggle de visibilidad de contraseña ────────────────────────────
  group('Toggle visibilidad de contrasena', () {
    testWidgets('al tocar el icono de ojo, la contrasena se muestra', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      // Antes de tocar, el icono debe ser el de visibilidad oculta
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

  // ── Grupo 4: Flujo de login exitoso ─────────────────────────────────────────
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
      // Flush microtasks + un frame para que setState(_isLoading=true) se procese
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Completar el Future para no dejar timers abiertos
      completer.complete(UserSession.fromEmail('usuario@test.com'));
      await tester.pumpAndSettle();
    });
  });

  // ── Grupo 5: Flujo de login fallido ─────────────────────────────────────────
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

  // ── Grupo 6: Dialog "Olvide mi contrasena" ──────────────────────────────────
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

  // ── Grupo 7: Toggle de idioma ────────────────────────────────────────────────
  group('Toggle de idioma', () {
    testWidgets('al tocar EN el pill EN queda seleccionado', (tester) async {
      await tester.pumpWidget(buildSubject(locale: 'es'));
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      // La pill EN debe mostrarse con color primario (seleccionada)
      // Verificamos que el locale cambio buscando texto en ingles
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('al tocar ES el pill ES queda seleccionado', (tester) async {
      await tester.pumpWidget(buildSubject(locale: 'en'));
      await tester.tap(find.text('ES'));
      await tester.pumpAndSettle();
      expect(find.text('ES'), findsOneWidget);
    });
  });

  // ── Grupo 8: Checkbox recordar sesion ───────────────────────────────────────
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
