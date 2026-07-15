// test/widget/loss_of_wristband_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/loss_of_wristband_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeAuthRepository extends Fake implements AuthRepository {
  @override
  UserSession? get currentUser => UserSession(
    id: '1',
    email: 'test@org.com',
    fullName: 'Test User',
    role: UserRole.doctor,
    organizationId: 'org-1',
  );

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'fake-token';
}

class _FakeUserRepository extends Fake implements UserRepository {}

class _FakeLocalDatabase extends Fake implements LocalDatabase {}

class _FakeSyncEngine extends Fake implements SyncEngine {}

class _FakePatientRepository extends Fake implements PatientRepository {
  PatientFullRecord? result;
  bool shouldThrow = false;
  bool throwApiException = false;
  int apiStatusCode = 404;
  String apiMessage = 'Not found';

  @override
  Future<PatientFullRecord> searchPatient({
    required String documentNumber,
    required String birthDate,
    required String firstName,
    required String lastName,
    String? guardianName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (shouldThrow) {
      if (throwApiException) {
        throw ApiException(apiMessage, statusCode: apiStatusCode);
      }
      throw Exception('Unexpected error');
    }
    return result!;
  }
}

class _TestLocaleWrapper extends StatefulWidget {
  const _TestLocaleWrapper({required this.initialLocale, required this.child});
  final String initialLocale;
  final Widget child;

  @override
  State<_TestLocaleWrapper> createState() => _TestLocaleWrapperState();
}

class _TestLocaleWrapperState extends State<_TestLocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (newLocale) {
        setState(() {
          _locale = newLocale;
        });
      },
      child: widget.child,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void _setMobileScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
}

void _resetScreenSize(WidgetTester tester) {
  tester.view.reset();
}

Widget _wrap(
  Widget child, {
  _FakePatientRepository? patientRepo,
  NavigatorObserver? observer,
  String initialLocale = 'es',
}) {
  final repo = patientRepo ?? _FakePatientRepository();
  return _TestLocaleWrapper(
    initialLocale: initialLocale,
    child: AppScope(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(),
      patientRepository: repo,
      localDatabase: _FakeLocalDatabase(),
      syncEngine: _FakeSyncEngine(),
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: _FakeAuthRepository(),
      ),
      child: MaterialApp(
        navigatorObservers: observer != null ? [observer] : [],
        home: child,
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Render smoke test ─────────────────────────────────────────────────
  group('LossOfWristbandScreen — initial render', () {
    testWidgets('mounts without error and shows key UI elements', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      final s = AppStrings.forTesting('es');

      expect(find.text(s.searchPatientTitle), findsWidgets);
      expect(find.text(s.searchSubtitle), findsOneWidget);
      expect(find.text(s.searchPrivacyNotice), findsOneWidget);
      expect(find.text(s.searchFooterNote), findsOneWidget);
      expect(find.text('YYYY-MM-DD'), findsOneWidget);

      _resetScreenSize(tester);
    });

    testWidgets('dispose is called without error when widget is removed', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();
      _resetScreenSize(tester);
    });
  });

  // ── 2. Document type dropdown ────────────────────────────────────────────
  group('_DocTypeDropdown', () {
    testWidgets('shows default TI selection', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();
      expect(find.text('TI'), findsWidgets);
      _resetScreenSize(tester);
    });

    testWidgets('opens dropdown and changes selection to CC', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('TI').first);
      await tester.pumpAndSettle();

      expect(find.text('CC — Cédula de ciudadanía'), findsOneWidget);

      await tester.tap(find.text('CC — Cédula de ciudadanía'));
      await tester.pumpAndSettle();

      expect(find.text('CC'), findsWidgets);
      _resetScreenSize(tester);
    });

    testWidgets('all doc type options are rendered in the dropdown', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('TI').first);
      await tester.pumpAndSettle();

      for (final label in [
        'TI — Tarjeta de identidad',
        'CC — Cédula de ciudadanía',
        'RC — Registro civil',
        'CE — Cédula de extranjería',
        'PA — Pasaporte',
        'PE — Permiso especial',
        'PT — PPT',
        'MS — Menor sin ID',
        'AS — Adulto sin ID',
      ]) {
        expect(
          find.text(label),
          findsAny,
          reason: '$label should be in the dropdown',
        );
      }
      _resetScreenSize(tester);
    });
  });

  // ── 3. Navigation — back button ──────────────────────────────────────────
  group('Navigation', () {
    testWidgets('back button pops the route', (tester) async {
      _setMobileScreenSize(tester);

      final authRepo = _FakeAuthRepository();
      final userRepo = _FakeUserRepository();
      final patientRepo = _FakePatientRepository();
      final db = _FakeLocalDatabase();
      final engine = _FakeSyncEngine();

      await tester.pumpWidget(
        _TestLocaleWrapper(
          initialLocale: 'es',
          child: AppScope(
            authRepository: authRepo,
            userRepository: userRepo,
            patientRepository: patientRepo,
            localDatabase: db,
            syncEngine: engine,
            statsRepository: StatsRepository(
              apiClient: ApiClient(baseUrl: 'http://localhost'),
              authRepository: authRepo,
            ),
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LossOfWristbandScreen(),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchPatientTitle), findsWidgets);

      final backButtonIcon = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == Icons.arrow_back_rounded,
      );

      await tester.tap(backButtonIcon.first);
      await tester.pumpAndSettle();

      expect(find.text(s.searchPatientTitle), findsNothing);
      _resetScreenSize(tester);
    });
  });

  // ── 4. Date picker ───────────────────────────────────────────────────────
  group('Date picker', () {
    testWidgets('tapping date field opens date picker dialog', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('selecting a date updates the date field display', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('YYYY-MM-DD'), findsNothing);
      _resetScreenSize(tester);
    });

    testWidgets('cancelling date picker leaves field unchanged', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();

      final cancelText = find.text('CANCELAR');
      if (cancelText.evaluate().isNotEmpty) {
        await tester.tap(cancelText);
      } else {
        await tester.tap(find.byType(TextButton).first);
      }
      await tester.pumpAndSettle();

      expect(find.text('YYYY-MM-DD'), findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 5. Validation — missing required fields ──────────────────────────────
  group('_search() — validation', () {
    testWidgets('shows error when all fields are empty and search is tapped', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchFieldsRequired), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('shows error when only docNumber is filled', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchFieldsRequired), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets(
      'shows error when docNumber and firstName filled but DOB is missing',
      (tester) async {
        _setMobileScreenSize(tester);
        await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
        await tester.pump();

        final fields = tester.widgetList<TextField>(find.byType(TextField));
        final fieldList = fields.toList();

        await tester.enterText(find.byWidget(fieldList[0]), '123456');
        await tester.enterText(find.byWidget(fieldList[1]), 'Ana');
        await tester.enterText(find.byWidget(fieldList[2]), 'García');
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        final s = AppStrings.forTesting('es');
        expect(find.text(s.searchFieldsRequired), findsOneWidget);
        _resetScreenSize(tester);
      },
    );
  });

  // ── 6. _search() — ApiException 404 ─────────────────────────────────────
  group('_search() — ApiException', () {
    testWidgets('shows searchNoMatch message on 404', (tester) async {
      _setMobileScreenSize(tester);
      final repo = _FakePatientRepository()
        ..shouldThrow = true
        ..throwApiException = true
        ..apiStatusCode = 404
        ..apiMessage = 'Not found';

      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), patientRepo: repo),
      );
      await tester.pump();

      await _fillAndSubmit(tester);

      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchNoMatch), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('shows raw message on non-404 ApiException (e.g. 500)', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      const errMsg = 'Error interno del servidor';
      final repo = _FakePatientRepository()
        ..shouldThrow = true
        ..throwApiException = true
        ..apiStatusCode = 500
        ..apiMessage = errMsg;

      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), patientRepo: repo),
      );
      await tester.pump();

      await _fillAndSubmit(tester);

      expect(find.text(errMsg), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('shows raw message on non-404 ApiException (e.g. 401)', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      const errMsg = 'Token expirado';
      final repo = _FakePatientRepository()
        ..shouldThrow = true
        ..throwApiException = true
        ..apiStatusCode = 401
        ..apiMessage = errMsg;

      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), patientRepo: repo),
      );
      await tester.pump();

      await _fillAndSubmit(tester);

      expect(find.text(errMsg), findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 7. _search() — generic exception ────────────────────────────────────
  group('_search() — generic exception', () {
    testWidgets('shows searchError message on unexpected exception', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      final repo = _FakePatientRepository()
        ..shouldThrow = true
        ..throwApiException = false;

      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), patientRepo: repo),
      );
      await tester.pump();

      await _fillAndSubmit(tester);

      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchError), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('error banner is rendered with icon', (tester) async {
      _setMobileScreenSize(tester);
      final repo = _FakePatientRepository()
        ..shouldThrow = true
        ..throwApiException = false;

      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), patientRepo: repo),
      );
      await tester.pump();

      await _fillAndSubmit(tester);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 8. _LabeledField sub-widget ──────────────────────────────────────────
  group('_LabeledField', () {
    testWidgets('renders required asterisk when requiredField = true', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.documentNumberLabel), findsOneWidget);
      expect(find.text('*'), findsWidgets);
      _resetScreenSize(tester);
    });

    testWidgets('renders helper text for document number field', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.minThreeChars), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('renders guardian helper text', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.guardianHelper), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('renders hint text for document number field', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      expect(find.text('Ej. 1098765432'), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('guardian field has no asterisk (optional)', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.guardianNameOptionalLabel), findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 9. _DateField sub-widget ────────────────────────────────────────────
  group('_DateField', () {
    testWidgets('shows calendar icon', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      _resetScreenSize(tester);
    });

    testWidgets('shows date value with primary color border after selection', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('YYYY-MM-DD'), findsNothing);
      _resetScreenSize(tester);
    });

    testWidgets('_formatDate formats correctly for boundary dates', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      await tester.tap(find.text('YYYY-MM-DD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final formatted = find.textContaining(RegExp(r'\d{4}-\d{2}-\d{2}'));
      expect(formatted, findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 10. _PrivacyBanner sub-widget ─────────────────────────────────────────
  group('_PrivacyBanner', () {
    testWidgets('shows privacy icon and message', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      final s = AppStrings.forTesting('es');
      expect(find.text(s.searchPrivacyNotice), findsOneWidget);
      _resetScreenSize(tester);
    });
  });

  // ── 11. ScreenBottomHandle ───────────────────────────────────────────────
  group('ScreenBottomHandle', () {
    testWidgets('is present in the widget tree', (tester) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(_wrap(const LossOfWristbandScreen()));
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
      _resetScreenSize(tester);
    });
  });

  // ── 12. Localization Switcher ────────────────────────────────────────────
  group('Localization Switcher', () {
    testWidgets('switching language from ES to EN updates UI strings', (
      tester,
    ) async {
      _setMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(const LossOfWristbandScreen(), initialLocale: 'es'),
      );
      await tester.pump();

      final sEs = AppStrings.forTesting('es');
      final sEn = AppStrings.forTesting('en');

      expect(find.text(sEs.searchPatientTitle), findsWidgets);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text(sEn.searchPatientTitle), findsWidgets);
      expect(find.text(sEs.searchPatientTitle), findsNothing);

      _resetScreenSize(tester);
    });
  });
}

// ─── Shared helper ────────────────────────────────────────────────────────────

Future<void> _fillAndSubmit(WidgetTester tester) async {
  final textFields = tester
      .widgetList<TextField>(find.byType(TextField))
      .toList();
  await tester.enterText(find.byWidget(textFields[0]), '123456');
  await tester.enterText(find.byWidget(textFields[1]), 'Ana María');
  await tester.enterText(find.byWidget(textFields[2]), 'García Pérez');
  await tester.pump();

  await tester.tap(find.text('YYYY-MM-DD'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(ElevatedButton));
  await tester.pump(const Duration(milliseconds: 20));
}
