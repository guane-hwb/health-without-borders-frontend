// test/widget/patient_profile_sheets_widget_test.dart
//
// The profile's edit sheets, opened as the profile opens them. What was typed
// is not saved anywhere until the sheet is confirmed, so no way of closing it
// may lose it without asking: dragging it down pops it without consulting its
// PopScope, and the barrier and the system back read canPop from the last
// build, which typing must keep current.

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
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_sheets.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_chronic_condition_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_family_history_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_medication_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_address_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

class _MockLocalDatabase extends Mock implements LocalDatabase {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockReachability extends Mock implements Reachability {}

final AppStrings _s = AppStrings.forTesting('es');

/// The dictation fields of some sheets read the connectivity from AppScope.
AppScope _scope({required Widget child}) {
  final auth = _MockAuthRepository();
  when(
    () => auth.sessionNotifier,
  ).thenReturn(ValueNotifier<UserSession?>(null));
  final sync = _MockSyncEngine();
  when(() => sync.isOnline).thenReturn(ValueNotifier<bool>(true));
  final reach = _MockReachability();
  when(() => reach.probe()).thenAnswer((_) async => true);
  return AppScope(
    authRepository: auth,
    userRepository: _MockUserRepository(),
    patientRepository: _MockPatientRepository(),
    localDatabase: _MockLocalDatabase(),
    syncEngine: sync,
    statsRepository: StatsRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
      authRepository: auth,
    ),
    reachability: reach,
    child: child,
  );
}

PatientFullRecord _draft() => PatientFullRecord(
  patientId: 'P-001',
  deviceUid: 'UID-001',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '987654321',
    ),
    firstName: 'Laura',
    firstLastName: 'Ríos',
    dob: '2005-08-15',
    biologicalSex: 'F',
    address: Address(city: 'Medellín', state: 'Antioquia'),
  ),
  guardianInfo: GuardianInfo(
    name: 'María García',
    relationship: '01',
    phone: '3001234567',
    docType: 'CC',
    docNumber: '1234567890',
  ),
);

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (Widget w) => w is TextField && w.decoration?.hintText == hint,
  description: 'TextField hint="$hint"',
);

class _Case {
  const _Case(this.name, this.sheet, this.open, this.field);

  final String name;
  final Type sheet;
  final Future<void> Function(BuildContext context) open;

  /// A field whose typing did not rebuild the sheet before the fix, where
  /// there is one.
  final Finder Function() field;
}

final List<_Case> _cases = <_Case>[
  _Case(
    'mediciones',
    EditVitalSignsSheet,
    (BuildContext context) => PatientProfileSheets.openVitalSignsSheet(
      context,
      draft: _draft(),
      original: _draft(),
      onConfirm:
          ({
            double? weight,
            double? height,
            String? bloodType,
            bool isBloodTypeCertified = false,
          }) {},
    ),
    () => _fieldWithHint('0.0'),
  ),
  _Case(
    'dirección',
    EditAddressSheet,
    (BuildContext context) => PatientProfileSheets.openAddressSheet(
      context,
      address: _draft().patientInfo.address,
      onConfirm: (_) {},
    ),
    () => _fieldWithHint(_s.streetHint),
  ),
  _Case(
    'cuidador',
    EditGuardianSheet,
    (BuildContext context) => PatientProfileSheets.openGuardianSheet(
      context,
      draft: _draft(),
      guardianIndex: 1,
      onConfirm: (_) {},
    ),
    () => _fieldWithHint(_s.guardianPhoneHint),
  ),
  _Case(
    'historial personal',
    EditChronicPersonalSheet,
    (BuildContext context) => PatientProfileSheets.openEditPersonalSheet(
      context,
      draft: _draft(),
      onConfirm: (_) {},
    ),
    () => find.byType(TextField),
  ),
  _Case(
    'condición crónica',
    AddChronicConditionSheet,
    (BuildContext context) => PatientProfileSheets.openAddChronicConditionSheet(
      context,
      onAdd: (_) {},
    ),
    () => find.byType(TextField),
  ),
  _Case(
    'medicamento',
    AddMedicationSheet,
    (BuildContext context) =>
        PatientProfileSheets.openAddMedicationSheet(context, onAdd: (_) {}),
    () => _fieldWithHint(_s.medicationHint),
  ),
  _Case(
    'antecedente familiar',
    AddFamilyHistorySheet,
    (BuildContext context) =>
        PatientProfileSheets.openAddFamilyHistorySheet(context, onAdd: (_) {}),
    () => find.byType(TextField),
  ),
  _Case(
    'alergia',
    AddAllergySheet,
    (BuildContext context) =>
        PatientProfileSheets.openAddAllergySheet(context, onAdd: (_) {}),
    () => _fieldWithHint(_s.allergenHint),
  ),
];

Future<void> _openSheet(WidgetTester tester, _Case c) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    _scope(
      child: AppLocale(
        locale: 'es',
        setLocale: (_) {},
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => c.open(context),
                  child: const Text('Abrir hoja'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir hoja'));
  await tester.pumpAndSettle();
  expect(find.byType(c.sheet), findsOneWidget);
}

Future<void> _type(WidgetTester tester, _Case c, String text) async {
  await tester.enterText(c.field().first, text);
  await tester.pump();
}

/// Taps the barrier, above the sheet.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

void main() {
  for (final _Case c in _cases) {
    group('Hoja de ${c.name}', () {
      testWidgets('arrastrarla hacia abajo con algo escrito no la cierra', (
        tester,
      ) async {
        await _openSheet(tester, c);
        await _type(tester, c, 'Texto de prueba');

        final Offset top = tester.getTopLeft(find.byType(c.sheet));
        await tester.flingFrom(
          top + const Offset(40, 6),
          const Offset(0, 900),
          3000,
        );
        await tester.pumpAndSettle();

        expect(find.byType(c.sheet), findsOneWidget);
        expect(find.text('Texto de prueba'), findsOneWidget);
      });

      testWidgets('tocar fuera con algo escrito pregunta; «Seguir editando» '
          'la deja abierta y «Descartar» la cierra', (tester) async {
        await _openSheet(tester, c);
        await _type(tester, c, 'Texto de prueba');

        await _tapOutside(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('¿Descartar lo que escribió?'), findsOneWidget);
        expect(
          find.text('Lo que escribió en esta hoja se perderá.'),
          findsOneWidget,
        );
        expect(find.text('Cambios sin sincronizar'), findsNothing);

        await tester.tap(find.text('Seguir editando'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(c.sheet), findsOneWidget);
        expect(find.text('Texto de prueba'), findsOneWidget);

        await _tapOutside(tester);
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();

        expect(find.byType(c.sheet), findsNothing);
      });
    });
  }

  testWidgets('el retroceso del sistema también pregunta antes de cerrar', (
    tester,
  ) async {
    final _Case allergy = _cases.last;
    await _openSheet(tester, allergy);
    await _type(tester, allergy, 'Penicilina');

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar lo que escribió?'), findsOneWidget);
    expect(find.byType(AddAllergySheet), findsOneWidget);
  });

  testWidgets('sin nada escrito, tocar fuera la cierra sin preguntar', (
    tester,
  ) async {
    await _openSheet(tester, _cases.last);

    await _tapOutside(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddAllergySheet), findsNothing);
  });
}
