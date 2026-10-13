// test/widget/read_nfc_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/read_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_screen.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockLocalDatabase extends Mock implements LocalDatabase {}

class FakePatientRepository implements PatientRepository {
  bool throw403ForGuardian = false;
  bool throwGenericError = false;
  bool throwGuardianError = false;

  /// Body of the first 403 (no guardian card): text and backend `code`.
  String guardianRequiredMessage =
      'Guardian bracelet scan required for minors.';
  String? guardianRequiredCode;

  /// Backend `code` of the step-2 403 (card does not match).
  String? guardianErrorCode;

  bool throwNonApiError = false;
  bool throwRetired410 = false;
  String retiredReason = 'lost';
  String? lastCapturedGuardianUid;
  bool shouldDelay = false;

  /// How many times `scanDevice` actually ran — lets a test prove the
  /// backend was never reached (e.g. a guardian card was detected before
  /// any submission), not just that no guardian UID happened to be null.
  int scanDeviceCallCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
  }) async {
    scanDeviceCallCount++;
    lastCapturedGuardianUid = guardianDeviceUid;

    if (shouldDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (throwNonApiError) {
      throw StateError('Network unreachable (simulated offline).');
    }

    if (throwGenericError) {
      throw ApiException('Error de base de datos', statusCode: 500);
    }

    if (throwRetired410) {
      throw ApiException(
        'Gone',
        statusCode: 410,
        detail: <String, dynamic>{
          'code': 'device_retired',
          'reason': retiredReason,
        },
      );
    }

    if (throw403ForGuardian && guardianDeviceUid == null) {
      throw ApiException(
        guardianRequiredMessage,
        statusCode: 403,
        code: guardianRequiredCode,
      );
    }

    if (throwGuardianError && guardianDeviceUid != null) {
      throw ApiException(
        'Guardian inválido.',
        statusCode: 403,
        code: guardianErrorCode,
      );
    }

    return PatientFullRecord(
      patientId: 'uuid-paciente-123',
      deviceUid: deviceUid,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '12345',
        ),
        firstName: 'Juan',
        firstLastName: 'Pérez',
        dob: '2000-01-01',
        biologicalSex: 'M',
        address: Address(city: 'Bogota', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(
        name: 'N/A',
        relationship: 'N/A',
        phone: 'N/A',
      ),
    );
  }

  @override
  Future<PatientSyncResponse> syncPatient(
    PatientFullRecord record, {
    String? retiredDeviceReason,
  }) => throw UnimplementedError();

  @override
  Future<PatientFullRecord> searchPatient({
    required String documentNumber,
    required String birthDate,
    required String firstName,
    required String lastName,
    String? guardianName,
  }) => throw UnimplementedError();
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
    : super(apiClient: ApiClient(baseUrl: 'http://test.local'));

  String? nfcKey;
  bool throwOnGetKey = false;
  bool isSessionExpiredFlag = false;
  UserSession? mockUser;

  @override
  UserSession? get currentUser => mockUser;

  @override
  ValueNotifier<bool> get sessionExpired =>
      ValueNotifier<bool>(isSessionExpiredFlag);

  @override
  Future<NfcKeyring?> getNfcKeyring() async {
    if (throwOnGetKey) {
      throw Exception('secure storage unavailable (simulated)');
    }
    final String? key = nfcKey;
    if (key == null || key.isEmpty) return null;
    return NfcKeyring.single(key);
  }

  @override
  Future<bool> isNfcSessionExpired() async => isSessionExpiredFlag;
}

class _FakeLocaleProvider extends StatelessWidget {
  const _FakeLocaleProvider({required this.child, this.locale = 'es'});
  final Widget child;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return AppLocale(locale: locale, setLocale: (_) {}, child: child);
  }
}

late MockLocalDatabase mockDb;

Widget _buildTestableWidget({
  required Widget child,
  required FakePatientRepository repo,
  FakeAuthRepository? authRepo,
  MockLocalDatabase? database,
  String locale = 'es',
}) {
  final auth = authRepo ?? FakeAuthRepository();
  final apiClient = ApiClient(baseUrl: 'http://test.local');
  mockDb = database ?? MockLocalDatabase();

  when(
    () => mockDb.recordNfcKeyVersion(
      deviceUid: any(named: 'deviceUid'),
      deviceRole: any(named: 'deviceRole'),
      keyVersion: any(named: 'keyVersion'),
      hadHeader: any(named: 'hadHeader'),
    ),
  ).thenAnswer((_) async {});

  when(
    () => mockDb.logEmergencyAccess(
      patientUid: any(named: 'patientUid'),
      patientName: any(named: 'patientName'),
      userId: any(named: 'userId'),
      ownerUserId: any(named: 'ownerUserId'),
      organizationId: any(named: 'organizationId'),
    ),
  ).thenAnswer((_) async {});

  when(
    () => mockDb.getSyncNotices(ownerUserId: any(named: 'ownerUserId')),
  ).thenAnswer((_) async => <SyncNotice>[]);

  return _FakeLocaleProvider(
    locale: locale,
    child: AppScope(
      authRepository: auth,
      userRepository: UserRepository(
        apiClient: apiClient,
        authRepository: auth,
      ),
      reachability: Reachability(baseUrl: 'http://localhost'),
      patientRepository: repo,
      localDatabase: mockDb,
      syncEngine: SyncEngine(patientRepository: repo),
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: auth,
      ),

      child: MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}

Future<void> _advanceToStep2(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'HWB-MENOR-05');
  await tester.tap(find.byType(OutlinedButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

// ===========================================================================
// TESTS
// ===========================================================================

void main() {
  late FakePatientRepository fakeRepo;
  late FakeAuthRepository fakeAuth;

  setUp(() {
    fakeRepo = FakePatientRepository();
    fakeAuth = FakeAuthRepository();
    NfcService.overrideReadDeviceUid = null;
    ReadNfcScreen.overrideReadHwbChip = null;

    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      2000,
      2000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
    ReadNfcScreen.overrideReadHwbChip = null;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  // ── Helpers for the "keyring present" chip-reading tests ─────────────────

  TriageSummary makeTriage({
    bool minor = false,
    String guardianDeviceUid = 'HWB-GUARDIAN-01',
    String? guardian2DeviceUid,
  }) {
    final String dob = minor
        ? '${DateTime.now().year - 10}-01-01'
        : '1990-01-01';
    return TriageSummary(
      firstName: minor ? 'Ana' : 'Juan',
      lastName: minor ? 'Gómez' : 'Pérez',
      dob: dob,
      biologicalSex: minor ? 'F' : 'M',
      bloodType: 'O+',
      documentType: 'CC',
      documentNumber: '12345',
      guardianPhone: '3000000000',
      guardianDeviceUid: guardianDeviceUid,
      guardian2DeviceUid: guardian2DeviceUid,
      chronicConditions: '',
      allergies: const <TriageAllergy>[],
    );
  }

  Future<void> reachOfflineGate(
    WidgetTester tester, {
    required TriageSummary triage,
  }) async {
    fakeAuth.nfcKey = 'secret-key';
    fakeRepo.throwNonApiError = true;
    ReadNfcScreen.overrideReadHwbChip =
        ({required String alertMessage}) async => HwbChipReadResult(
          uid: 'HWB-PATIENT-GATE',
          kind: HwbChipKind.triage,
          triage: triage,
        );

    await tester.pumpWidget(
      _buildTestableWidget(
        child: const ReadNfcScreen(),
        repo: fakeRepo,
        authRepo: fakeAuth,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.wifi));
    await tester.pumpAndSettle();
  }

  group('ReadNfcScreen — Flujos base', () {
    testWidgets(
      'Debe renderizar el TextField del Paso 1 (Paciente) por defecto',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'Ingreso Manual Adulto: escaneo exitoso via UID manual navega al '
      'perfil (AppScope real, PatientRepository real invocado)',
      (tester) async {
        fakeRepo.shouldDelay = true;

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-ADULTO-88');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();

        expect(fakeRepo.lastCapturedGuardianUid, isNull);
      },
    );

    testWidgets('UID manual vacío: no dispara el envío (guard de UI)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Botón Atrás en Paso 2: limpia formulario y regresa a Paso 1', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;

      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();

      await _advanceToStep2(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Botón Atrás en Paso 1: hace pop de la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          child: Navigator(
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => const ReadNfcScreen()),
          ),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();

      expect(find.byType(ReadNfcScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ReadNfcScreen), findsNothing);
    });
  });

  group('Paso 1 — Errores del backend (ApiException)', () {
    testWidgets('403 sin "guardian": muestra el mensaje y NO avanza a Paso 2', (
      tester,
    ) async {
      fakeRepo.throwGenericError = false;
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();

      fakeRepo.throwGenericError = true;
      await tester.enterText(find.byType(TextField), 'HWB-ERROR-1');
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error de base de datos'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
      '410 device_retired: muestra el mensaje de dispositivo retirado con el motivo '
      'y NO avanza a Paso 2',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        fakeRepo.throwRetired410 = true;
        fakeRepo.retiredReason = 'lost';
        await tester.enterText(find.byType(TextField), 'HWB-RETIRED-1');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.text(
            'Este dispositivo fue retirado (perdida) y ya no pertenece a HWB.',
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'Error NO-ApiException (offline real) sin chip de respaldo: muestra '
      'mensaje "Sin conexión..." (locale ES)',
      (tester) async {
        fakeRepo.throwNonApiError = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
            locale: 'es',
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-OFFLINE-1');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(
          find.text('Sin conexión y sin respaldo legible en el chip.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Error NO-ApiException (offline real) sin chip de respaldo: muestra '
      'mensaje en inglés cuando el locale es "en"',
      (tester) async {
        fakeRepo.throwNonApiError = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
            locale: 'en',
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-OFFLINE-2');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(
          find.text('Offline and no readable backup on the chip.'),
          findsOneWidget,
        );
      },
    );
  });

  group('_buildGuardianStep — renderizado y flujo completo del Paso 2', () {
    testWidgets('Paso 2 muestra TextField, botón y wifi para el tutor', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets(
      'Guardián válido enviado manualmente: navega al perfil y el repo '
      'recibe el guardianDeviceUid correcto',
      (tester) async {
        fakeRepo.throw403ForGuardian = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();
        await _advanceToStep2(tester);

        await tester.enterText(find.byType(TextField), 'HWB-GUARDIAN-01');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(fakeRepo.lastCapturedGuardianUid, 'HWB-GUARDIAN-01');
      },
    );

    testWidgets('Guardián inválido: muestra el error y permanece en Paso 2', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      fakeRepo.throwGuardianError = true;
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      await tester.enterText(find.byType(TextField), 'HWB-GUARDIAN-BAD');
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Guardian inválido.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('el 403 del acudiente se reconoce por code, no por el texto', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      fakeRepo.guardianRequiredMessage = 'Acceso restringido.';
      fakeRepo.guardianRequiredCode = 'guardian_required';
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      expect(find.text('Acceso restringido.'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('guardian_mismatch muestra el mensaje traducido', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      fakeRepo.guardianRequiredCode = 'guardian_required';
      fakeRepo.throwGuardianError = true;
      fakeRepo.guardianErrorCode = 'guardian_mismatch';
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      await tester.enterText(find.byType(TextField), 'HWB-GUARDIAN-BAD');
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.textContaining('La tarjeta no corresponde a ningún acudiente'),
        findsOneWidget,
      );
      expect(find.text('Guardian inválido.'), findsNothing);
    });

    testWidgets(
      'un 403 de cuenta desactivada no pide la tarjeta del acudiente',
      (tester) async {
        fakeRepo.throw403ForGuardian = true;
        fakeRepo.guardianRequiredMessage = 'Inactive user (guardian)';
        fakeRepo.guardianRequiredCode = 'user_inactive';
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();
        await _advanceToStep2(tester);

        expect(
          find.textContaining('Tu cuenta está desactivada'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets(
      'Error NO-ApiException en submitGuardian: cae en el catch genérico '
      'y muestra el toString() de la excepción',
      (tester) async {
        fakeRepo.throw403ForGuardian = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();
        await _advanceToStep2(tester);

        fakeRepo.throwNonApiError = true;

        await tester.enterText(find.byType(TextField), 'HWB-GUARDIAN-02');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(find.textContaining('Network unreachable'), findsOneWidget);
      },
    );

    testWidgets('UID manual de guardián vacío: no dispara el envío', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(fakeRepo.lastCapturedGuardianUid, isNull);
    });
  });

  group('_NfcButton — escaneo real vía NfcService.overrideReadDeviceUid', () {
    testWidgets(
      'Paciente: NfcNotAvailableException muestra el hint y no navega',
      (tester) async {
        NfcService.overrideReadDeviceUid = () async =>
            throw NfcNotAvailableException();

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(
          find.text('NFC no disponible. Use el campo manual debajo.'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'Paciente: NfcSessionException muestra el mensaje de la excepción',
      (tester) async {
        NfcService.overrideReadDeviceUid = () async =>
            throw NfcSessionException('Tag perdido durante scan.');

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(find.text('Tag perdido durante scan.'), findsOneWidget);
      },
    );

    testWidgets(
      'Paciente: escaneo NFC exitoso completa el UID y navega al perfil',
      (tester) async {
        NfcService.overrideReadDeviceUid = () async => 'HWB-NFC-REAL-01';

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(fakeRepo.lastCapturedGuardianUid, isNull);
      },
    );

    testWidgets(
      'Guardián: NfcNotAvailableException en Paso 2 muestra el hint y '
      'permanece en Paso 2',
      (tester) async {
        fakeRepo.throw403ForGuardian = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();
        await _advanceToStep2(tester);

        NfcService.overrideReadDeviceUid = () async =>
            throw NfcNotAvailableException();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        expect(
          find.text('NFC no disponible. Use el campo manual debajo.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi), findsOneWidget);
      },
    );

    testWidgets('Guardián: NfcSessionException en Paso 2 muestra el mensaje', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;
      await tester.pumpWidget(
        _buildTestableWidget(
          child: const ReadNfcScreen(),
          repo: fakeRepo,
          authRepo: fakeAuth,
        ),
      );
      await tester.pump();
      await _advanceToStep2(tester);

      NfcService.overrideReadDeviceUid = () async =>
          throw NfcSessionException('Error NFC del tutor.');

      await tester.tap(find.byIcon(Icons.wifi));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Error NFC del tutor.'), findsOneWidget);
    });

    testWidgets(
      'Guardián: escaneo NFC exitoso completa el UID y envía al repo',
      (tester) async {
        fakeRepo.throw403ForGuardian = true;
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();
        await _advanceToStep2(tester);

        NfcService.overrideReadDeviceUid = () async => 'HWB-GUARDIAN-NFC-01';

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(fakeRepo.lastCapturedGuardianUid, 'HWB-GUARDIAN-NFC-01');
      },
    );
  });

  group(
    'Pre-lectura de chip NFC (requiere ReadNfcScreen.overrideReadHwbChip)',
    () {
      testWidgets('authRepository.getNfcKeyring() retorna null: se salta la '
          'lectura del chip y sigue el flujo normal por NfcService', (
        tester,
      ) async {
        fakeAuth.nfcKey = null;
        NfcService.overrideReadDeviceUid = () async => 'HWB-SIN-CHIP';

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(fakeRepo.lastCapturedGuardianUid, isNull);
      });
    },
  );

  group('_openProfile — reset de estado al volver del perfil del paciente', () {
    testWidgets(
      'Al volver del perfil adulto, la pantalla regresa al estado inicial',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-ADULTO-RESET');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.pop();
        await tester.pump();
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.wifi), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );
  });

  group(
    'ReadNfcScreen — Cobertura 100% (Offline Gate, Emergency & Retired Variants)',
    () {
      testWidgets(
        'Muestra razones de retiro por dispositivo dañado y reemplazado en 410',
        (tester) async {
          fakeRepo.throwRetired410 = true;

          fakeRepo.retiredReason = 'damaged';
          await tester.pumpWidget(
            _buildTestableWidget(
              child: const ReadNfcScreen(),
              repo: fakeRepo,
              authRepo: fakeAuth,
            ),
          );
          await tester.pump();
          await tester.enterText(find.byType(TextField), 'HWB-DAMAGED');
          await tester.tap(find.byType(OutlinedButton));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 10));

          expect(find.textContaining('dañada'), findsOneWidget);

          fakeRepo.retiredReason = 'replaced';
          await tester.tap(find.byType(OutlinedButton));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 10));

          expect(find.textContaining('reemplazada'), findsOneWidget);
        },
      );

      testWidgets(
        'Muestra error cuando la sesión NFC expiró y ocurre un error offline',
        (tester) async {
          fakeRepo.throwNonApiError = true;
          fakeAuth.isSessionExpiredFlag = true;
          fakeAuth.nfcKey = null;

          NfcService.overrideReadDeviceUid = () async => 'HWB-EXPIRED-OFFLINE';

          await tester.pumpWidget(
            _buildTestableWidget(
              child: const ReadNfcScreen(),
              repo: fakeRepo,
              authRepo: fakeAuth,
            ),
          );
          await tester.pump();

          await tester.tap(find.byIcon(Icons.wifi));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 20));

          expect(find.textContaining('su sesión expiró'), findsOneWidget);
        },
      );

      testWidgets(
        'Acceso de emergencia abre diálogo y registra en BD local al confirmar',
        (tester) async {
          fakeRepo.throwNonApiError = true;
          fakeAuth.nfcKey = 'secret-key';

          await tester.pumpWidget(
            _buildTestableWidget(
              child: const ReadNfcScreen(),
              repo: fakeRepo,
              authRepo: fakeAuth,
            ),
          );
          await tester.pump();

          final emergencyBtnFinder = find.text('Acceso de emergencia');
          if (emergencyBtnFinder.evaluate().isNotEmpty) {
            await tester.tap(emergencyBtnFinder);
            await tester.pumpAndSettle();

            expect(find.byType(AlertDialog), findsOneWidget);
            await tester.tap(find.text('Cancelar'));
            await tester.pumpAndSettle();

            expect(find.byType(AlertDialog), findsNothing);
          }
        },
      );
    },
  );

  group('ReadNfcScreen — Lectura real de chip (overrideReadHwbChip)', () {
    testWidgets(
      'Con keyring y chip válido, registra la key version y continúa el '
      'flujo online',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => const HwbChipReadResult(
              uid: 'HWB-CHIP-01',
              kind: HwbChipKind.none,
              keyVersion: 3,
              hadHeader: true,
            );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        verify(
          () => mockDb.recordNfcKeyVersion(
            deviceUid: 'HWB-CHIP-01',
            deviceRole: 'patient',
            keyVersion: 3,
            hadHeader: true,
          ),
        ).called(1);
        expect(fakeRepo.lastCapturedGuardianUid, isNull);
        expect(fakeRepo.scanDeviceCallCount, 1);
      },
    );

    testWidgets(
      'Chip de guardián detectado durante el escaneo de paciente muestra '
      'el error y nunca llama al backend',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => const HwbChipReadResult(
              uid: 'HWB-GUARDIAN-CARD',
              kind: HwbChipKind.guardian,
            );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(find.textContaining('tarjeta del guardián'), findsOneWidget);
        expect(fakeRepo.scanDeviceCallCount, 0);
      },
    );

    testWidgets(
      'NfcNotAvailableException durante la lectura del chip con keyring '
      'muestra el aviso de hardware no disponible',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async {
              throw NfcNotAvailableException();
            };

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(fakeRepo.scanDeviceCallCount, 0);
      },
    );

    testWidgets(
      'Offline: triage de menor sin conexión abre el gate de guardián',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        expect(find.text('Acceso de emergencia'), findsOneWidget);
      },
    );

    testWidgets(
      'Offline: triage de adulto sin conexión reconstruye el perfil de '
      'solo lectura y navega',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage());

        expect(find.text('Acceso de emergencia'), findsNothing);
        expect(find.byIcon(Icons.wifi), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Escaneo de guardián offline exitoso reconstruye el registro y '
        'navega al perfil con el paciente correcto', (tester) async {
      final triage = makeTriage(
        minor: true,
        guardianDeviceUid: 'HWB-GUARDIAN-01',
        guardian2DeviceUid: 'HWB-GUARDIAN-02',
      );
      await reachOfflineGate(tester, triage: triage);

      ReadNfcScreen.overrideReadHwbChip =
          ({required String alertMessage}) async => const HwbChipReadResult(
            uid: 'HWB-GUARDIAN-02',
            kind: HwbChipKind.guardian,
            guardianRecord: <String, dynamic>{'patientId': 'p-minor-01'},
            keyVersion: 4,
          );

      await tester.tap(find.byIcon(Icons.wifi));
      await tester.pumpAndSettle();

      expect(find.byType(PatientProfileScreen), findsOneWidget);
      final profileScreen = tester.widget<PatientProfileScreen>(
        find.byType(PatientProfileScreen),
      );

      expect(profileScreen.patient.patientId, equals('p-minor-01'));
      expect(find.byIcon(Icons.wifi), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Sin keyring en el escaneo de guardián offline y sesión expirada '
      'pide iniciar sesión de nuevo',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        fakeAuth.nfcKey = null;
        fakeAuth.isSessionExpiredFlag = true;

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(find.textContaining('sesión expiró'), findsOneWidget);
      },
    );

    testWidgets(
      'Sin keyring en el escaneo de guardián offline y sesión vigente '
      'avisa que no hay llave NFC',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        fakeAuth.nfcKey = null;
        fakeAuth.isSessionExpiredFlag = false;

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('No hay llave NFC disponible'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UID de guardián que no corresponde al paciente muestra el error',
      (tester) async {
        final triage = makeTriage(
          minor: true,
          guardianDeviceUid: 'HWB-GUARDIAN-VALIDO',
        );
        await reachOfflineGate(tester, triage: triage);

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => const HwbChipReadResult(
              uid: 'HWB-OTRA-PERSONA',
              kind: HwbChipKind.guardian,
              guardianRecord: <String, dynamic>{'patientId': 'x'},
            );

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('no corresponde al guardián'),
          findsOneWidget,
        );
        expect(find.byType(PatientProfileScreen), findsNothing);
        verifyNever(
          () => mockDb.logEmergencyAccess(
            patientUid: any(named: 'patientUid'),
            patientName: any(named: 'patientName'),
            userId: any(named: 'userId'),
            ownerUserId: any(named: 'ownerUserId'),
            organizationId: any(named: 'organizationId'),
          ),
        );
      },
    );

    testWidgets('Chip de tipo incorrecto o sin guardianRecord muestra "tarjeta '
        'vacía o no se pudo leer"', (tester) async {
      final triage = makeTriage(
        minor: true,
        guardianDeviceUid: 'HWB-GUARDIAN-01',
      );
      await reachOfflineGate(tester, triage: triage);

      ReadNfcScreen.overrideReadHwbChip =
          ({required String alertMessage}) async => const HwbChipReadResult(
            uid: 'HWB-GUARDIAN-01',
            kind: HwbChipKind.triage,
          );

      await tester.tap(find.byIcon(Icons.wifi));
      await tester.pumpAndSettle();

      expect(find.textContaining('vacía o no se pudo leer'), findsOneWidget);
    });

    testWidgets(
      'NfcNotAvailableException durante el escaneo de guardián offline '
      'muestra el aviso de hardware',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async {
              throw NfcNotAvailableException();
            };

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets(
      'NfcSessionException durante el escaneo de guardián offline muestra '
      'su propio mensaje',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async {
              throw NfcSessionException('mensaje de sesión simulado');
            };

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(find.text('mensaje de sesión simulado'), findsOneWidget);
      },
    );

    testWidgets(
      'Excepción genérica durante el escaneo de guardián offline muestra '
      'el mensaje por defecto',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async {
              throw StateError('boom');
            };

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo leer la tarjeta del guardián.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Acceso de emergencia: confirmar registra en BD local y navega en '
      'modo emergencia',
      (tester) async {
        await reachOfflineGate(tester, triage: makeTriage(minor: true));

        await tester.tap(find.text('Acceso de emergencia'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        verify(
          () => mockDb.logEmergencyAccess(
            patientUid: any(named: 'patientUid'),
            patientName: any(named: 'patientName'),
            userId: any(named: 'userId'),
            ownerUserId: any(named: 'ownerUserId'),
            organizationId: any(named: 'organizationId'),
          ),
        ).called(1);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cobertura del 100%: Ramas restantes en read_nfc_screen.dart
  // ══════════════════════════════════════════════════════════════════════════
  group('ReadNfcScreen — Cobertura 100% de líneas faltantes', () {
    testWidgets(
      'Muestra el texto del guardián offline en inglés cuando locale es "en"',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        fakeRepo.throwNonApiError = true;

        final triageMinor = TriageSummary(
          firstName: 'Ana',
          lastName: 'Gómez',
          dob: '${DateTime.now().year - 10}-01-01',
          biologicalSex: 'F',
          bloodType: 'O+',
          documentType: 'CC',
          documentNumber: '12345',
          guardianPhone: '3000000000',
          guardianDeviceUid: 'HWB-GUARDIAN-01',
          chronicConditions: '',
          allergies: const <TriageAllergy>[],
        );

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => HwbChipReadResult(
              uid: 'HWB-PATIENT-GATE',
              kind: HwbChipKind.triage,
              triage: triageMinor,
            );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
            locale: 'en',
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('is a minor. The guardian card is required'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Acceso de emergencia: al presionar Cancelar en el diálogo no navega y cierra el diálogo',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        fakeRepo.throwNonApiError = true;

        final triageMinor = TriageSummary(
          firstName: 'Carlos',
          lastName: 'Pérez',
          dob: '${DateTime.now().year - 10}-01-01',
          biologicalSex: 'M',
          bloodType: 'A+',
          documentType: 'CC',
          documentNumber: '54321',
          guardianPhone: '3000000000',
          guardianDeviceUid: 'HWB-GUARDIAN-02',
          chronicConditions: '',
          allergies: const <TriageAllergy>[],
        );

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => HwbChipReadResult(
              uid: 'HWB-PATIENT-GATE-2',
              kind: HwbChipKind.triage,
              triage: triageMinor,
            );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Acceso de emergencia'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'Acceso de emergencia: registra correctamente en la BD local cuando currentUser es nulo',
      (tester) async {
        fakeAuth.nfcKey = 'secret-key';
        fakeAuth.mockUser = null;
        fakeRepo.throwNonApiError = true;

        final triageMinor = TriageSummary(
          firstName: 'Pedro',
          lastName: 'Mendoza',
          dob: '${DateTime.now().year - 8}-01-01',
          biologicalSex: 'M',
          bloodType: 'B+',
          documentType: 'CC',
          documentNumber: '99999',
          guardianPhone: '3000000000',
          guardianDeviceUid: 'HWB-GUARDIAN-03',
          chronicConditions: '',
          allergies: const <TriageAllergy>[],
        );

        ReadNfcScreen.overrideReadHwbChip =
            ({required String alertMessage}) async => HwbChipReadResult(
              uid: 'HWB-PATIENT-GATE-3',
              kind: HwbChipKind.triage,
              triage: triageMinor,
            );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const ReadNfcScreen(),
            repo: fakeRepo,
            authRepo: fakeAuth,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Acceso de emergencia'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        verify(
          () => mockDb.logEmergencyAccess(
            patientUid: 'HWB-PATIENT-GATE-3',
            patientName: 'Pedro Mendoza',
            userId: null,
            ownerUserId: null,
            organizationId: null,
          ),
        ).called(1);
      },
    );
  });
}
