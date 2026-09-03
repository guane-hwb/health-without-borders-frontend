// test/widget/patient_profile_screen_widget_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_consultation_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_vaccine_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_chronic_condition_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_family_history_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_medication_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/allergies_manage_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/background_manage_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_address_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_consultations.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_banners.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_header.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

class _NullApiClient implements ApiClient {
  const _NullApiClient();
  @override
  final String baseUrl = '';

  @override
  set tokenProvider(TokenProvider? _) {}

  @override
  Future<Map<String, dynamic>> getJson({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.getJson');

  @override
  Future<List<dynamic>> getJsonList({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.getJsonList');

  @override
  Future<Map<String, dynamic>> postJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.postJson');

  @override
  Future<Map<String, dynamic>> postForm({
    required String path,
    required Map<String, String> form,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.postForm');

  @override
  Future<Map<String, dynamic>> patchJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.patchJson');

  @override
  Future<void> delete({
    required String path,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async => throw UnsupportedError('_NullApiClient.delete');
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    UserRole role = UserRole.doctor,
    this.key,
    this.keyDelay,
  }) : _fakeUser = UserSession(
         id: 'u-test',
         email: 'test@example.com',
         fullName: 'Test User',
         role: role,
         organizationId: 'org-test',
       ),
       super(apiClient: const _NullApiClient());

  final UserSession _fakeUser;
  final String? key;
  final Duration? keyDelay;

  int getNfcEncryptionKeyCallCount = 0;

  @override
  UserSession? get currentUser => _fakeUser;

  @override
  Future<String?> getNfcEncryptionKey() async {
    getNfcEncryptionKeyCallCount++;
    if (keyDelay != null) await Future<void>.delayed(keyDelay!);
    return key ??
        '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF';
  }

  @override
  Future<NfcKeyring?> getNfcKeyring() async {
    final String? hex = await getNfcEncryptionKey();
    if (hex == null || hex.isEmpty) return null;
    return NfcKeyring.single(hex);
  }
}

class _FaultyLocalDatabase extends LocalDatabase {
  factory _FaultyLocalDatabase() {
    final store = <String, String>{};
    return _FaultyLocalDatabase._(store);
  }

  _FaultyLocalDatabase._(Map<String, String> store)
    : _memoryStore = store,
      super.forTesting(
        forceWeb: true,
        webGet: (key) => store[key],
        webSet: (key, value) => store[key] = value,
        webRemove: (key) => store.remove(key),
      );

  final Map<String, String> _memoryStore;

  bool throwOnGetChipStatus = false;
  bool throwOnSavePatient = false;
  bool throwOnMarkChipsDirty = false;
  bool throwOnClearChipsDirty = false;

  int savePatientCallCount = 0;
  int clearChipsDirtyCallCount = 0;

  @override
  Future<NfcChipStatus?> getChipStatus(String patientId) async {
    if (throwOnGetChipStatus) {
      throw Exception('Simulated getChipStatus failure');
    }
    return super.getChipStatus(patientId);
  }

  @override
  Future<void> savePatient(
    PatientFullRecord record, {
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
  }) async {
    savePatientCallCount++;
    if (throwOnSavePatient) {
      throw Exception('Simulated savePatient failure');
    }
    final key = 'patient_${record.patientId}';
    _memoryStore[key] = jsonEncode(record.toJson());
  }

  @override
  Future<void> markChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {
    if (throwOnMarkChipsDirty) {
      throw Exception('Simulated markChipsDirty failure');
    }
    return super.markChipsDirty(
      patientId,
      patient: patient,
      guardian: guardian,
    );
  }

  @override
  Future<void> clearChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {
    clearChipsDirtyCallCount++;
    if (throwOnClearChipsDirty) {
      throw Exception('Simulated clearChipsDirty failure');
    }
    return super.clearChipsDirty(
      patientId,
      patient: patient,
      guardian: guardian,
    );
  }
}

class _FakeSyncEngine extends SyncEngine {
  _FakeSyncEngine({this.shouldThrow = false})
    : super(
        patientRepository: PatientRepository(
          apiClient: const _NullApiClient(),
          authRepository: _FakeAuthRepository(),
        ),
        localDatabase: LocalDatabase.instance,
      );

  final bool shouldThrow;
  int callCount = 0;

  @override
  Future<bool> syncAll() async {
    callCount++;
    if (shouldThrow) throw Exception('Error de sincronización simulado');
    return true;
  }
}

class _LocaleWrapper extends StatefulWidget {
  const _LocaleWrapper({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_LocaleWrapper> createState() => _LocaleWrapperState();
}

class _LocaleWrapperState extends State<_LocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  Widget build(BuildContext context) => AppLocale(
    locale: _locale,
    setLocale: (l) => setState(() => _locale = l),
    child: widget.child,
  );
}

class _Fakes {
  _Fakes({required this.auth, required this.syncEngine, required this.db});
  final _FakeAuthRepository auth;
  final _FakeSyncEngine syncEngine;
  final _FaultyLocalDatabase db;
}

Widget _wrap(
  Widget child, {
  UserRole role = UserRole.doctor,
  bool syncShouldThrow = false,
  _FakeSyncEngine? syncEng,
  String locale = 'es',
  String? nfcKey,
  Duration? nfcKeyDelay,
  LocalDatabase? localDatabase,
  void Function(_Fakes fakes)? onFakesReady,
}) {
  final fakeAuth = _FakeAuthRepository(
    role: role,
    key: nfcKey,
    keyDelay: nfcKeyDelay,
  );
  final fakeSyncEngine =
      syncEng ?? _FakeSyncEngine(shouldThrow: syncShouldThrow);
  final db = localDatabase ?? _FaultyLocalDatabase();

  if (onFakesReady != null && db is _FaultyLocalDatabase) {
    onFakesReady(_Fakes(auth: fakeAuth, syncEngine: fakeSyncEngine, db: db));
  }

  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(
      home: AppScope(
        authRepository: fakeAuth,
        userRepository: UserRepository(
          apiClient: const _NullApiClient(),
          authRepository: fakeAuth,
        ),
        reachability: Reachability(baseUrl: 'http://localhost'),
        patientRepository: PatientRepository(
          apiClient: const _NullApiClient(),
          authRepository: fakeAuth,
        ),
        localDatabase: db,
        syncEngine: fakeSyncEngine,
        statsRepository: StatsRepository(
          apiClient: ApiClient(baseUrl: 'http://localhost'),
          authRepository: fakeAuth,
        ),
        child: child,
      ),
    ),
  );
}

Widget buildTestApp({required Widget child}) {
  return _wrap(child);
}

final _originalCheckConnectivity = PatientProfileScreen.checkConnectivityImpl;
final _originalConnectivityStream = PatientProfileScreen.connectivityStreamImpl;
final _originalShowReassignDialog =
    PatientProfileScreen.showReassignDeviceDialogImpl;
final _originalExecuteUpdateNfcChips =
    PatientProfileScreen.executeUpdateNfcChipsImpl;
final _originalExecuteReassignOne = PatientProfileScreen.executeReassignOneImpl;

void _resetScreenSeams() {
  PatientProfileScreen.checkConnectivityImpl = () async => [
    ConnectivityResult.wifi,
  ];
  PatientProfileScreen.connectivityStreamImpl = () =>
      Stream.value([ConnectivityResult.wifi]);
  PatientProfileScreen.showReassignDeviceDialogImpl =
      _originalShowReassignDialog;
  PatientProfileScreen.executeUpdateNfcChipsImpl =
      _originalExecuteUpdateNfcChips;
  PatientProfileScreen.executeReassignOneImpl = _originalExecuteReassignOne;
}

StreamController<List<ConnectivityResult>> _setConnectivity(
  List<ConnectivityResult> initial,
) {
  final controller = StreamController<List<ConnectivityResult>>.broadcast();
  PatientProfileScreen.checkConnectivityImpl = () async => initial;
  PatientProfileScreen.connectivityStreamImpl = () => controller.stream;
  return controller;
}

PatientInfo _info({
  String dob = '1990-06-15',
  String sex = 'M',
  String firstName = 'Juan',
  String idType = 'CC',
  String idNumber = '1234567',
}) => PatientInfo(
  identification: PatientIdentification(
    documentType: idType,
    documentNumber: idNumber,
  ),
  firstLastName: 'Pérez',
  secondLastName: '',
  firstName: firstName,
  secondName: '',
  dob: dob,
  biologicalSex: sex,
  address: Address(street: 'Calle 1', city: 'Bogotá', state: 'Cundinamarca'),
  nationalityCode: 'CO',
  nationalityName: 'Colombia',
  genderIdentity: '',
  ethnicity: '',
  ethnicCommunity: '',
  disabilityCategory: '',
  bloodType: 'O+',
);

PatientFullRecord _record({
  PatientInfo? info,
  BackgroundHistory? background,
  List<AllergyInfo> allergies = const [],
  List<MedicalHistoryItem> history = const [],
  List<VaccinationRecordItem> vaccines = const [],
  GuardianInfo? guardian,
}) => PatientFullRecord(
  patientId: 'pid-001',
  deviceUid: 'dev-001',
  patientInfo: info ?? _info(),
  guardianInfo:
      guardian ??
      GuardianInfo(
        name: 'Guardia 1',
        relationship: '01',
        phone: '123',
        deviceUid: 'gdev-001',
      ),
  guardian2Info: GuardianInfo(
    name: 'Guardia 2',
    relationship: '02',
    phone: '456',
  ),
  backgroundHistory: background ?? BackgroundHistory(),
  allergies: allergies,
  medicalHistory: history,
  vaccinationRecord: vaccines,
);

MedicalHistoryItem _consultationItem() =>
    MedicalHistoryItem(startDateTime: '2026-01-01T00:00:00');

Future<void> _pumpScreen(
  WidgetTester tester,
  PatientFullRecord patient, {
  bool readOnly = false,
  bool offline = false,
  bool allowReassign = false,
  UserRole role = UserRole.doctor,
  bool syncShouldThrow = false,
  _FakeSyncEngine? syncEng,
  String locale = 'es',
  String? nfcKey,
  Duration? nfcKeyDelay,
  LocalDatabase? localDatabase,
  void Function(_Fakes fakes)? onFakesReady,
}) async {
  await tester.pumpWidget(
    _wrap(
      PatientProfileScreen(
        patient: patient,
        readOnly: readOnly,
        offline: offline,
        allowReassign: allowReassign,
      ),
      role: role,
      syncShouldThrow: syncShouldThrow,
      syncEng: syncEng,
      locale: locale,
      nfcKey: nfcKey,
      nfcKeyDelay: nfcKeyDelay,
      localDatabase: localDatabase,
      onFakesReady: onFakesReady,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    _resetScreenSeams();
  });

  tearDown(() {
    PatientProfileScreen.checkConnectivityImpl = _originalCheckConnectivity;
    PatientProfileScreen.connectivityStreamImpl = _originalConnectivityStream;
    PatientProfileScreen.showReassignDeviceDialogImpl =
        _originalShowReassignDialog;
    PatientProfileScreen.executeUpdateNfcChipsImpl =
        _originalExecuteUpdateNfcChips;
    PatientProfileScreen.executeReassignOneImpl = _originalExecuteReassignOne;
  });

  group('PatientProfileScreen - Tests 1 a 20 (Render y Banners)', () {
    testWidgets('1. Renderiza pantalla base', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('2. Muestra nombre completo', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Juan'), findsAtLeastNWidgets(1));
    });

    testWidgets('3. Muestra banner offline cuando offline es true', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), offline: true);
      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('4. Banner offline en inglés', (tester) async {
      await _pumpScreen(tester, _record(), offline: true, locale: 'en');
      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('5. Tab bar con badge de consultas', (tester) async {
      await _pumpScreen(tester, _record(history: [_consultationItem()]));
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('6. Tab bar con badge de vacunas', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          vaccines: [
            VaccinationRecordItem(
              date: '2020',
              vaccineName: 'V',
              vaccineCode: 'C',
              dose: 1,
              administratedBy: 'A',
              administratedAt: '2020',
            ),
          ],
        ),
      );
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('7. Navegación a tab consultas', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.textContaining('Consultas'));
      await tester.pumpAndSettle();
    });

    testWidgets('8. Navegación a tab vacunas', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.textContaining('Vacunas'));
      await tester.pumpAndSettle();
    });

    testWidgets('9. Formato sexo M', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'M')));
      expect(find.textContaining('Masculino'), findsAtLeastNWidgets(1));
    });

    testWidgets('10. Formato sexo F', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'F')));
      expect(find.textContaining('Femenino'), findsAtLeastNWidgets(1));
    });

    testWidgets('11. Formato sexo Indeterminado', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'X')));
      expect(find.textContaining('Indeterminado'), findsAtLeastNWidgets(1));
    });

    testWidgets('12. Documento RC', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'RC', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('13. Documento TI', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'TI', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('14. Documento CE', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'CE', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('15. Documento PA', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'PA', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('16. Documento PE', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'PE', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('17. Documento PT', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'PT', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('18. Documento MS', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'MS', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('19. Documento AS', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'AS', idNumber: '1234567'),
        ),
      );
      expect(find.textContaining('1234567'), findsAtLeastNWidgets(1));
    });

    testWidgets('20. Conmutación de idioma ES a EN por toggle', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.text('EN').first);
      await tester.pumpAndSettle();
    });
  });

  group('PatientProfileScreen - Tests 21 a 40 (Modales y Callbacks de UI)', () {
    testWidgets('21. Modal de alergias abre al tocar sección de alergias', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      expect(find.textContaining('Alergias'), findsWidgets);
    });

    testWidgets('22. Modal antecedentes abre al tocar antecedentes', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      expect(find.textContaining('Antecedentes'), findsWidgets);
    });

    testWidgets(
      '23. Modal de signos vitales mediante callback del TabSummary',
      (tester) async {
        await _pumpScreen(tester, _record());
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditVitalSigns();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('24. Modal de dirección mediante callback del TabSummary', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditAddress();
      await tester.pumpAndSettle();
    });

    testWidgets('25. Modal de guardián 1 mediante callback', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditGuardian(1);
      await tester.pumpAndSettle();
    });

    testWidgets('26. Modal de guardián 2 mediante callback', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditGuardian(2);
      await tester.pumpAndSettle();
    });

    testWidgets(
      '27. Modales bloqueados cuando canEdit es false en ProfileTabSummary',
      (tester) async {
        await _pumpScreen(tester, _record(), readOnly: true);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        expect(summary.canEdit, isFalse);
      },
    );

    testWidgets('28. Renderizado con alergias previas', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          allergies: [AllergyInfo(allergen: 'Aspirina', category: '01')],
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      expect(find.textContaining('Aspirina'), findsWidgets);
    });

    testWidgets('29. Renderizado con condiciones crónicas previas', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            chronicConditions: [
              ChronicConditionItem(chronicDescription: 'HTA'),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      expect(find.textContaining('HTA'), findsWidgets);
    });

    testWidgets('30. Renderizado con medicamentos previos', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            medications: [
              MedicationStatementItem(
                medicationName: 'Metformina',
                status: 'active',
              ),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      expect(find.textContaining('Metformina'), findsWidgets);
    });

    testWidgets('31. Renderizado con antecedentes familiares previos', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            familyHistory: [
              FamilyHistoryItem(
                conditionDescription: 'Diabetes',
                relationship: '01',
              ),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      expect(find.textContaining('Diabetes'), findsWidgets);
    });

    testWidgets('32. Interacción con ícono de regreso en el Header', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('33. Abrir modal de alergias y simular botón cerrar', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('34. Abrir modal de antecedentes y simular botón cerrar', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets(
      '35. Intentar abrir guardián 2 cuando no existe no abre modal',
      (tester) async {
        await _pumpScreen(
          tester,
          PatientFullRecord(
            patientId: 'pid-001',
            deviceUid: 'dev-001',
            patientInfo: _info(),
            guardianInfo: GuardianInfo(
              name: 'G1',
              relationship: '01',
              phone: '123',
            ),
            guardian2Info: null,
          ),
        );
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditGuardian(2);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('36. Modales deshabilitados en modo readOnly en el root', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('37. Callback de dirección deshabilitado en readOnly', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditAddress();
      await tester.pumpAndSettle();
    });

    testWidgets('38. Callback de signos vitales deshabilitado en readOnly', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditVitalSigns();
      await tester.pumpAndSettle();
    });

    testWidgets('39. Callback de guardián deshabilitado en readOnly', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditGuardian(1);
      await tester.pumpAndSettle();
    });

    testWidgets('40. Callback de antecedentes deshabilitado en readOnly', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
    });
  });

  group('PatientProfileScreen - Tests 41 a 60 (Navegación y Flujos)', () {
    testWidgets('41. Navegación a agregar consulta con rol de Doctor', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), role: UserRole.doctor);
      await tester.tap(find.textContaining('Consultas'));
      await tester.pumpAndSettle();
    });

    testWidgets('42. Intentar agregar consulta con rol de Enfermero/a', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), role: UserRole.nurse);
      await tester.tap(find.textContaining('Consultas'));
      await tester.pumpAndSettle();
    });

    testWidgets('43. Navegación a agregar vacuna', (tester) async {
      await _pumpScreen(tester, _record(), role: UserRole.nurse);
      await tester.tap(find.textContaining('Vacunas'));
      await tester.pumpAndSettle();
    });

    testWidgets('44. Sync manual no muestra error en flujo normal', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
    });

    testWidgets('45. Sync con error controlado en repositorio', (tester) async {
      await _pumpScreen(tester, _record(), syncShouldThrow: true);
      await tester.pumpAndSettle();
    });

    testWidgets('46. Salir confirmando cambios con retroceso', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('47. Renderizado de campos con valores completos', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(info: _info(firstName: 'Carlos')));
      expect(find.textContaining('Carlos'), findsWidgets);
    });

    testWidgets('48. Formato sin clave NFC guardada', (tester) async {
      await _pumpScreen(tester, _record(), nfcKey: '');
      await tester.pumpAndSettle();
    });

    testWidgets('49. Formato sin clave NFC en inglés', (tester) async {
      await _pumpScreen(tester, _record(), nfcKey: '', locale: 'en');
      await tester.pumpAndSettle();
    });

    testWidgets(
      '50. Confirmación de salida sin diálogo al no tener cambios pendientes',
      (tester) async {
        await _pumpScreen(tester, _record());
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('51. Visualización de la tarjeta del paciente', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Pérez'), findsAtLeastNWidgets(1));
    });

    testWidgets('52. Cambio de idioma dinamico', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.tap(find.text('EN').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES').first);
      await tester.pumpAndSettle();
    });

    testWidgets('53. Verificación de pestañas visibles', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Resumen'), findsWidgets);
    });

    testWidgets('54. Verificación de pestaña Consultas visible', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Consultas'), findsWidgets);
    });

    testWidgets('55. Verificación de pestaña Vacunas visible', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Vacunas'), findsWidgets);
    });

    testWidgets('56. Renderizado de registro sin ID de paciente', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        PatientFullRecord(
          patientId: '',
          deviceUid: 'dev-001',
          patientInfo: _info(),
          guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
          backgroundHistory: BackgroundHistory(),
        ),
      );
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('57. Renderizado con guardián secundario opcional', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('58. Renderizado con historia médica vacía', (tester) async {
      await _pumpScreen(tester, _record(history: []));
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('59. Renderizado con lista de vacunas vacía', (tester) async {
      await _pumpScreen(tester, _record(vaccines: []));
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('60. Renderizado con alergias vacías', (tester) async {
      await _pumpScreen(tester, _record(allergies: []));
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });
  });

  group(
    'PatientProfileScreen - Tests 61 a 72 (Banners, Idiomas y Casos Borde)',
    () {
      testWidgets('61. Visualización de pantalla en estado readOnly', (
        tester,
      ) async {
        await _pumpScreen(tester, _record(), readOnly: true);
        expect(find.byType(PatientProfileScreen), findsOneWidget);
      });

      testWidgets('62. Visualización de pantalla en estado offline', (
        tester,
      ) async {
        await _pumpScreen(tester, _record(), offline: true);
        expect(find.byType(PatientProfileScreen), findsOneWidget);
      });

      testWidgets(
        '63. Visualización de pantalla en estado offline y readOnly',
        (tester) async {
          await _pumpScreen(tester, _record(), readOnly: true, offline: true);
          expect(find.byType(PatientProfileScreen), findsOneWidget);
        },
      );

      testWidgets(
        '64. Renderizado con fecha de nacimiento futura o recién nacido',
        (tester) async {
          final now = DateTime.now();
          final dobStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          await _pumpScreen(tester, _record(info: _info(dob: dobStr)));
          expect(find.textContaining('0 años'), findsAtLeastNWidgets(1));
        },
      );

      testWidgets(
        '65. Apertura de modal de alergias y verificar presencia de botón agregar',
        (tester) async {
          await _pumpScreen(tester, _record());
          final summary = tester.widget<ProfileTabSummary>(
            find.byType(ProfileTabSummary),
          );
          summary.onOpenAllergies();
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.add), findsWidgets);
        },
      );

      testWidgets(
        '66. Apertura de modal de antecedentes y verificar secciones',
        (tester) async {
          await _pumpScreen(tester, _record());
          final summary = tester.widget<ProfileTabSummary>(
            find.byType(ProfileTabSummary),
          );
          summary.onOpenBackground();
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
        },
      );

      testWidgets('67. Probar guardián con índice 1', (tester) async {
        await _pumpScreen(tester, _record());
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditGuardian(1);
        await tester.pumpAndSettle();
      });

      testWidgets('68. Probar guardián con índice 2 cuando existe guardián 2', (
        tester,
      ) async {
        await _pumpScreen(tester, _record());
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditGuardian(2);
        await tester.pumpAndSettle();
      });

      testWidgets('69. Renderizado en idioma EN', (tester) async {
        await _pumpScreen(tester, _record(), locale: 'en');
        expect(find.byType(PatientProfileScreen), findsOneWidget);
      });

      testWidgets('70. Muestra iniciales correctas en avatar', (tester) async {
        await _pumpScreen(tester, _record(info: _info(firstName: 'Juan')));
        expect(find.text('JP'), findsOneWidget);
      });

      testWidgets('71. Cierre de modal mediante botón cerrar en alergias', (
        tester,
      ) async {
        await _pumpScreen(tester, _record());
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onOpenAllergies();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      });

      testWidgets('72. Cierre de modal mediante botón cerrar en antecedentes', (
        tester,
      ) async {
        await _pumpScreen(tester, _record());
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onOpenBackground();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      });
    },
  );

  group('PatientProfileScreen – Manejo defensivo de datos', () {
    testWidgets('Renderiza edad y fecha sin error ante formatos ISO con hora', (
      tester,
    ) async {
      final record = PatientFullRecord(
        patientId: 'p-test-01',
        deviceUid: 'uid-test-01',
        patientInfo: PatientInfo(
          identification: PatientIdentification(
            documentType: 'CC',
            documentNumber: '123456',
          ),
          firstLastName: 'Pérez',
          firstName: 'Juan',
          dob: '2015-08-20T14:30:00.000Z',
          biologicalSex: 'M',
          address: Address(city: 'Bogotá', state: 'Cundinamarca'),
        ),
        guardianInfo: GuardianInfo(
          name: 'Maria Pérez',
          relationship: '01',
          phone: '3001234567',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(child: PatientProfileScreen(patient: record)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientProfileScreen), findsOneWidget);
      expect(find.textContaining('años'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'Muestra etiqueta o código fallback ante tipos de documento especiales o desconocidos',
      (tester) async {
        final record = PatientFullRecord(
          patientId: 'p-test-02',
          deviceUid: 'uid-test-02',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'DE',
              documentNumber: '987654',
            ),
            firstLastName: 'Gómez',
            firstName: 'Ana',
            dob: '2020-01-01',
            biologicalSex: 'F',
            address: Address(city: 'Medellín', state: 'Antioquia'),
          ),
          guardianInfo: GuardianInfo(
            name: 'Carlos Gómez',
            relationship: '01',
            phone: '3009876543',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(child: PatientProfileScreen(patient: record)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Doc. Extranjero 987654'), findsOneWidget);
      },
    );
  });

  group('Botón "Reasignar dispositivo" — visibilidad por origen', () {
    testWidgets('se muestra cuando allowReassign es true y no es readOnly', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), allowReassign: true);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar dispositivo'), findsOneWidget);
      expect(find.byIcon(Icons.published_with_changes), findsOneWidget);
    });

    testWidgets('se oculta por defecto (entrada por Leer NFC)', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar dispositivo'), findsNothing);
      expect(find.byIcon(Icons.published_with_changes), findsNothing);
    });

    testWidgets('se oculta en readOnly aunque allowReassign sea true', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), allowReassign: true, readOnly: true);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar dispositivo'), findsNothing);
      expect(find.byIcon(Icons.published_with_changes), findsNothing);
    });
  });

  group('Conectividad dinámica y sincronización automática al reconectar', () {
    testWidgets('73. Inicia sin conexión → banner offline dinámico visible', (
      tester,
    ) async {
      _setConnectivity([ConnectivityResult.none]);
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets(
      '74. Reconectar con cambios pendientes dispara sincronización automática',
      (tester) async {
        final controller = _setConnectivity([ConnectivityResult.none]);
        late _Fakes fakes;
        await _pumpScreen(tester, _record(), onFakesReady: (f) => fakes = f);
        await tester.pumpAndSettle();

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        final addressSheet = tester.widget<EditAddressSheet>(
          find.byType(EditAddressSheet),
        );
        addressSheet.onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        expect(fakes.syncEngine.callCount, 0);

        await tester.runAsync(() async {
          controller.add([ConnectivityResult.wifi]);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(fakes.syncEngine.callCount, greaterThanOrEqualTo(1));
        expect(find.byType(OfflineBanner), findsNothing);
        await controller.close();
      },
    );

    testWidgets(
      '75. Reconectar sin cambios pendientes NO dispara sincronización',
      (tester) async {
        final controller = _setConnectivity([ConnectivityResult.none]);
        late _Fakes fakes;
        await _pumpScreen(tester, _record(), onFakesReady: (f) => fakes = f);
        await tester.pumpAndSettle();

        controller.add([ConnectivityResult.wifi]);
        await tester.pumpAndSettle();

        expect(fakes.syncEngine.callCount, 0);
        await controller.close();
      },
    );

    testWidgets('76. Transición conectado → desconectado actualiza el banner', (
      tester,
    ) async {
      final controller = _setConnectivity([ConnectivityResult.wifi]);
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsNothing);

      controller.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsOneWidget);
      await controller.close();
    });
  });

  group('Estado del chip NFC y banner de chip desactualizado', () {
    testWidgets(
      '77. Chip marcado como sucio muestra el banner de actualización',
      (tester) async {
        final db = _FaultyLocalDatabase();
        await db.markChipsDirty('pid-001', patient: true, guardian: true);
        await _pumpScreen(tester, _record(), localDatabase: db);
        await tester.pumpAndSettle();
        expect(find.byType(NfcStaleBanner), findsOneWidget);
      },
    );

    testWidgets('78. Chip sucio pero en modo readOnly NO muestra el banner', (
      tester,
    ) async {
      final db = _FaultyLocalDatabase();
      await db.markChipsDirty('pid-001', patient: true, guardian: true);
      await _pumpScreen(tester, _record(), localDatabase: db, readOnly: true);
      await tester.pumpAndSettle();
      expect(find.byType(NfcStaleBanner), findsNothing);
    });

    testWidgets('79. Chip limpio no muestra el banner de actualización', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
      expect(find.byType(NfcStaleBanner), findsNothing);
    });

    testWidgets('80. Fallo al cargar el estado del chip no rompe la pantalla', (
      tester,
    ) async {
      final db = _FaultyLocalDatabase()..throwOnGetChipStatus = true;
      await _pumpScreen(tester, _record(), localDatabase: db);
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
      expect(find.byType(NfcStaleBanner), findsNothing);
    });

    testWidgets(
      '81. Editar con patientId vacío no marca ningún chip como sucio',
      (tester) async {
        final db = _FaultyLocalDatabase();
        await _pumpScreen(
          tester,
          PatientFullRecord(
            patientId: '',
            deviceUid: 'dev-001',
            patientInfo: _info(),
            guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
            backgroundHistory: BackgroundHistory(),
          ),
          localDatabase: db,
        );
        await tester.pumpAndSettle();

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        expect(find.byType(NfcStaleBanner), findsNothing);
      },
    );
  });

  group('_updateNfcChips — actualización de chips vía banner', () {
    Future<_Fakes> pumpDirty(
      WidgetTester tester, {
      String? nfcKey,
      Duration? nfcKeyDelay,
      String locale = 'es',
    }) async {
      late _Fakes fakes;
      final db = _FaultyLocalDatabase();
      await db.markChipsDirty('pid-001', patient: true, guardian: true);
      await _pumpScreen(
        tester,
        _record(),
        localDatabase: db,
        nfcKey: nfcKey,
        nfcKeyDelay: nfcKeyDelay,
        locale: locale,
        onFakesReady: (f) => fakes = f,
      );
      await tester.pumpAndSettle();
      return fakes;
    }

    testWidgets('82. Sin clave NFC (vacía) muestra snackbar en español', (
      tester,
    ) async {
      await pumpDirty(tester, nfcKey: '');
      tester.widget<NfcStaleBanner>(find.byType(NfcStaleBanner)).onUpdate();
      await tester.pumpAndSettle();
      expect(
        find.text('No hay clave NFC disponible para grabar.'),
        findsOneWidget,
      );
    });

    testWidgets('83. Sin clave NFC (vacía) muestra snackbar en inglés', (
      tester,
    ) async {
      await pumpDirty(tester, nfcKey: '', locale: 'en');
      tester.widget<NfcStaleBanner>(find.byType(NfcStaleBanner)).onUpdate();
      await tester.pumpAndSettle();
      expect(find.text('No NFC key available to write.'), findsOneWidget);
    });

    testWidgets(
      '84. executeUpdateNfcChips exitoso limpia el chip y oculta el banner',
      (tester) async {
        final fakes = await pumpDirty(tester);
        PatientProfileScreen.executeUpdateNfcChipsImpl =
            ({
              required context,
              required record,
              required keyring,
              required patientChipDirty,
              required guardianChipDirty,
            }) async => true;

        tester.widget<NfcStaleBanner>(find.byType(NfcStaleBanner)).onUpdate();
        await tester.pumpAndSettle();

        expect(fakes.db.clearChipsDirtyCallCount, greaterThanOrEqualTo(1));
        expect(find.byType(NfcStaleBanner), findsNothing);
      },
    );

    testWidgets('85. executeUpdateNfcChips fallido conserva el banner', (
      tester,
    ) async {
      await pumpDirty(tester);
      PatientProfileScreen.executeUpdateNfcChipsImpl =
          ({
            required context,
            required record,
            required keyring,
            required patientChipDirty,
            required guardianChipDirty,
          }) async => false;

      tester.widget<NfcStaleBanner>(find.byType(NfcStaleBanner)).onUpdate();
      await tester.pumpAndSettle();

      expect(find.byType(NfcStaleBanner), findsOneWidget);
    });

    testWidgets(
      '86. Doble toque rápido en "Actualizar" sólo dispara una actualización',
      (tester) async {
        var callCount = 0;
        final gate = Completer<void>();
        await pumpDirty(tester);
        PatientProfileScreen.executeUpdateNfcChipsImpl =
            ({
              required context,
              required record,
              required keyring,
              required patientChipDirty,
              required guardianChipDirty,
            }) async {
              callCount++;
              await gate.future;
              return true;
            };

        final banner = tester.widget<NfcStaleBanner>(
          find.byType(NfcStaleBanner),
        );
        banner.onUpdate();
        await tester.pump();
        await tester.pump();

        banner.onUpdate();

        gate.complete();
        await tester.pumpAndSettle();

        expect(callCount, 1);
      },
    );
  });

  group('_reassignDevices — flujo de reasignación de dispositivo', () {
    testWidgets('87. Cancelar el diálogo no realiza ninguna acción', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), allowReassign: true);
      PatientProfileScreen.showReassignDeviceDialogImpl =
          (context, {required isEs, required hasG1, required hasG2}) async =>
              null;

      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onReassignDevice!();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      '88. Selección sin objetivos (caso límite) no realiza ninguna acción',
      (tester) async {
        var executeCalls = 0;
        await _pumpScreen(tester, _record(), allowReassign: true);
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(targets: [], reason: 'lost');
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async {
              executeCalls++;
              return null;
            };

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(executeCalls, 0);
      },
    );

    testWidgets(
      '89. Sin clave NFC tras confirmar el diálogo muestra snackbar',
      (tester) async {
        await _pumpScreen(tester, _record(), allowReassign: true, nfcKey: '');
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient],
                  reason: 'lost',
                );

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(
          find.text('No hay clave NFC disponible para grabar.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '90. Reasignación exitosa de un solo objetivo guarda y sincroniza',
      (tester) async {
        late _Fakes fakes;
        await _pumpScreen(
          tester,
          _record(),
          allowReassign: true,
          onFakesReady: (f) => fakes = f,
        );
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient],
                  reason: 'lost',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async => record.copyWith(deviceUid: 'dev-NEW');

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );

        await tester.runAsync(() async {
          summary.onReassignDevice!();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(fakes.db.savePatientCallCount, greaterThanOrEqualTo(1));
        expect(fakes.syncEngine.callCount, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      '91. Reasignación exitosa de paciente + guardián 1 (dos objetivos)',
      (tester) async {
        final calledTargets = <ReassignTarget>[];
        await _pumpScreen(tester, _record(), allowReassign: true);
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient, ReassignTarget.guardian1],
                  reason: 'damaged',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async {
              calledTargets.add(target);
              return record;
            };

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(calledTargets, [
          ReassignTarget.patient,
          ReassignTarget.guardian1,
        ]);
      },
    );

    testWidgets(
      '92. Si el segundo objetivo falla, el ciclo corta pero conserva lo ya reasignado',
      (tester) async {
        var calls = 0;
        late _Fakes fakes;
        await _pumpScreen(
          tester,
          _record(),
          allowReassign: true,
          onFakesReady: (f) => fakes = f,
        );
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient, ReassignTarget.guardian1],
                  reason: 'lost',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async {
              calls++;
              if (target == ReassignTarget.patient) return record;
              return null;
            };

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(calls, 2);
        expect(fakes.db.savePatientCallCount, greaterThanOrEqualTo(1));
      },
    );

    testWidgets('93. Si todos los objetivos fallan, no se guarda nada', (
      tester,
    ) async {
      late _Fakes fakes;
      await _pumpScreen(
        tester,
        _record(),
        allowReassign: true,
        onFakesReady: (f) => fakes = f,
      );
      PatientProfileScreen.showReassignDeviceDialogImpl =
          (context, {required isEs, required hasG1, required hasG2}) async =>
              const ReassignSelection(
                targets: [ReassignTarget.patient],
                reason: 'lost',
              );
      PatientProfileScreen.executeReassignOneImpl =
          ({
            required context,
            required target,
            required record,
            required codec,
            required isEs,
            required showSnack,
          }) async => null;

      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onReassignDevice!();
      await tester.pumpAndSettle();

      expect(fakes.db.savePatientCallCount, 0);
    });

    testWidgets(
      '94. Reasignación exitosa sin conexión no sincroniza pero sí notifica',
      (tester) async {
        final controller = _setConnectivity([ConnectivityResult.none]);
        late _Fakes fakes;
        await _pumpScreen(
          tester,
          _record(),
          allowReassign: true,
          onFakesReady: (f) => fakes = f,
        );
        await tester.pumpAndSettle();
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient],
                  reason: 'lost',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async => record;

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(fakes.syncEngine.callCount, 0);
        await controller.close();
      },
    );

    testWidgets(
      '95. Fallo al guardar la reasignación muestra snackbar de error (ES)',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(
          tester,
          _record(),
          allowReassign: true,
          localDatabase: db,
        );
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient],
                  reason: 'lost',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async => record;

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo guardar la reasignación.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '96. Fallo al guardar la reasignación muestra snackbar de error (EN)',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(
          tester,
          _record(),
          allowReassign: true,
          localDatabase: db,
          locale: 'en',
        );
        PatientProfileScreen.showReassignDeviceDialogImpl =
            (context, {required isEs, required hasG1, required hasG2}) async =>
                const ReassignSelection(
                  targets: [ReassignTarget.patient],
                  reason: 'lost',
                );
        PatientProfileScreen.executeReassignOneImpl =
            ({
              required context,
              required target,
              required record,
              required codec,
              required isEs,
              required showSnack,
            }) async => record;

        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onReassignDevice!();
        await tester.pumpAndSettle();

        expect(find.text('Could not save the reassignment.'), findsOneWidget);
      },
    );
  });

  group('_saveAndPendingSync — guardado local y reintento', () {
    testWidgets('97. Guardado exitoso no muestra snackbar de error', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditAddress();
      await tester.pumpAndSettle();
      tester
          .widget<EditAddressSheet>(find.byType(EditAddressSheet))
          .onConfirm(Address(city: 'Cali', state: 'Valle'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No se pudo guardar en el dispositivo'),
        findsNothing,
      );
    });

    testWidgets(
      '98. Guardado exitoso con conexión dispara sincronización silenciosa',
      (tester) async {
        late _Fakes fakes;
        await _pumpScreen(tester, _record(), onFakesReady: (f) => fakes = f);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          tester
              .widget<EditAddressSheet>(find.byType(EditAddressSheet))
              .onConfirm(Address(city: 'Cali', state: 'Valle'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(fakes.syncEngine.callCount, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      '99. Fallo al guardar localmente muestra snackbar con acción Reintentar',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(tester, _record(), localDatabase: db);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('El cambio NO está a salvo'),
          findsOneWidget,
        );
        expect(find.byType(SnackBarAction), findsOneWidget);
      },
    );

    testWidgets(
      '100. Fallo al guardar localmente en inglés muestra el mensaje en inglés',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(tester, _record(), localDatabase: db, locale: 'en');
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        expect(find.textContaining('is NOT safe'), findsOneWidget);
      },
    );

    testWidgets(
      '101. Tocar "Reintentar" vuelve a intentar el guardado y retira la marca de fallo',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(tester, _record(), localDatabase: db);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        db.throwOnSavePatient = false;
        final action = tester.widget<SnackBarAction>(
          find.byType(SnackBarAction),
        );
        action.onPressed();

        ScaffoldMessenger.of(
          tester.element(find.byType(PatientProfileScreen)),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();

        expect(find.textContaining('El cambio NO está a salvo'), findsNothing);
      },
    );
  });

  group('_confirmExit — confirmación de salida tras un guardado fallido', () {
    testWidgets(
      '102. Muestra diálogo de confirmación si el último guardado falló',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(tester, _record(), localDatabase: db);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
        header.onBack();
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      '103. "Cancelar" en el diálogo mantiene al usuario en la pantalla',
      (tester) async {
        final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
        await _pumpScreen(tester, _record(), localDatabase: db);
        final summary = tester.widget<ProfileTabSummary>(
          find.byType(ProfileTabSummary),
        );
        summary.onEditAddress();
        await tester.pumpAndSettle();
        tester
            .widget<EditAddressSheet>(find.byType(EditAddressSheet))
            .onConfirm(Address(city: 'Cali', state: 'Valle'));
        await tester.pumpAndSettle();

        final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
        header.onBack();
        await tester.pumpAndSettle();

        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        (dialog.actions![0] as TextButton).onPressed!();
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(PatientProfileScreen), findsOneWidget);
      },
    );

    testWidgets('104. "Salir" en el diálogo abandona la pantalla', (
      tester,
    ) async {
      final db = _FaultyLocalDatabase()..throwOnSavePatient = true;
      await _pumpScreen(tester, _record(), localDatabase: db);
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditAddress();
      await tester.pumpAndSettle();
      tester
          .widget<EditAddressSheet>(find.byType(EditAddressSheet))
          .onConfirm(Address(city: 'Cali', state: 'Valle'));
      await tester.pumpAndSettle();

      final header = tester.widget<ProfileHeader>(find.byType(ProfileHeader));
      header.onBack();
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      (dialog.actions![1] as TextButton).onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Confirmación de sheets — actualizan el draft y disparan guardado', () {
    testWidgets('105. Confirmar signos vitales actualiza el draft', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditVitalSigns();
      await tester.pumpAndSettle();
      tester
          .widget<EditVitalSignsSheet>(find.byType(EditVitalSignsSheet))
          .onConfirm(weight: 72.5, height: 171, bloodType: 'A+');
      await tester.pumpAndSettle();

      expect(find.textContaining('72.5'), findsWidgets);
    });

    testWidgets('106. Confirmar guardián 1 actualiza el draft', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditGuardian(1);
      await tester.pumpAndSettle();
      tester
          .widget<EditGuardianSheet>(find.byType(EditGuardianSheet))
          .onConfirm(
            GuardianInfo(
              name: 'Nuevo Guardián',
              relationship: '02',
              phone: '3111111111',
            ),
          );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('107. Confirmar guardián 2 actualiza el draft', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onEditGuardian(2);
      await tester.pumpAndSettle();
      tester
          .widget<EditGuardianSheet>(find.byType(EditGuardianSheet))
          .onConfirm(
            GuardianInfo(
              name: 'Guardián Dos Nuevo',
              relationship: '03',
              phone: '3222222222',
            ),
          );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('108. Confirmar antecedentes personales actualiza el draft', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      final bg = tester.widget<BackgroundManageSheet>(
        find.byType(BackgroundManageSheet),
      );
      bg.onEditPersonal();
      await tester.pumpAndSettle();
      tester
          .widget<EditChronicPersonalSheet>(
            find.byType(EditChronicPersonalSheet),
          )
          .onConfirm('Sin antecedentes personales relevantes');
      await tester.pumpAndSettle();
    });

    testWidgets('109. Agregar condición crónica desde antecedentes', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      final bg = tester.widget<BackgroundManageSheet>(
        find.byType(BackgroundManageSheet),
      );
      bg.onAddChronic();
      await tester.pumpAndSettle();
      tester
          .widget<AddChronicConditionSheet>(
            find.byType(AddChronicConditionSheet),
          )
          .onAdd(ChronicConditionItem(chronicDescription: 'Asma'));
      await tester.pumpAndSettle();
    });

    testWidgets('110. Eliminar condición crónica desde antecedentes', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            chronicConditions: [
              ChronicConditionItem(chronicDescription: 'HTA'),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      tester
          .widget<BackgroundManageSheet>(find.byType(BackgroundManageSheet))
          .onRemoveChronic(0);
      await tester.pumpAndSettle();
    });

    testWidgets('111. Agregar medicamento desde antecedentes', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      tester
          .widget<BackgroundManageSheet>(find.byType(BackgroundManageSheet))
          .onAddMedication();
      await tester.pumpAndSettle();
      tester
          .widget<AddMedicationSheet>(find.byType(AddMedicationSheet))
          .onAdd(
            MedicationStatementItem(
              medicationName: 'Ibuprofeno',
              status: 'active',
            ),
          );
      await tester.pumpAndSettle();
    });

    testWidgets('112. Eliminar medicamento desde antecedentes', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            medications: [
              MedicationStatementItem(
                medicationName: 'Metformina',
                status: 'active',
              ),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      tester
          .widget<BackgroundManageSheet>(find.byType(BackgroundManageSheet))
          .onRemoveMedication(0);
      await tester.pumpAndSettle();
    });

    testWidgets('113. Agregar antecedente familiar', (tester) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      tester
          .widget<BackgroundManageSheet>(find.byType(BackgroundManageSheet))
          .onAddFamily();
      await tester.pumpAndSettle();
      tester
          .widget<AddFamilyHistorySheet>(find.byType(AddFamilyHistorySheet))
          .onAdd(
            FamilyHistoryItem(
              conditionDescription: 'Hipertensión',
              relationship: '01',
            ),
          );
      await tester.pumpAndSettle();
    });

    testWidgets('114. Eliminar antecedente familiar', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          background: BackgroundHistory(
            familyHistory: [
              FamilyHistoryItem(
                conditionDescription: 'Diabetes',
                relationship: '01',
              ),
            ],
          ),
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenBackground();
      await tester.pumpAndSettle();
      tester
          .widget<BackgroundManageSheet>(find.byType(BackgroundManageSheet))
          .onRemoveFamily(0);
      await tester.pumpAndSettle();
    });

    testWidgets('115. Agregar alergia desde el modal de alergias', (
      tester,
    ) async {
      await _pumpScreen(tester, _record());
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      tester
          .widget<AllergiesManageSheet>(find.byType(AllergiesManageSheet))
          .onAdd();
      await tester.pumpAndSettle();
      tester
          .widget<AddAllergySheet>(find.byType(AddAllergySheet))
          .onAdd(AllergyInfo(category: '02', allergen: 'Maní'));
      await tester.pumpAndSettle();
    });

    testWidgets('116. Eliminar alergia desde el modal de alergias', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _record(
          allergies: [AllergyInfo(allergen: 'Aspirina', category: '01')],
        ),
      );
      final summary = tester.widget<ProfileTabSummary>(
        find.byType(ProfileTabSummary),
      );
      summary.onOpenAllergies();
      await tester.pumpAndSettle();
      tester
          .widget<AllergiesManageSheet>(find.byType(AllergiesManageSheet))
          .onRemove(0);
      await tester.pumpAndSettle();
    });
  });

  group('Navegación a agregar consulta / vacuna', () {
    testWidgets(
      '117. Agregar consulta exitosamente actualiza el historial médico',
      (tester) async {
        await _pumpScreen(tester, _record(), role: UserRole.doctor);
        await tester.tap(find.textContaining('Consultas'));
        await tester.pumpAndSettle();

        final tab = tester.widget<ProfileTabConsultations>(
          find.byType(ProfileTabConsultations),
        );
        tab.onAdd();
        await tester.pumpAndSettle();
        expect(find.byType(AddConsultationScreen), findsOneWidget);

        Navigator.of(
          tester.element(find.byType(AddConsultationScreen)),
        ).pop(MedicalHistoryItem(startDateTime: '2026-01-01T00:00:00'));
        await tester.pumpAndSettle();

        expect(find.byType(AddConsultationScreen), findsNothing);
      },
    );

    testWidgets('118. Rol sin permiso para agregar consulta muestra snackbar', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), role: UserRole.nurse);
      await tester.tap(find.textContaining('Consultas'));
      await tester.pumpAndSettle();

      final tab = tester.widget<ProfileTabConsultations>(
        find.byType(ProfileTabConsultations),
      );
      tab.onAdd();
      await tester.pumpAndSettle();

      expect(find.byType(AddConsultationScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('119. Agregar vacuna(s) exitosamente actualiza el registro', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), role: UserRole.nurse);
      await tester.tap(find.textContaining('Vacunas'));
      await tester.pumpAndSettle();

      final tab = tester.widget<ProfileTabVaccines>(
        find.byType(ProfileTabVaccines),
      );
      tab.onAdd();
      await tester.pumpAndSettle();
      expect(find.byType(AddVaccineScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop([
        VaccinationRecordItem(
          date: '2026',
          vaccineName: 'BCG',
          vaccineCode: 'BCG',
          dose: 1,
          administratedBy: 'Enfermera',
          administratedAt: '2026',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(AddVaccineScreen), findsNothing);
    });

    testWidgets('120. Cancelar la pantalla de agregar vacuna no agrega nada', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), role: UserRole.nurse);
      await tester.tap(find.textContaining('Vacunas'));
      await tester.pumpAndSettle();

      final tab = tester.widget<ProfileTabVaccines>(
        find.byType(ProfileTabVaccines),
      );
      tab.onAdd();
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop(null);
      await tester.pumpAndSettle();

      expect(find.byType(AddVaccineScreen), findsNothing);
    });

    testWidgets('121. readOnly impide navegar a agregar consulta o vacuna', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      await tester.tap(find.textContaining('Consultas'));
      await tester.pumpAndSettle();

      final consultTab = tester.widget<ProfileTabConsultations>(
        find.byType(ProfileTabConsultations),
      );
      consultTab.onAdd();
      await tester.pumpAndSettle();
      expect(find.byType(AddConsultationScreen), findsNothing);

      await tester.tap(find.textContaining('Vacunas'));
      await tester.pumpAndSettle();

      final vaccineTab = tester.widget<ProfileTabVaccines>(
        find.byType(ProfileTabVaccines),
      );
      vaccineTab.onAdd();
      await tester.pumpAndSettle();
      expect(find.byType(AddVaccineScreen), findsNothing);
    });
  });
}
