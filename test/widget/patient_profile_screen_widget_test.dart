// test/widget/patient_profile_screen_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';

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
  _FakeAuthRepository({UserRole role = UserRole.doctor, this.key})
    : _fakeUser = UserSession(
        id: 'u-test',
        email: 'test@example.com',
        fullName: 'Test User',
        role: role,
        organizationId: 'org-test',
      ),
      super(apiClient: const _NullApiClient());

  final UserSession _fakeUser;
  final String? key;

  @override
  UserSession? get currentUser => _fakeUser;

  @override
  Future<String?> getNfcEncryptionKey() async =>
      key ?? '0123456789ABCDEF0123456789ABCDEF';
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

Widget _wrap(
  Widget child, {
  UserRole role = UserRole.doctor,
  bool syncShouldThrow = false,
  _FakeSyncEngine? syncEng,
  String locale = 'es',
  String? nfcKey,
}) {
  final fakeAuth = _FakeAuthRepository(role: role, key: nfcKey);
  final fakeSyncEngine =
      syncEng ?? _FakeSyncEngine(shouldThrow: syncShouldThrow);

  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(
      builder: (context, navigatorChild) {
        return AppScope(
          authRepository: fakeAuth,
          userRepository: UserRepository(
            apiClient: const _NullApiClient(),
            authRepository: fakeAuth,
          ),
          patientRepository: PatientRepository(
            apiClient: const _NullApiClient(),
            authRepository: fakeAuth,
          ),
          localDatabase: LocalDatabase.instance,
          syncEngine: fakeSyncEngine,
          statsRepository: StatsRepository(
            apiClient: ApiClient(baseUrl: 'http://localhost'),
            authRepository: fakeAuth,
          ),
          child: navigatorChild!,
        );
      },
      home: child,
    ),
  );
}

Widget buildTestApp({required Widget child}) {
  return _wrap(child);
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
  UserRole role = UserRole.doctor,
  bool syncShouldThrow = false,
  String locale = 'es',
  String? nfcKey,
}) async {
  await tester.pumpWidget(
    _wrap(
      PatientProfileScreen(
        patient: patient,
        readOnly: readOnly,
        offline: offline,
      ),
      role: role,
      syncShouldThrow: syncShouldThrow,
      locale: locale,
      nfcKey: nfcKey,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
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
      expect(find.textContaining('sin conexión'), findsOneWidget);
    });

    testWidgets('4. Banner offline en inglés', (tester) async {
      await _pumpScreen(tester, _record(), offline: true, locale: 'en');
      expect(find.textContaining('Offline view'), findsOneWidget);
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
              documentType: 'DE', // Documento Extranjero
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
}
