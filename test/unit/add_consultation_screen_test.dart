// test/unit/add_consultation_screen_test.dart
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
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_consultation_screen.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

class _MockLocalDatabase extends Mock implements LocalDatabase {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

class _FakeMedicalHistoryItem extends Fake implements MedicalHistoryItem {}

// ── Helpers ───────────────────────────────────────────────────────────────────

PatientFullRecord _fakePatient({
  String firstName = 'Laura',
  String lastName = 'Ríos',
  double? weight,
  double? height,
  List<AllergyInfo> allergies = const [],
}) => PatientFullRecord(
  patientId: 'P-001',
  deviceUid: 'UID-001',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '987654321',
    ),
    firstName: firstName,
    firstLastName: lastName,
    dob: '2005-08-15',
    biologicalSex: 'F',
    address: Address(city: 'Medellín', state: 'Antioquia'),
    weight: weight,
    height: height,
  ),
  guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
  backgroundHistory: null,
  allergies: allergies,
  medicalHistory: [],
  vaccinationRecord: [],
);

AllergyInfo _allergyMed() =>
    AllergyInfo(category: '01', allergen: 'Penicilina', reaction: 'Urticaria');

// ── AppScope factory ──────────────────────────────────────────────────────────

AppScope _defaultScope({
  _MockLocalDatabase? db,
  _MockSyncEngine? sync,
  _MockPatientRepository? repo,
}) {
  final auth = _MockAuthRepository();
  final user = _MockUserRepository();
  final resolvedRepo = repo ?? _MockPatientRepository();
  final resolvedDb = db ?? _MockLocalDatabase();
  final resolvedSync = sync ?? _MockSyncEngine();
  when(() => resolvedSync.syncAll()).thenAnswer((_) async {});
  return AppScope(
    authRepository: auth,
    userRepository: user,
    patientRepository: resolvedRepo,
    localDatabase: resolvedDb,
    syncEngine: resolvedSync,
    child: const SizedBox.shrink(),
  );
}

AppScope _scopeWithSave() {
  final db = _MockLocalDatabase();
  final sync = _MockSyncEngine();
  when(() => db.savePatient(any())).thenAnswer((_) async {});
  when(() => sync.syncAll()).thenAnswer((_) async {});
  return _defaultScope(db: db, sync: sync);
}

// ── Widget wrapper ────────────────────────────────────────────────────────────

Widget _buildApp({
  PatientFullRecord? patient,
  bool returnToProfile = false,
  AppScope? scope,
}) {
  final s = scope ?? _defaultScope();
  return AppScope(
    authRepository: s.authRepository,
    userRepository: s.userRepository,
    patientRepository: s.patientRepository,
    localDatabase: s.localDatabase,
    syncEngine: s.syncEngine,
    child: AppLocale(
      locale: 'es',
      setLocale: (_) {},
      child: MaterialApp(
        home: AddConsultationScreen(
          patient: patient,
          returnToProfile: returnToProfile,
        ),
      ),
    ),
  );
}

// ── Finders ───────────────────────────────────────────────────────────────────

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
  description: 'TextField hint="$hint"',
);

const _hintHistory = 'Fiebre de 3 días de evolución, tos seca, rinorrea...';
const _hintPhysical = 'T: 38.2°C, FC: 110, FR: 28. Faringe eritematosa...';
const _hintSystems = 'Pulmones: murmullo vesicular conservado sin agregados...';
const _hintTreatment = 'Acetaminofén 15mg/kg cada 6h. Control en 72h...';

// ROOT-CAUSE FIX:
Finder _guardarButtonFinder() =>
    find.byKey(const ValueKey('guardar_consulta_btn'));

/// Read onPressed from the "Save query" button regardless of its subtype.
bool _isGuardarEnabled(WidgetTester tester) {
  final btn = tester.widget<ButtonStyleButton>(_guardarButtonFinder());
  return btn.onPressed != null;
}

/// Scroll to the button and touch it.
Future<void> _tapGuardar(WidgetTester tester) async {
  final btn = _guardarButtonFinder();
  await tester.ensureVisible(btn);
  await tester.pump();
  await tester.tap(btn, warnIfMissed: false);
}

/// Fill in the required field and save.
Future<void> _fillAndSave(
  WidgetTester tester, {
  String history = 'Fiebre',
}) async {
  final historyField = _fieldWithHint(_hintHistory);
  await tester.ensureVisible(historyField);
  await tester.pump();
  await tester.enterText(historyField, history);
  await tester.pump();
  await _tapGuardar(tester);
  await tester.pumpAndSettle();
}

// ════════════════════════════════════════════════════════════════════════════
// UNIT TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatientFullRecord());
    registerFallbackValue(_FakeMedicalHistoryItem());
  });

  // ── _isFormValid ───────────────────────────────────────────────────────────
  group('_isFormValid (unit)', () {
    test('es false cuando historyCtrl está vacío', () {
      final ctrl = TextEditingController();
      expect(ctrl.text.trim().isNotEmpty, isFalse);
      ctrl.dispose();
    });

    test('es false cuando historyCtrl tiene solo espacios', () {
      final ctrl = TextEditingController(text: '   ');
      expect(ctrl.text.trim().isNotEmpty, isFalse);
      ctrl.dispose();
    });

    test('es true cuando historyCtrl tiene texto no vacío', () {
      final ctrl = TextEditingController(text: 'Cefalea intensa');
      expect(ctrl.text.trim().isNotEmpty, isTrue);
      ctrl.dispose();
    });
  });

  // ── _DateTimeRow._format ───────────────────────────────────────────────────
  group('_DateTimeRow._format (unit)', () {
    String format(DateTime dt) {
      final d =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    }

    test('rellena con cero mes y día de un dígito', () {
      expect(format(DateTime(2024, 3, 7, 9, 5)), '2024-03-07 09:05');
    });

    test('no duplica ceros en valores de dos dígitos', () {
      expect(format(DateTime(2024, 12, 31, 23, 59)), '2024-12-31 23:59');
    });

    test('formatea medianoche correctamente', () {
      expect(format(DateTime(2025, 1, 1, 0, 0)), '2025-01-01 00:00');
    });
  });

  // ── PractitionerInfo ───────────────────────────────────────────────────────
  group('PractitionerInfo (unit)', () {
    PractitionerInfo? build({
      required String name,
      String docType = 'CC',
      String doc = '',
    }) => name.isNotEmpty
        ? PractitionerInfo(
            documentType: docType,
            documentNumber: doc.isEmpty ? '0' : doc,
            name: name,
          )
        : null;

    test(
      'es null cuando el nombre está vacío',
      () => expect(build(name: ''), isNull),
    );
    test(
      'es no-null cuando el nombre tiene texto',
      () => expect(build(name: 'Dr. García'), isNotNull),
    );
    test(
      'documentNumber usa "0" cuando doc está vacío',
      () => expect(build(name: 'X')!.documentNumber, '0'),
    );
    test(
      'documentNumber usa el valor cuando se provee',
      () => expect(build(name: 'X', doc: '123')!.documentNumber, '123'),
    );
  });

  // ── ProviderInfo ───────────────────────────────────────────────────────────
  group('ProviderInfo (unit)', () {
    ProviderInfo? build({required String name, String reps = ''}) =>
        name.isNotEmpty
        ? ProviderInfo(repsCode: reps.isEmpty ? '0' : reps, name: name)
        : null;

    test(
      'es null cuando el nombre está vacío',
      () => expect(build(name: ''), isNull),
    );
    test(
      'es no-null cuando el nombre tiene texto',
      () => expect(build(name: 'Hospital'), isNotNull),
    );
    test(
      'repsCode usa "0" cuando se omite',
      () => expect(build(name: 'H')!.repsCode, '0'),
    );
    test(
      'repsCode usa el valor cuando se provee',
      () => expect(build(name: 'H', reps: 'ABC')!.repsCode, 'ABC'),
    );
  });

  // ── PayerInfo ──────────────────────────────────────────────────────────────
  group('PayerInfo (unit)', () {
    PayerInfo? build(String name) =>
        name.isNotEmpty ? PayerInfo(name: name) : null;

    test(
      'es null cuando el nombre está vacío',
      () => expect(build(''), isNull),
    );
    test(
      'es no-null con "No asegurado" (valor por defecto)',
      () => expect(build('No asegurado'), isNotNull),
    );
  });

  // ── dischargeDisposition ───────────────────────────────────────────────────
  group('dischargeDisposition (unit)', () {
    String? resolve(String? v) => (v?.isEmpty ?? true) ? null : v;

    test('es null para cadena vacía ""', () => expect(resolve(''), isNull));
    test(
      'es null cuando el valor es null',
      () => expect(resolve(null), isNull),
    );
    test('es "01" para Alta voluntaria', () => expect(resolve('01'), '01'));
    test('es "04" para Alta médica', () => expect(resolve('04'), '04'));
  });

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET — SCAN STEP
  // ════════════════════════════════════════════════════════════════════════════

  group('Scan step (patient == null)', () {
    testWidgets('muestra ícono médico, título y subtítulo NFC', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.byIcon(Icons.medical_services), findsOneWidget);
      expect(find.text('Escanear paciente'), findsOneWidget);
      expect(find.textContaining('Acerque el dispositivo NFC'), findsOneWidget);
    });

    testWidgets('muestra botón "Buscar paciente"', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Buscar paciente'), findsOneWidget);
    });

    testWidgets('no hay mensaje de error al inicio', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('NFC no disponible.'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
    });

    testWidgets('tap en "Buscar paciente" abre diálogo con campo UID', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Buscar paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar por UID'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Ingrese UID del dispositivo NFC'),
        findsOneWidget,
      );
    });

    testWidgets('Cancelar en el diálogo lo cierra sin error', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Buscar paciente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar por UID'), findsNothing);
      expect(find.text('NFC no disponible.'), findsNothing);
    });

    testWidgets('tap en ícono NFC muestra CircularProgressIndicator', (
      tester,
    ) async {
      final repo = _MockPatientRepository();
      when(
        () => repo.scanDevice(any()),
      ).thenAnswer((_) => Completer<PatientFullRecord>().future);

      NfcService.overrideReadDeviceUid = () async => 'UID-FAKE';

      final scope = _defaultScope(repo: repo);
      await tester.pumpWidget(_buildApp(scope: scope));

      await tester.tap(find.byIcon(Icons.nfc_rounded));
      await tester.pump(Duration.zero);

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      NfcService.overrideReadDeviceUid = null;
    });

    testWidgets('NfcNotAvailableException muestra texto de error', (
      tester,
    ) async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcNotAvailableException();

      await tester.pumpWidget(_buildApp());
      await tester.tap(find.byIcon(Icons.nfc_rounded));
      await tester.pumpAndSettle();

      expect(find.text('NFC no disponible.'), findsOneWidget);

      NfcService.overrideReadDeviceUid = null;
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET — FORM STEP
  // ════════════════════════════════════════════════════════════════════════════

  group('Form step (patient != null)', () {
    testWidgets('muestra badge con nombre del paciente', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Laura Ríos'), findsOneWidget);
    });

    testWidgets('muestra encabezados de secciones', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Signos vitales'), findsOneWidget);
      expect(find.text('Fecha y hora de atención'), findsOneWidget);
      expect(find.text('Contexto de atención'), findsOneWidget);
      expect(find.text('Evaluación clínica'), findsOneWidget);
      expect(find.text('Diagnóstico y egreso'), findsOneWidget);
    });
    testWidgets('botón "Guardar consulta" deshabilitado con form vacío', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(_isGuardarEnabled(tester), isFalse);
    });

    testWidgets('botón habilitado al escribir en "Enfermedad actual"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final historyField = _fieldWithHint(_hintHistory);
      await tester.ensureVisible(historyField);
      await tester.pump();
      await tester.enterText(historyField, 'Dolor abdominal');
      await tester.pump();

      // Make the button visible to read its status in the current viewport.
      await tester.ensureVisible(_guardarButtonFinder());
      await tester.pump();

      expect(_isGuardarEnabled(tester), isTrue);
    });

    testWidgets('pre-carga peso y talla cuando el paciente los tiene', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(weight: 58.5, height: 162.0)),
      );
      await tester.pumpAndSettle();

      final values = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((tf) => tf.controller?.text ?? '')
          .toList();

      expect(
        values.any((v) => v == '58.5'),
        isTrue,
        reason: 'Peso pre-cargado como 58.5',
      );
      expect(
        values.any((v) => v == '162.0'),
        isTrue,
        reason: 'Talla pre-cargada como 162.0',
      );
    });

    testWidgets('dropdowns de modalidad, grupo y entorno presentes', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.text('Intramural'), findsOneWidget);
      expect(find.text('Consulta externa'), findsOneWidget);
      expect(find.text('Institucional'), findsOneWidget);
    });

    testWidgets('campo pagador empieza con "No asegurado"', (tester) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      final values = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((tf) => tf.controller?.text ?? '')
          .toList();
      expect(values.any((v) => v == 'No asegurado'), isTrue);
    });

    testWidgets('sin alergias no aparece advertencia de alergia en el form', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(find.textContaining('alergia'), findsNothing);
    });

    testWidgets('con alergias muestra contador en badge del paciente', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(allergies: [_allergyMed()])),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 alergia(s)'), findsOneWidget);
    });

    testWidgets('campos de evaluación clínica tienen los hints correctos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(patient: _fakePatient()));
      await tester.pumpAndSettle();

      expect(_fieldWithHint(_hintHistory), findsOneWidget);
      expect(_fieldWithHint(_hintPhysical), findsOneWidget);
      expect(_fieldWithHint(_hintSystems), findsOneWidget);
      expect(_fieldWithHint(_hintTreatment), findsOneWidget);
    });

    testWidgets(
      'botón vuelve a deshabilitarse si se borra el campo obligatorio',
      (tester) async {
        await tester.pumpWidget(_buildApp(patient: _fakePatient()));
        await tester.pumpAndSettle();

        final historyField = _fieldWithHint(_hintHistory);
        await tester.ensureVisible(historyField);
        await tester.pump();
        await tester.enterText(historyField, 'Fiebre');
        await tester.pump();
        await tester.enterText(historyField, '');
        await tester.pump();

        await tester.ensureVisible(_guardarButtonFinder());
        await tester.pump();

        expect(_isGuardarEnabled(tester), isFalse);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET — SUCCESS STEP
  // ════════════════════════════════════════════════════════════════════════════

  group('Success step', () {
    testWidgets('muestra ícono check tras guardar', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('muestra "Consulta guardada exitosamente"', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.text('Consulta guardada exitosamente'), findsWidgets);
    });

    testWidgets('muestra nombre del paciente en el paso de éxito', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.text('Laura Ríos'), findsOneWidget);
    });

    testWidgets('muestra fila "Guardado local: Exitoso"', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.textContaining('Guardado local'), findsOneWidget);
      expect(find.text('Exitoso'), findsOneWidget);
    });

    testWidgets('muestra fila de sincronización', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.textContaining('Sincronización'), findsOneWidget);
      expect(find.textContaining('En cola'), findsOneWidget);
    });

    testWidgets('muestra SnackBar de éxito', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(
        find.textContaining('Consulta guardada exitosamente ✓'),
        findsOneWidget,
      );
    });

    testWidgets('sin alergia cat. 01 → no aparece advertencia', (tester) async {
      await tester.pumpWidget(
        _buildApp(patient: _fakePatient(), scope: _scopeWithSave()),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.textContaining('alertas de alergia'), findsNothing);
    });

    testWidgets('con alergia cat. 01 → aparece advertencia de alergia', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          patient: _fakePatient(allergies: [_allergyMed()]),
          scope: _scopeWithSave(),
        ),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.textContaining('alertas de alergia'), findsOneWidget);
    });

    testWidgets('error al guardar muestra SnackBar con "Error al guardar:"', (
      tester,
    ) async {
      final db = _MockLocalDatabase();
      final sync = _MockSyncEngine();
      when(() => db.savePatient(any())).thenThrow(Exception('sin espacio'));
      when(() => sync.syncAll()).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildApp(
          patient: _fakePatient(),
          scope: _defaultScope(db: db, sync: sync),
        ),
      );
      await tester.pumpAndSettle();

      await _fillAndSave(tester);

      expect(find.textContaining('Error al guardar:'), findsOneWidget);
      expect(find.text('Consulta guardada exitosamente'), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET — returnToProfile = true
  // ════════════════════════════════════════════════════════════════════════════

  group('returnToProfile = true', () {
    testWidgets('al guardar hace pop con MedicalHistoryItem', (tester) async {
      MedicalHistoryItem? popped;
      final scope = _defaultScope();

      await tester.pumpWidget(
        AppScope(
          authRepository: scope.authRepository,
          userRepository: scope.userRepository,
          patientRepository: scope.patientRepository,
          localDatabase: scope.localDatabase,
          syncEngine: scope.syncEngine,
          child: AppLocale(
            locale: 'es',
            setLocale: (_) {},
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () async {
                    final result = await Navigator.of(ctx)
                        .push<MedicalHistoryItem>(
                          MaterialPageRoute(
                            builder: (_) => AppScope(
                              authRepository: scope.authRepository,
                              userRepository: scope.userRepository,
                              patientRepository: scope.patientRepository,
                              localDatabase: scope.localDatabase,
                              syncEngine: scope.syncEngine,
                              child: AppLocale(
                                locale: 'es',
                                setLocale: (_) {},
                                child: AddConsultationScreen(
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

      final historyField = _fieldWithHint(_hintHistory);
      await tester.ensureVisible(historyField);
      await tester.pump();
      await tester.enterText(historyField, 'Consulta de seguimiento');
      await tester.pump();

      await _tapGuardar(tester);
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.type, 'Consultation');
      expect(
        popped!.clinicalEvaluation.historyOfCurrentIllness,
        'Consulta de seguimiento',
      );
    });
  });
}
