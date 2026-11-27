// test/widget/lock_gate_widget_test.dart

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:health_without_borders_frontend/src/features/auth/presentation/auth_gate.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/lock_gate.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/login_screen.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepo;
  final ValueNotifier<bool> localLockedNotifier = ValueNotifier<bool>(true);

  setUp(() {
    authRepo = MockAuthRepository();
    localLockedNotifier.value = true;
    when(() => authRepo.isLocalLocked).thenReturn(localLockedNotifier);
    when(() => authRepo.setLocalLocked(any())).thenAnswer((invocation) {
      localLockedNotifier.value = invocation.positionalArguments.first as bool;
    });
    when(() => authRepo.currentUser).thenReturn(
      UserSession(
        id: '1',
        email: 'nurse@hwb.org',
        fullName: 'Enfermera Ana',
        role: UserRole.nurse,
        organizationId: 'org-1',
      ),
    );
  });

  // El mismo builder que lib/src/app.dart: el bloqueo es una capa sobre el
  // Navigator, y AuthGate queda debajo.
  Widget wrapWidget(Widget child) {
    final navigatorKey = GlobalKey<NavigatorState>();
    final controller = LockController(authRepository: authRepo);
    addTearDown(controller.dispose);
    return AppLocale(
      locale: 'es',
      setLocale: (_) {},
      child: MaterialApp(
        navigatorKey: navigatorKey,
        builder: (BuildContext context, Widget? child) => LockLayer(
          controller: controller,
          authRepository: authRepo,
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: child,
      ),
    );
  }

  testWidgets(
    'restaurar sesión muestra un solo LockScreen (pantalla de bloqueo), no HomeScreen directo',
    (tester) async {
      when(() => authRepo.restoreSession()).thenAnswer(
        (_) async => UserSession(
          id: '1',
          email: 'nurse@hwb.org',
          fullName: 'Enfermera Ana',
          role: UserRole.nurse,
          organizationId: 'org-1',
        ),
      );

      await tester.pumpWidget(wrapWidget(AuthGate(authRepository: authRepo)));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Sesión bloqueada'), findsOneWidget);
    },
  );

  test('con la app bloqueada, getNfcKeyring() devuelve null', () async {
    when(() => authRepo.isLocalLocked).thenReturn(ValueNotifier<bool>(true));
    when(() => authRepo.getNfcKeyring()).thenAnswer((_) async => null);

    final keyring = await authRepo.getNfcKeyring();
    expect(keyring, isNull);
  });

  test('tras 10 minutos de inactividad, LockController activa el bloqueo', () {
    fakeAsync((async) {
      localLockedNotifier.value = false;
      final controller = LockController(
        authRepository: authRepo,
        foregroundTimeout: const Duration(minutes: 10),
      );

      controller.recordUserActivity();
      async.elapse(const Duration(minutes: 9));
      expect(localLockedNotifier.value, isFalse);

      async.elapse(const Duration(minutes: 2));
      expect(localLockedNotifier.value, isTrue);

      controller.dispose();
    });
  });

  group('LockLayer, la capa del builder de la app', () {
    late _LockAuth auth;

    setUp(() => auth = _LockAuth());

    Future<void> pumpLocked(WidgetTester tester) async {
      await tester.pumpWidget(_LockedApp(auth: auth));
      auth.setLocalLocked(true);
      await tester.pump();
      expect(find.byType(LockScreen), findsOneWidget);
    }

    Finder passwordField() => find.descendant(
      of: find.byType(LockScreen),
      matching: find.byType(TextField),
    );

    testWidgets(
      'con el bloqueo, lo de debajo sale del árbol de semántica y sólo queda el LockScreen',
      (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await tester.pumpWidget(_LockedApp(auth: auth));
        expect(find.semantics.byLabel(RegExp('Penicilina')), findsOne);
        expect(find.semantics.byLabel(RegExp('Ver consultas')), findsOne);

        auth.setLocalLocked(true);
        await tester.pump();

        expect(find.semantics.byLabel(RegExp('Penicilina')), findsNothing);
        expect(find.semantics.byLabel(RegExp('Ver consultas')), findsNothing);
        expect(find.semantics.byLabel(RegExp('Sesión bloqueada')), findsOne);
        expect(find.semantics.byLabel(RegExp('Cambiar de usuario')), findsOne);
        semantics.dispose();
      },
    );

    testWidgets('con el bloqueo, un toque no llega al botón de debajo', (
      tester,
    ) async {
      await pumpLocked(tester);
      final Finder button = find.widgetWithText(
        ElevatedButton,
        'Ver consultas',
      );

      final hit = tester.hitTestOnBinding(tester.getCenter(button));
      final RenderObject buttonBox = tester.renderObject(button);
      expect(hit.path.any((entry) => entry.target == buttonBox), isFalse);

      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Consultas abiertas: 0'), findsOneWidget);
    });

    testWidgets(
      'al bloquear, el foco sale de la pantalla de debajo y no puede volver',
      (tester) async {
        await tester.pumpWidget(_LockedApp(auth: auth));
        final FocusNode note = tester
            .state<_PatientScreenState>(find.byType(_PatientScreen))
            .noteFocus;
        await tester.tap(find.byKey(_PatientScreen.noteKey));
        await tester.pump();
        expect(note.hasFocus, isTrue);

        auth.setLocalLocked(true);
        await tester.pump();
        expect(note.hasFocus, isFalse);

        note.requestFocus();
        await tester.pump();
        expect(note.hasFocus, isFalse);
      },
    );

    testWidgets(
      'el campo de contraseña del bloqueo recibe el toque, escribe y pega',
      (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async => switch (call.method) {
            'Clipboard.hasStrings' => <String, Object?>{'value': true},
            'Clipboard.getData' => <String, Object?>{'text': 'clave-pegada'},
            _ => null,
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await pumpLocked(tester);

        await tester.tap(passwordField());
        await tester.pump();
        expect(tester.takeException(), isNull);
        final EditableText editable = tester.widget<EditableText>(
          find.descendant(
            of: passwordField(),
            matching: find.byType(EditableText),
          ),
        );
        expect(editable.focusNode.hasFocus, isTrue);

        await tester.enterText(passwordField(), 'abc');
        expect(editable.controller.text, 'abc');

        editable.controller.clear();
        await tester.longPress(passwordField());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Paste'));
        await tester.pump();
        expect(editable.controller.text, 'clave-pegada');
      },
    );

    testWidgets(
      '«Cambiar de usuario» abre el login con el Navigator de la app antes del logout',
      (tester) async {
        final Completer<void> network = Completer<void>();
        auth.logoutGate = network;
        await pumpLocked(tester);

        await tester.tap(find.text('Cambiar de usuario'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // El logout sigue en la red: el bloqueo cubre todavía, y debajo ya
        // está el login, no la paciente.
        expect(tester.takeException(), isNull);
        expect(auth.logouts, 1);
        expect(find.byType(LockScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(_PatientScreen), findsNothing);

        network.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(LockScreen), findsNothing);
        expect(find.byType(_PatientScreen), findsNothing);
        expect(
          tester
              .widget<LoginScreen>(find.byType(LoginScreen))
              .showSessionExpired,
          isFalse,
        );
      },
    );

    testWidgets(
      'si el logout termina enseguida, ningún cuadro muestra la paciente sin el bloqueo',
      (tester) async {
        await pumpLocked(tester);

        await tester.tap(find.text('Cambiar de usuario'));
        await tester.pump();

        expect(auth.logouts, 1);
        expect(find.byType(LockScreen), findsNothing);
        expect(find.byType(_PatientScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'cinco contraseñas erradas llevan al login con aviso de sesión expirada',
      (tester) async {
        await pumpLocked(tester);

        for (var i = 0; i < 5; i++) {
          await tester.enterText(passwordField(), 'errada-$i');
          await tester.tap(find.text('Desbloquear'));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(auth.logouts, 1);
        expect(find.byType(LockScreen), findsNothing);
        expect(find.byType(_PatientScreen), findsNothing);
        expect(
          tester
              .widget<LoginScreen>(find.byType(LoginScreen))
              .showSessionExpired,
          isTrue,
        );
        expect(
          find.text('Sesión expirada. Inicie sesión nuevamente.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'con el bloqueo, el retroceso del sistema no saca la pantalla tapada',
      (tester) async {
        await tester.pumpWidget(_LockedApp(auth: auth));
        final NavigatorState navigator = tester.state<NavigatorState>(
          find.byType(Navigator),
        );
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Consulta en curso')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Consulta en curso'), findsOneWidget);

        auth.setLocalLocked(true);
        await tester.pump();
        final bool handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(handled, isTrue);
        expect(find.text('Consulta en curso'), findsOneWidget);
        expect(find.byType(LockScreen), findsOneWidget);

        await tester.enterText(passwordField(), _LockAuth.password);
        await tester.tap(find.text('Desbloquear'));
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Consulta en curso'), findsNothing);
        expect(find.text('Alergias: Penicilina'), findsOneWidget);
      },
    );

    testWidgets('al desbloquear, la pantalla de debajo vuelve con su estado', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(_LockedApp(auth: auth));
      await tester.tap(find.text('Ver consultas'));
      await tester.enterText(find.byKey(_PatientScreen.noteKey), 'nota');
      await tester.pump();
      final State<_PatientScreen> before = tester.state(
        find.byType(_PatientScreen),
      );

      auth.setLocalLocked(true);
      await tester.pump();
      await tester.enterText(passwordField(), _LockAuth.password);
      await tester.tap(find.text('Desbloquear'));
      await tester.pump();

      expect(find.byType(LockScreen), findsNothing);
      expect(tester.state(find.byType(_PatientScreen)), same(before));
      expect(find.text('Consultas abiertas: 1'), findsOneWidget);
      expect(find.text('nota'), findsOneWidget);
      expect(find.semantics.byLabel(RegExp('Penicilina')), findsOne);

      await tester.tap(find.text('Ver consultas'));
      await tester.pump();
      expect(find.text('Consultas abiertas: 2'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('LockController — ciclo de vida de la aplicación', () {
    test('ignora cambios de ciclo de vida cuando no hay usuario activo', () {
      localLockedNotifier.value = false;
      when(() => authRepo.currentUser).thenReturn(null);
      final controller = LockController(
        authRepository: authRepo,
        backgroundTimeout: const Duration(minutes: 5),
      );
      addTearDown(controller.dispose);

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(localLockedNotifier.value, isFalse);
    });

    test(
      'bloquea al reanudar si el tiempo en segundo plano supera backgroundTimeout',
      () {
        localLockedNotifier.value = false;
        final controller = LockController(
          authRepository: authRepo,
          foregroundTimeout: const Duration(minutes: 10),
          backgroundTimeout: Duration.zero,
        );
        addTearDown(controller.dispose);

        controller.recordUserActivity();
        controller.didChangeAppLifecycleState(AppLifecycleState.paused);
        controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(localLockedNotifier.value, isTrue);
      },
    );

    test(
      'reinicia el timer de inactividad al reanudar antes de backgroundTimeout',
      () {
        fakeAsync((async) {
          localLockedNotifier.value = false;
          final controller = LockController(
            authRepository: authRepo,
            foregroundTimeout: const Duration(minutes: 10),
            backgroundTimeout: const Duration(minutes: 5),
          );

          controller.recordUserActivity();
          controller.didChangeAppLifecycleState(AppLifecycleState.inactive);

          async.elapse(const Duration(minutes: 2));
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          expect(localLockedNotifier.value, isFalse);

          async.elapse(const Duration(minutes: 9));
          expect(localLockedNotifier.value, isFalse);

          async.elapse(const Duration(minutes: 1));
          expect(localLockedNotifier.value, isTrue);

          controller.dispose();
        });
      },
    );
  });

  group('LockScreen — visibilidad y envío por teclado', () {
    late _LockAuth auth;

    setUp(() => auth = _LockAuth());

    Finder passwordField() => find.descendant(
      of: find.byType(LockScreen),
      matching: find.byType(TextField),
    );

    testWidgets(
      'alterna la visibilidad de la contraseña al tocar el ícono del ojo',
      (tester) async {
        await tester.pumpWidget(_LockedApp(auth: auth));
        auth.setLocalLocked(true);
        await tester.pump();

        expect(tester.widget<TextField>(passwordField()).obscureText, isTrue);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        expect(tester.widget<TextField>(passwordField()).obscureText, isFalse);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        expect(tester.widget<TextField>(passwordField()).obscureText, isTrue);
      },
    );

    testWidgets('desbloquea al enviar el formulario desde el teclado (done)', (
      tester,
    ) async {
      await tester.pumpWidget(_LockedApp(auth: auth));
      auth.setLocalLocked(true);
      await tester.pump();

      await tester.enterText(passwordField(), _LockAuth.password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('Alergias: Penicilina'), findsOneWidget);
    });
  });
}

/// AuthRepository de mentira con lo que el bloqueo usa. El logout imita al
/// real: primero la red ([logoutGate]) y después levanta el bloqueo y borra
/// la sesión.
class _LockAuth extends Fake implements AuthRepository {
  static const String password = 'clave-correcta';

  final ValueNotifier<bool> _locked = ValueNotifier<bool>(false);
  final ValueNotifier<UserSession?> _session = ValueNotifier<UserSession?>(
    UserSession(
      id: '1',
      email: 'nurse@hwb.org',
      fullName: 'Enfermera Ana',
      role: UserRole.nurse,
      organizationId: 'org-1',
    ),
  );
  final ValueNotifier<String?> _inactiveCode = ValueNotifier<String?>(null);

  Completer<void>? logoutGate;
  int logouts = 0;

  @override
  UserSession? get currentUser => _session.value;

  @override
  ValueNotifier<UserSession?> get sessionNotifier => _session;

  @override
  ValueListenable<bool> get isLocalLocked => _locked;

  @override
  void setLocalLocked(bool locked) => _locked.value = locked;

  @override
  ValueListenable<String?> get accountInactiveCode => _inactiveCode;

  @override
  Future<bool> verifyLocalLockPassword(String rawPassword) async {
    final bool ok = rawPassword == password;
    if (ok) _locked.value = false;
    return ok;
  }

  @override
  Future<void> logout({bool wipeLocalData = false}) async {
    logouts++;
    await logoutGate?.future;
    _locked.value = false;
    _session.value = null;
  }
}

/// La app con el mismo `builder` que lib/src/app.dart (sin la franja de la
/// ventana de sesión, que con la sesión vigente no pinta nada) y, debajo, una
/// pantalla con datos de una paciente.
class _LockedApp extends StatefulWidget {
  const _LockedApp({required this.auth});

  final _LockAuth auth;

  @override
  State<_LockedApp> createState() => _LockedAppState();
}

class _LockedAppState extends State<_LockedApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Como lib/src/app.dart: este observador se registra antes que el del
  // Navigator y se traga el retroceso del sistema mientras dure el bloqueo.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<bool> didPopRoute() async => _controller.blocksSystemBack;
  final ApiClient _apiClient = ApiClient(baseUrl: 'http://localhost');
  late final LockController _controller = LockController(
    authRepository: widget.auth,
  );
  late final PatientRepository _patientRepository = PatientRepository(
    apiClient: _apiClient,
    authRepository: widget.auth,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: 'es',
      setLocale: (_) {},
      child: AppScope(
        authRepository: widget.auth,
        userRepository: UserRepository(
          apiClient: _apiClient,
          authRepository: widget.auth,
        ),
        patientRepository: _patientRepository,
        statsRepository: StatsRepository(
          apiClient: _apiClient,
          authRepository: widget.auth,
        ),
        localDatabase: LocalDatabase.instance,
        syncEngine: SyncEngine(
          patientRepository: _patientRepository,
          localDatabase: LocalDatabase.instance,
        ),
        reachability: Reachability(baseUrl: 'http://localhost'),
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          builder: (BuildContext context, Widget? child) => LockLayer(
            controller: _controller,
            authRepository: widget.auth,
            navigatorKey: _navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const _PatientScreen(),
        ),
      ),
    );
  }
}

class _PatientScreen extends StatefulWidget {
  const _PatientScreen();

  static const Key noteKey = Key('nota-clinica');

  @override
  State<_PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<_PatientScreen> {
  final TextEditingController note = TextEditingController();
  final FocusNode noteFocus = FocusNode();
  int opened = 0;

  @override
  void dispose() {
    note.dispose();
    noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Alergias: Penicilina'),
          ElevatedButton(
            onPressed: () => setState(() => opened++),
            child: const Text('Ver consultas'),
          ),
          Text('Consultas abiertas: $opened'),
          TextField(
            key: _PatientScreen.noteKey,
            controller: note,
            focusNode: noteFocus,
          ),
        ],
      ),
    );
  }
}
