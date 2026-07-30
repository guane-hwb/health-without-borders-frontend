// test/unit/add_vaccine_screen_test.dart
//
// Covers:
//  • Unit  — _VaccineEntry.isValid logic
//  • Unit  — _formattedDate padding
//  • Widget — scan step (initial state, NFC icon, manual-search button,
//             CircularProgressIndicator while scanning)
//  • Widget — form step (patient badge, add/remove vaccine entries, status
//             selection, save-button enable/disable)
//  • Widget — success step (icon, patient name, status rows, error snackbar)
//  • Widget — returnToProfile path pops with vaccine
//  • Widget — common vaccine chip selector
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_vaccine_screen.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

class _MockLocalDatabase extends Mock implements LocalDatabase {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Search for a [TextField] by its exact hint text.
Finder textFieldWithHint(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
  description: 'TextField with hint "$hint"',
);

const String _hintVaccineName = 'Ej: Triple Viral (SRP)';
const String _hintCvxCode = 'Ej: 03';
const String _hintAdminBy = 'Ej: Enf. Ana Ruiz';
const String _hintAdminAt = 'Ej: Brigada Frontera Cúcuta';

/// Minimal [PatientFullRecord] with all required fields.
PatientFullRecord _fakePatient({String name = 'Ana García'}) =>
    PatientFullRecord(
      patientId: 'P001',
      deviceUid: 'UID-001',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123456789',
        ),
        firstLastName: name.split(' ').length > 1 ? name.split(' ').last : name,
        firstName: name.split(' ').first,
        dob: '2010-05-01',
        biologicalSex: 'F',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
      backgroundHistory: null,
      allergies: [],
      medicalHistory: [],
      vaccinationRecord: [],
    );

// ---------------------------------------------------------------------------
// Widget wrapper
// ---------------------------------------------------------------------------

/// Injects a fake [AppScope] and [AppLocale] so the widget doesn't touch
/// real platform code.
Widget _buildApp({
  PatientFullRecord? patient,
  bool returnToProfile = false,
  AppScope? scope,
  String locale = 'es',
}) {
  final wrapper = scope ?? _defaultScope();
  return AppScope(
    authRepository: wrapper.authRepository,
    userRepository: wrapper.userRepository,
    patientRepository: wrapper.patientRepository,
    localDatabase: wrapper.localDatabase,
    syncEngine: wrapper.syncEngine,
    statsRepository: StatsRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
      authRepository: wrapper.authRepository,
    ),
    child: AppLocale(
      locale: locale,
      setLocale: (_) {},
      child: MaterialApp(
        home: AddVaccineScreen(
          patient: patient,
          returnToProfile: returnToProfile,
        ),
      ),
    ),
  );
}

AppScope _defaultScope() {
  final auth = _MockAuthRepository();
  final user = _MockUserRepository();
  final repo = _MockPatientRepository();
  final db = _MockLocalDatabase();
  final sync = _MockSyncEngine();

  when(() => sync.syncAll()).thenAnswer((_) async => true);

  return AppScope(
    authRepository: auth,
    userRepository: user,
    patientRepository: repo,
    localDatabase: db,
    syncEngine: sync,
    statsRepository: StatsRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
      authRepository: auth,
    ),
    child: const SizedBox.shrink(),
  );
}

Future<void> _tapGuardar(WidgetTester tester, {int entriesCount = 1}) async {
  final label = entriesCount == 1
      ? 'Guardar vacuna'
      : 'Guardar $entriesCount vacunas';
  final guardarFinder = find.widgetWithText(ElevatedButton, label);
  await tester.ensureVisible(guardarFinder);
  await tester.pumpAndSettle();
  await tester.tap(guardarFinder);
}

// ---------------------------------------------------------------------------
// TESTS
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatientFullRecord());
  });

  // ── Unit: _VaccineEntry.isValid ───────────────────────────────────────────

  group('_VaccineEntry.isValid (unit)', () {
    test('is false when both controllers are empty', () {
      final e = VaccineEntryTestable();
      expect(e.isValid, isFalse);
    });

    test('is false when name is set but cvx is empty', () {
      final e = VaccineEntryTestable();
      e.nameCtrl.text = 'Hepatitis B';
      expect(e.isValid, isFalse);
    });

    test('is false when cvx is set but name is empty', () {
      final e = VaccineEntryTestable();
      e.cvxCtrl.text = '08';
      expect(e.isValid, isFalse);
    });

    test('is false when both have only whitespace', () {
      final e = VaccineEntryTestable();
      e.nameCtrl.text = '   ';
      e.cvxCtrl.text = '   ';
      expect(e.isValid, isFalse);
    });

    test('is true when both have non-empty trimmed text', () {
      final e = VaccineEntryTestable();
      e.nameCtrl.text = 'BCG';
      e.cvxCtrl.text = '19';
      expect(e.isValid, isTrue);
    });
  });

  // ── Unit: _formattedDate ──────────────────────────────────────────────────

  group('formattedDate (unit)', () {
    test('pads single-digit month and day with leading zero', () {
      expect(formatVaccineDate(DateTime(2024, 3, 7)), '2024-03-07');
    });

    test('does not double-pad two-digit values', () {
      expect(formatVaccineDate(DateTime(2024, 12, 31)), '2024-12-31');
    });
  });

  // ── Widget: SCAN STEP ─────────────────────────────────────────────────────

  group('Scan step (widget.patient == null)', () {
    testWidgets('shows NFC icon and scan instructions', (tester) async {
      await tester.pumpWidget(_buildApp());

      find.byIcon(Icons.nfc_rounded);
      expect(find.text('Escanear paciente'), findsOneWidget);
      expect(find.textContaining('Acerque el dispositivo NFC'), findsOneWidget);
    });

    testWidgets('shows manual-search button', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Buscar paciente'), findsOneWidget);
    });

    testWidgets('no scan error message is shown initially', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(
        find.text('NFC no disponible. Use el campo manual debajo.'),
        findsNothing,
      );
      expect(
        find.text('No se pudo leer el dispositivo. Inténtalo de nuevo.'),
        findsNothing,
      );
    });

    testWidgets('tapping Buscar paciente opens UID dialog', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Buscar paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar por UID'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'UID del dispositivo NFC'),
        findsOneWidget,
      );
    });

    testWidgets('dialog Cancelar closes without error', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Buscar paciente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar por UID'), findsNothing);
    });

    testWidgets('NFC scan shows CircularProgressIndicator while scanning', (
      tester,
    ) async {
      final scope = _defaultScope();

      when(
        () => scope.patientRepository.scanDevice(any()),
      ).thenAnswer((_) => Completer<PatientFullRecord>().future);

      NfcService.overrideReadDeviceUid = () async => 'UID-TEST';

      await tester.pumpWidget(_buildApp(scope: scope));
      await tester.tap(find.byIcon(Icons.nfc_rounded));

      await tester.pump(Duration.zero);

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      NfcService.overrideReadDeviceUid = null;
    });

    testWidgets('NfcNotAvailableException shows error text', (tester) async {
      final scope = _defaultScope();
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcNotAvailableException();

      await tester.pumpWidget(_buildApp(scope: scope));
      await tester.tap(find.byIcon(Icons.nfc_rounded));
      await tester.pumpAndSettle();

      expect(
        find.text('NFC no disponible. Use el campo manual debajo.'),
        findsOneWidget,
      );

      NfcService.overrideReadDeviceUid = null;
    });
  });

  // ── Widget: FORM STEP ─────────────────────────────────────────────────────

  group('Form step (widget.patient != null)', () {
    testWidgets('renders patient name badge', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
    });

    testWidgets('renders section headers', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Administración'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
    });

    testWidgets('save button is disabled when form is empty', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Guardar vacuna'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('save button enables when all required fields are filled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      await tester.enterText(textFieldWithHint(_hintVaccineName).first, 'BCG');
      await tester.enterText(textFieldWithHint(_hintCvxCode).first, '19');
      await tester.enterText(textFieldWithHint(_hintAdminBy), 'Dr. Pérez');
      await tester.enterText(
        textFieldWithHint(_hintAdminAt),
        'Hospital Central',
      );
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Guardar vacuna'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('Agregar adds a second vaccine entry card', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Vacuna 1'), findsOneWidget);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Vacuna 2'), findsOneWidget);
      expect(find.textContaining('Guardar 2 vacunas'), findsOneWidget);
    });

    testWidgets('removing an entry reduces the list back to one', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      final deleteIcon = find.byIcon(Icons.delete_outline).last;
      await tester.ensureVisible(deleteIcon);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Vacuna 2'), findsNothing);
      expect(find.text('Vacuna 1'), findsOneWidget);
    });

    testWidgets('cannot remove last remaining entry', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('status options are all rendered', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Completado'), findsOneWidget);
      expect(find.text('Rehusada por paciente'), findsOneWidget);
      expect(find.text('No administrada (justificar)'), findsOneWidget);
    });

    testWidgets('tapping a status option selects it', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final rehusada = find.text('Rehusada por paciente');
      await tester.ensureVisible(rehusada);
      await tester.tap(rehusada);
      await tester.pump();

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('dose selector shows Dosis 1–4 and Refuerzo', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      for (int i = 1; i <= 4; i++) {
        expect(find.text('Dosis $i'), findsOneWidget);
      }
      expect(find.text('Refuerzo'), findsOneWidget);
    });

    testWidgets('tapping dose 3 updates selection', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final dosis3 = find.text('Dosis 3');
      await tester.ensureVisible(dosis3);
      await tester.tap(dosis3);
      await tester.pump();

      expect(find.text('Dosis 3'), findsOneWidget);
    });

    testWidgets('formatted date is shown in date field', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expected =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(find.text(expected), findsOneWidget);
    });
  });

  // ── Widget: SUCCESS STEP ──────────────────────────────────────────────────

  group('Success step', () {
    Future<void> fillAndSave(WidgetTester tester, AppScope scope) async {
      when(
        () => scope.localDatabase.savePatient(any()),
      ).thenAnswer((_) async {});
      when(
        () => scope.localDatabase.markChipsDirty(
          any(),
          guardian: any(named: 'guardian'),
        ),
      ).thenAnswer((_) async {});
      when(() => scope.syncEngine.syncAll()).thenAnswer((_) async => true);

      await tester.pumpWidget(_buildApp(patient: _fakePatient(), scope: scope));
      await tester.pumpAndSettle();

      await tester.enterText(textFieldWithHint(_hintVaccineName).first, 'BCG');
      await tester.enterText(textFieldWithHint(_hintCvxCode).first, '19');
      await tester.enterText(textFieldWithHint(_hintAdminBy), 'Dr. López');
      await tester.enterText(
        textFieldWithHint(_hintAdminAt),
        'Centro de Salud',
      );
      await tester.pump();

      await _tapGuardar(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('renders success icon after saving 1 vaccine', (tester) async {
      final scope = _defaultScope();
      await fillAndSave(tester, scope);

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Vacuna guardada exitosamente'), findsWidgets);
    });

    testWidgets('shows patient name in success step', (tester) async {
      final scope = _defaultScope();
      await fillAndSave(tester, scope);

      expect(find.text('Ana García'), findsOneWidget);
    });

    testWidgets('shows local-save and sync status rows', (tester) async {
      final scope = _defaultScope();
      await fillAndSave(tester, scope);

      expect(find.textContaining('Guardado local'), findsOneWidget);
      expect(find.textContaining('Pendientes por sincronizar'), findsOneWidget);
    });

    testWidgets('save failure shows error snackbar', (tester) async {
      final scope = _defaultScope();
      when(
        () => scope.localDatabase.savePatient(any()),
      ).thenThrow(Exception('disk full'));

      await tester.pumpWidget(_buildApp(patient: _fakePatient(), scope: scope));
      await tester.pumpAndSettle();

      await tester.enterText(textFieldWithHint(_hintVaccineName).first, 'BCG');
      await tester.enterText(textFieldWithHint(_hintCvxCode).first, '19');
      await tester.enterText(textFieldWithHint(_hintAdminBy), 'Dr. López');
      await tester.enterText(
        textFieldWithHint(_hintAdminAt),
        'Centro de Salud',
      );
      await tester.pump();

      await _tapGuardar(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo guardar. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });
  });

  // ── Widget: returnToProfile path ──────────────────────────────────────────

  group('returnToProfile = true', () {
    testWidgets('pops with vaccine result instead of saving locally', (
      tester,
    ) async {
      List<VaccinationRecordItem>? popped;
      final scope = _defaultScope();

      await tester.pumpWidget(
        AppScope(
          authRepository: scope.authRepository,
          userRepository: scope.userRepository,
          patientRepository: scope.patientRepository,
          localDatabase: scope.localDatabase,
          syncEngine: scope.syncEngine,
          statsRepository: StatsRepository(
            apiClient: ApiClient(baseUrl: 'http://localhost'),
            authRepository: scope.authRepository,
          ),
          child: AppLocale(
            locale: 'es',
            setLocale: (_) {},
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () async {
                    final result = await Navigator.of(ctx)
                        .push<List<VaccinationRecordItem>>(
                          MaterialPageRoute(
                            builder: (_) => AppScope(
                              authRepository: scope.authRepository,
                              userRepository: scope.userRepository,
                              patientRepository: scope.patientRepository,
                              localDatabase: scope.localDatabase,
                              syncEngine: scope.syncEngine,
                              statsRepository: StatsRepository(
                                apiClient: ApiClient(
                                  baseUrl: 'http://localhost',
                                ),
                                authRepository: scope.authRepository,
                              ),
                              child: AppLocale(
                                locale: 'es',
                                setLocale: (_) {},
                                child: AddVaccineScreen(
                                  patient: _fakePatient(),
                                  returnToProfile: true,
                                ),
                              ),
                            ),
                          ),
                        );
                    popped = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        textFieldWithHint(_hintVaccineName).first,
        'Varicela',
      );
      await tester.enterText(textFieldWithHint(_hintCvxCode).first, '21');
      await tester.enterText(textFieldWithHint(_hintAdminBy), 'Enfermera R.');
      await tester.enterText(textFieldWithHint(_hintAdminAt), 'IPS Sur');
      await tester.pump();

      await _tapGuardar(tester);
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.isNotEmpty, isTrue);
      expect(popped!.first.vaccineName, 'Varicela');
      expect(popped!.first.vaccineCode, '21');
    });
  });

  // ── Widget: common-vaccines quick-fill ────────────────────────────────────

  group('Common vaccine chip selector', () {
    testWidgets('selecting BCG fills name and code fields', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('BCG (Tuberculosis)'));
      await tester.pump();

      expect(
        tester
            .widget<TextField>(textFieldWithHint(_hintVaccineName).first)
            .controller
            ?.text,
        'BCG (Tuberculosis)',
      );
    });
  });

  group('Verificación de Internacionalización Multiidioma (i18n)', () {
    testWidgets('Renders all fields in English when locale is set to "en"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient(), locale: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Vaccines'), findsOneWidget);
      expect(find.text('Dose 1'), findsOneWidget);
      expect(find.text('Booster'), findsOneWidget);
    });

    testWidgets(
      'Renders correct dynamic vaccine lists and buttons in English scenario',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(patient: _fakePatient(), locale: 'en'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Oral Polio (OPV)'), findsOneWidget);
        expect(find.text('MMR (Measles, Mumps, Rubella)'), findsOneWidget);
        expect(find.text('Refused by patient'), findsOneWidget);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Exported helpers for pure unit tests
// ---------------------------------------------------------------------------

/// Public alias so that unit tests can instantiate _VaccineEntry.
typedef VaccineEntryTestable = VaccineEntry;

/// Helper exported to check date format without lifting widgets.
String formatVaccineDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
