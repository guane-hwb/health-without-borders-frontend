// test/widget/change_password_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/change_password_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

class _MockLocalDatabase extends Mock implements LocalDatabase {}

class _Auth extends Fake implements AuthRepository {
  _Auth(this.user);

  UserSession? user;
  Object? error;
  final List<List<String>> calls = <List<String>>[];

  @override
  UserSession? get currentUser => user;

  @override
  ValueNotifier<UserSession?> get sessionNotifier =>
      ValueNotifier<UserSession?>(user);

  @override
  Future<UserSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls.add(<String>[currentPassword, newPassword]);
    final Object? e = error;
    if (e != null) throw e;
    user = user!.copyWith(mustChangePassword: false);
    return user!;
  }
}

final UserSession _user = UserSession(
  id: 'u1',
  email: 'ana@hwb.org',
  fullName: 'Ana Rodríguez',
  role: UserRole.nurse,
  organizationId: 'o1',
);

Widget _app(_Auth auth, {String locale = 'es'}) {
  final ApiClient api = ApiClient(baseUrl: 'https://example.com');
  final PatientRepository patients = PatientRepository(
    apiClient: api,
    authRepository: auth,
  );
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: AppScope(
      authRepository: auth,
      userRepository: UserRepository(apiClient: api, authRepository: auth),
      patientRepository: patients,
      localDatabase: _MockLocalDatabase(),
      syncEngine: SyncEngine(
        patientRepository: patients,
        localDatabase: _MockLocalDatabase(),
      ),
      statsRepository: StatsRepository(apiClient: api, authRepository: auth),
      reachability: Reachability(baseUrl: 'http://localhost'),
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _Auth auth, {
  String locale = 'es',
}) async {
  await tester.pumpWidget(_app(auth, locale: locale));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  String current = 'temporal-123',
  String next = 'una-clave-larga-1',
  String? confirm,
}) async {
  await tester.enterText(
    find.byKey(const Key('change_password_current')),
    current,
  );
  await tester.enterText(find.byKey(const Key('change_password_new')), next);
  await tester.enterText(
    find.byKey(const Key('change_password_confirm')),
    confirm ?? next,
  );
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Guardar contraseña'));
  await tester.pumpAndSettle();
}

void main() {
  late _Auth auth;

  setUp(() => auth = _Auth(_user));

  testWidgets('desde el menú tiene botón atrás y no muestra el aviso', (
    tester,
  ) async {
    await _open(tester, auth);

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.textContaining('Un administrador'), findsNothing);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('valida en la app antes de enviar', (tester) async {
    await _open(tester, auth);

    await _save(tester);
    expect(find.text('Escriba la contraseña actual.'), findsOneWidget);
    expect(find.text('Debe tener al menos 12 caracteres.'), findsOneWidget);

    await _fill(tester, next: 'una-clave-larga-1', confirm: 'otra-distinta-1');
    await _save(tester);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    await _fill(tester, current: 'misma-clave-12', next: 'misma-clave-12');
    await _save(tester);
    expect(
      find.text('Debe ser distinta de la contraseña actual.'),
      findsOneWidget,
    );

    expect(auth.calls, isEmpty);
  });

  testWidgets('guarda, avisa y vuelve atrás', (tester) async {
    await _open(tester, auth);
    await _fill(tester);
    await _save(tester);

    expect(auth.calls, <List<String>>[
      <String>['temporal-123', 'una-clave-larga-1'],
    ]);
    expect(find.text('Contraseña actualizada.'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  final Map<String, (Object, String)> errors = <String, (Object, String)>{
    '400 → la actual no es correcta': (
      ApiException('The current password is not correct.', statusCode: 400),
      'La contraseña actual no es correcta.',
    ),
    '422 → la política': (
      ApiException('x', statusCode: 422),
      'La nueva contraseña no cumple la política: al menos 12 caracteres, '
          'máximo 72 bytes y que no sea común.',
    ),
    '429 login_paused → cuánto esperar': (
      ApiException(
        'Too many failed sign-in attempts.',
        statusCode: 429,
        code: 'login_paused',
        retryAfter: const Duration(seconds: 120),
      ),
      'Demasiados intentos. Intente de nuevo en 2 minutos.',
    ),
    '403 con code conocido → su mensaje': (
      ApiException('Inactive', statusCode: 403, code: 'user_inactive'),
      'Tu cuenta está desactivada. Contacta al administrador de tu '
          'organización.',
    ),
    '500 sin code → genérico': (
      ApiException('boom', statusCode: 500),
      'No se pudo cambiar la contraseña.',
    ),
    'sin red → revisar la conexión': (
      Exception('SocketException'),
      'No se pudo cambiar la contraseña. Revise la conexión e intente de '
          'nuevo.',
    ),
  };
  errors.forEach((String name, (Object, String) c) {
    testWidgets(name, (tester) async {
      auth.error = c.$1;
      await _open(tester, auth);
      await _fill(tester);
      await _save(tester);

      expect(find.text(c.$2), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });
  });

  testWidgets('Mostrar/Ocultar alterna el texto de los tres campos', (
    tester,
  ) async {
    await _open(tester, auth);
    bool obscured() => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .every((EditableText t) => t.obscureText);

    expect(obscured(), isTrue);
    await tester.tap(find.text('Mostrar'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.text('Ocultar'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('en inglés', (tester) async {
    await _open(tester, auth, locale: 'en');
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Save password'), findsOneWidget);
  });
}
