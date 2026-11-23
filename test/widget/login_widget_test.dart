// test/widget/login_widget_test.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

UserSession buildTestSession(String email) => UserSession(
  id: 'test-user-id',
  email: email,
  fullName: 'Test User',
  role: UserRole.doctor,
  organizationId: 'test-organization-id',
);

/// The [ApiException] the real [ApiClient] throws when the sign-in request
/// gets [response], so the screen sees exactly what production hands it.
Future<ApiException> apiErrorFor(http.Response response) async {
  final ApiClient client = ApiClient(
    baseUrl: 'https://example.com',
    client: MockClient((_) async => response),
  );
  try {
    await client.postForm(
      path: '/api/v1/login/access-token',
      form: const <String, String>{},
    );
  } on ApiException catch (e) {
    return e;
  }
  throw StateError('the client accepted HTTP ${response.statusCode}');
}

class FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;
  String? loginEmail;
  String? loginPassword;
  UserSession? _session;

  Future<UserSession> Function({
    required String email,
    required String password,
  })?
  loginHandler;

  @override
  Future<NfcKeyring?> getNfcKeyring() async => null;

  @override
  Future<bool> isNfcSessionExpired() async => false;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
    bool rememberSession = true,
  }) async {
    loginCalled = true;
    loginEmail = email;
    loginPassword = password;
    if (loginHandler != null) {
      _session = await loginHandler!(email: email, password: password);
      return _session!;
    }
    _session = buildTestSession(email);
    return _session!;
  }

  @override
  UserSession? get currentUser => _session;

  /// Set to a code to simulate a session ended by a deactivated account.
  final ValueNotifier<String?> inactiveCode = ValueNotifier<String?>(null);

  @override
  ValueListenable<String?> get accountInactiveCode => inactiveCode;

  @override
  Future<UserSession?> getCurrentUser() async => _session;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async => '';

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<UserSession?> restoreSession() async => _session;

  @override
  ValueListenable<bool> get sessionExpired => ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get sessionWindowClosed => ValueNotifier<bool>(false);

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<void> logout({bool wipeLocalData = false}) async {
    await clearSession();
  }

  @override
  Future<bool> wipeLocalPhi({bool force = false}) async => true;

  @override
  bool get hasToken => _session != null;

  @override
  ValueNotifier<UserSession?> get sessionNotifier =>
      ValueNotifier<UserSession?>(_session);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake helper for AuthRepository without needing mockito or generated code.
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late FakeAuthRepository mockAuthRepo;

  // ── Helper: wraps LoginScreen with all its required providers ─────────
  Widget buildSubject({
    String locale = 'es',
    bool showSessionExpired = false,
    Widget? home,
  }) {
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
        statsRepository: StatsRepository(
          apiClient: ApiClient(baseUrl: 'http://localhost'),
          authRepository: mockAuthRepo,
        ),
        reachability: Reachability(baseUrl: 'http://localhost'),
        child: MaterialApp(
          routes: {'/login': (_) => const LoginScreen()},
          home: home ?? LoginScreen(showSessionExpired: showSessionExpired),
        ),
      ),
    );
  }

  setUp(() {
    mockAuthRepo = FakeAuthRepository();
  });

  group('Aviso de sesión expirada', () {
    testWidgets('muestra el aviso cuando showSessionExpired es true', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(showSessionExpired: true));
      await tester.pump(); // dispara el post-frame callback -> showSnackBar
      await tester.pump(const Duration(milliseconds: 500)); // deja aparecer

      expect(
        find.text('Sesión expirada. Inicie sesión nuevamente.'),
        findsOneWidget,
      );
    });

    testWidgets('si la cuenta fue desactivada lo dice en lugar de "expirada"', (
      tester,
    ) async {
      mockAuthRepo.inactiveCode.value = 'user_inactive';
      await tester.pumpWidget(buildSubject(showSessionExpired: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Tu cuenta está desactivada'), findsOneWidget);
      expect(
        find.textContaining('Los registros pendientes se conservan'),
        findsOneWidget,
      );
      expect(
        find.text('Sesión expirada. Inicie sesión nuevamente.'),
        findsNothing,
      );
    });

    testWidgets('no muestra el aviso por defecto', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Sesión expirada. Inicie sesión nuevamente.'),
        findsNothing,
      );
    });
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
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('la contrasena se muestra oculta por defecto', (tester) async {
      await tester.pumpWidget(buildSubject());
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
      expect(find.textContaining('Ingresa'), findsWidgets);
    });

    testWidgets('muestra error de email invalido con formato incorrecto', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).first, 'noesvalido');
      await tester.pump();
      expect(find.textContaining('no v'), findsOneWidget);
    });

    testWidgets('muestra error de contrasena corta (menos de 6 caracteres)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.pump();
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
      expect(find.text('Ingresa tu correo electrónico'), findsNothing);
      expect(find.text('Ingresa tu contraseña'), findsNothing);
      expect(find.textContaining('no válido'), findsNothing);
      expect(find.textContaining('al menos 6'), findsNothing);
    });
  });

  group('Correo del inicio de sesión: el validador común', () {
    Future<void> submitEmail(WidgetTester tester, String email) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    for (final String email in <String>[
      'enfermera@salud.gov.co',
      'juan.perez@cruzroja.org.co',
      'user@guane.com.co',
      'ana+brigada@unicef.org',
      'medico@unicef.org',
    ]) {
      testWidgets('acepta $email y envía la petición', (tester) async {
        await submitEmail(tester, email);

        expect(find.text('Correo electrónico no válido'), findsNothing);
        expect(mockAuthRepo.loginCalled, isTrue);
        expect(mockAuthRepo.loginEmail, email);
      });
    }

    for (final (String email, String message) in <(String, String)>[
      ('sin-arroba', 'Correo electrónico no válido'),
      ('a@b', 'Correo electrónico no válido'),
      ('', 'Ingresa tu correo electrónico'),
    ]) {
      testWidgets('rechaza «$email» sin enviar la petición', (tester) async {
        await submitEmail(tester, email);

        expect(find.text(message), findsOneWidget);
        expect(mockAuthRepo.loginCalled, isFalse);
      });
    }
  });

  // ── Group 3: Password Visibility Toggle ────────────────────────────
  group('Toggle visibilidad de contrasena', () {
    testWidgets('al tocar el icono de ojo, la contrasena se muestra', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
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
            return buildTestSession(email);
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
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(buildTestSession('usuario@test.com'));
      await tester.pumpAndSettle();
    });
  });

  // ── Group 5: Failed login flow ─────────────────────────────────────────
  group('Flujo login fallido', () {
    testWidgets(
      'una ApiException sin estado ni code muestra el mensaje genérico, '
      'nunca su texto',
      (tester) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              // Lo que lanza AuthRepository.login si falta el token.
              throw ApiException('Login did not return an access token.');
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
        expect(
          find.text('No se pudo iniciar sesión. Intente de nuevo.'),
          findsOneWidget,
        );
        expect(find.textContaining('access token'), findsNothing);
      },
    );

    testWidgets('un rechazo con code muestra el mensaje traducido', (
      tester,
    ) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw ApiException(
              'Organization is inactive.',
              statusCode: 401,
              code: 'organization_inactive',
            );
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Tu organización está desactivada'),
        findsOneWidget,
      );
      expect(find.text('Organization is inactive.'), findsNothing);
      expect(find.text('Correo o contraseña incorrectos.'), findsNothing);
    });

    for (final (String name, http.Response response, String message, String raw)
        in <(String, http.Response, String, String)>[
          (
            '401 sin code (contraseña errada)',
            http.Response(
              '{"detail":"Incorrect email or password"}',
              401,
              headers: <String, String>{'content-type': 'application/json'},
            ),
            'Correo o contraseña incorrectos.',
            'Incorrect email or password',
          ),
          (
            '302 de un portal cautivo',
            http.Response(
              '',
              302,
              headers: <String, String>{
                'location': 'http://portal.example/login',
              },
            ),
            'La red Wi-Fi pide aceptar sus condiciones en el navegador. '
                'Ábralo, acéptelas y vuelva a intentar.',
            'Untrusted redirect',
          ),
          (
            '200 con la página HTML de un portal cautivo',
            http.Response(
              '<html><body>Acepte las condiciones</body></html>',
              200,
              headers: <String, String>{'content-type': 'text/html'},
            ),
            'La red Wi-Fi pide aceptar sus condiciones en el navegador. '
                'Ábralo, acéptelas y vuelva a intentar.',
            'Unexpected response payload format',
          ),
          (
            '511 de un portal cautivo',
            http.Response('<html><body>Portal</body></html>', 511),
            'La red Wi-Fi pide aceptar sus condiciones en el navegador. '
                'Ábralo, acéptelas y vuelva a intentar.',
            'HTTP 511',
          ),
          (
            '500 sin code',
            http.Response('', 500),
            'El servidor no responde. Intente de nuevo en unos minutos.',
            'Server error',
          ),
          (
            '503 con la página HTML del balanceador',
            http.Response('<html><body>Service Unavailable</body></html>', 503),
            'El servidor no responde. Intente de nuevo en unos minutos.',
            'Server error',
          ),
          (
            '404 sin code',
            http.Response('', 404),
            'No se pudo iniciar sesión. Intente de nuevo.',
            'Not found',
          ),
          (
            '422 con detail en inglés',
            http.Response(
              '{"detail":"Field required"}',
              422,
              headers: <String, String>{'content-type': 'application/json'},
            ),
            'No se pudo iniciar sesión. Intente de nuevo.',
            'Field required',
          ),
        ]) {
      testWidgets('un $name se explica en español y sin jerga HTTP', (
        tester,
      ) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              throw await apiErrorFor(response);
            };

        await tester.pumpWidget(buildSubject());
        await tester.enterText(
          find.byType(TextFormField).first,
          'usuario@test.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(find.textContaining(raw), findsNothing);
        expect(find.textContaining('HTTP'), findsNothing);
      });
    }

    testWidgets('en inglés, el 401 sin code dice que el correo o la '
        'contraseña no coinciden', (tester) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw await apiErrorFor(
              http.Response('{"detail":"Incorrect email or password"}', 401),
            );
          };

      await tester.pumpWidget(buildSubject(locale: 'en'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    for (final (String name, ApiException error, String message)
        in <(String, ApiException, String)>[
          (
            'login_paused con Retry-After',
            ApiException(
              'Too many failed sign-in attempts for this account. Try again '
              'in 120 seconds.',
              statusCode: 429,
              code: 'login_paused',
              retryAfter: const Duration(seconds: 120),
            ),
            'Demasiados intentos. Intente de nuevo en 2 minutos.',
          ),
          (
            'límite por IP sin code',
            ApiException('Request failed (HTTP 429).', statusCode: 429),
            'Demasiados intentos. Espere unos minutos e intente de nuevo.',
          ),
        ]) {
      testWidgets('un 429 ($name) dice cuánto esperar', (tester) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              throw error;
            };

        await tester.pumpWidget(buildSubject());
        await tester.enterText(
          find.byType(TextFormField).first,
          'usuario@test.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('muestra SnackBar generico para errores inesperados', (
      tester,
    ) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            throw Exception('Error genérico');
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
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('en inglés el diálogo muestra su texto, no las claves', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(locale: 'en'));
      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();

      expect(
        find.text('Contact the system administrator to reset your password.'),
        findsOneWidget,
      );
      expect(find.text('forgotPasswordMessage'), findsNothing);
      expect(find.text('ok'), findsNothing);

      await tester.tap(find.text('Got it'));
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
    setUp(() {
      LoginScreen.debugIsWebOverride = false;
    });

    tearDown(() {
      LoginScreen.debugIsWebOverride = null;
    });

    testWidgets('inicia en false (desmarcado por seguridad)', (tester) async {
      await tester.pumpWidget(buildSubject());
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('al tocarlo cambia a true', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets(
      'criterio de aceptacion auditoria: en web no se muestra la casilla y se aclara que la sesion termina al cerrar la pestana',
      (tester) async {
        LoginScreen.debugIsWebOverride = true;
        await tester.pumpWidget(buildSubject());

        expect(find.byType(Checkbox), findsNothing);
        expect(
          find.text('En el navegador la sesión termina al cerrar la pestaña'),
          findsOneWidget,
        );
      },
    );
  });

  group('LoginScreen — Uncovered Branches & Keyboard Submissions', () {
    testWidgets('onSubmitted en email solicita foco al campo de contraseña', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      final emailField = find.byType(TextFormField).first;
      await tester.showKeyboard(emailField);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('onSubmitted en contraseña ejecuta el método de login', (
      tester,
    ) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async {
            return buildTestSession(email);
          };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      final passwordField = find.byType(TextFormField).last;
      await tester.showKeyboard(passwordField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(mockAuthRepo.loginCalled, isTrue);
    });

    testWidgets(
      'muestra SnackBar de conexión requerida al capturar un error genérico de SocketException',
      (tester) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              throw Exception(
                'SocketException: Failed host lookup: api.example.com',
              );
            };

        await tester.pumpWidget(buildSubject());
        await tester.enterText(
          find.byType(TextFormField).first,
          'usuario@test.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(s.loginNetworkRequired), findsOneWidget);
      },
    );

    testWidgets(
      'ApiException cuyo mensaje menciona un problema de red muestra el '
      'aviso de conexión requerida (rama distinta al catch genérico)',
      (tester) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              throw ApiException(
                'SocketException: Failed host lookup: api.example.com',
              );
            };

        await tester.pumpWidget(buildSubject());
        await tester.enterText(
          find.byType(TextFormField).first,
          'usuario@test.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(s.loginNetworkRequired), findsOneWidget);
        expect(find.textContaining('Failed host lookup'), findsNothing);
      },
    );

    testWidgets(
      'tocar el texto de _RememberCheckbox conmuta el valor de la casilla',
      (tester) async {
        LoginScreen.debugIsWebOverride = false;
        await tester.pumpWidget(buildSubject());

        final s = AppStrings.forTesting('es');
        await tester.tap(find.text(s.rememberSession));
        await tester.pump();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
        LoginScreen.debugIsWebOverride = null;
      },
    );
  });

  group('LoginScreen — errores de red tipados (catch dedicados)', () {
    final errors = <(String, Object Function())>[
      ('SocketException', () => const SocketException('sin red')),
      ('TimeoutException', () => TimeoutException('tiempo agotado')),
      ('http.ClientException', () => http.ClientException('conexión caída')),
    ];

    Future<void> submit(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
    }

    for (final (name, build) in errors) {
      testWidgets(
        '$name muestra el aviso de conexión requerida y reactiva el botón',
        (tester) async {
          mockAuthRepo.loginHandler =
              ({required String email, required String password}) async {
                throw build();
              };

          await tester.pumpWidget(buildSubject());
          await submit(tester);
          await tester.pumpAndSettle();

          final s = AppStrings.forTesting('es');
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.text(s.loginNetworkRequired), findsOneWidget);
          expect(find.text(s.loginFailed), findsNothing);
          final btn = tester.widget<ElevatedButton>(
            find.byType(ElevatedButton),
          );
          expect(btn.onPressed, isNotNull);
        },
      );

      testWidgets('$name muestra el aviso de conexión en inglés', (
        tester,
      ) async {
        mockAuthRepo.loginHandler =
            ({required String email, required String password}) async {
              throw build();
            };

        await tester.pumpWidget(buildSubject(locale: 'en'));
        await submit(tester);
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('en');
        expect(find.text(s.loginNetworkRequired), findsOneWidget);
      });

      testWidgets(
        '$name con la pantalla desmontada no muestra aviso ni lanza errores',
        (tester) async {
          final completer = Completer<UserSession>();
          mockAuthRepo.loginHandler =
              ({required String email, required String password}) =>
                  completer.future;

          await tester.pumpWidget(buildSubject());
          await submit(tester);
          await tester.pump();

          await tester.pumpWidget(const SizedBox());
          completer.completeError(build());
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Sesión vencida: la contraseña se pide sobre la pantalla abierta', () {
    const String written = 'Fiebre de 3 días';

    /// A form with something written in it, and the session expiring over it
    /// as the app reacts to AuthRepository.sessionExpired.
    Future<NavigatorState> expireOverForm(
      WidgetTester tester, {
      required String? expiredUserId,
    }) async {
      await tester.pumpWidget(
        buildSubject(home: const Scaffold(body: TextField())),
      );
      await tester.enterText(find.byType(TextField), written);
      await tester.pump();
      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      reauthenticateOverCurrentScreen(
        navigator,
        expiredUserId: expiredUserId,
      ).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      return navigator;
    }

    Future<void> signIn(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextFormField).first,
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('si entra la misma persona, vuelve al formulario con lo '
        'escrito', (tester) async {
      final NavigatorState navigator = await expireOverForm(
        tester,
        expiredUserId: 'test-user-id',
      );

      await signIn(tester);

      expect(mockAuthRepo.loginCalled, isTrue);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text(written), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('si entra otra cuenta, deja sólo el inicio de esa cuenta', (
      tester,
    ) async {
      final NavigatorState navigator = await expireOverForm(
        tester,
        expiredUserId: 'otra-persona',
      );

      await signIn(tester);

      expect(find.text(written), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('si la misma persona debe cambiar la contraseña, deja sólo el '
        'inicio, que se lo pide', (tester) async {
      mockAuthRepo.loginHandler =
          ({required String email, required String password}) async =>
              buildTestSession(email).copyWith(mustChangePassword: true);
      final NavigatorState navigator = await expireOverForm(
        tester,
        expiredUserId: 'test-user-id',
      );

      await signIn(tester);

      expect(find.text(written), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('si sale con el retroceso, deja sólo el inicio de sesión', (
      tester,
    ) async {
      final NavigatorState navigator = await expireOverForm(
        tester,
        expiredUserId: 'test-user-id',
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(mockAuthRepo.loginCalled, isFalse);
      expect(find.text(written), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });
  });
}
