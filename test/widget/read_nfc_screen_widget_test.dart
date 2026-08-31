// test/widget/read_nfc_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/read_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakePatientRepository implements PatientRepository {
  bool throw403ForGuardian = false;
  bool throwGenericError = false;
  bool throwGuardianError = false;

  bool throwNonApiError = false;
  bool throwRetired410 = false;
  String? lastCapturedGuardianUid;
  bool shouldDelay = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
  }) async {
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
        detail: const <String, dynamic>{
          'code': 'device_retired',
          'reason': 'lost',
        },
      );
    }

    if (throw403ForGuardian && guardianDeviceUid == null) {
      throw ApiException(
        'Guardian bracelet scan required for minors.',
        statusCode: 403,
      );
    }

    if (throwGuardianError && guardianDeviceUid != null) {
      throw ApiException('Guardian inválido.', statusCode: 403);
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

  @override
  Future<String?> getNfcEncryptionKey() async {
    if (throwOnGetKey) {
      throw Exception('secure storage unavailable (simulated)');
    }
    return nfcKey;
  }
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

Widget _buildTestableWidget({
  required Widget child,
  required FakePatientRepository repo,
  FakeAuthRepository? authRepo,
  String locale = 'es',
}) {
  final auth = authRepo ?? FakeAuthRepository();
  final apiClient = ApiClient(baseUrl: 'http://test.local');
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
      localDatabase: LocalDatabase.instance,
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

    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      2000,
      2000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

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
      // Sigue en Paso 2 (no volvió a Paso 1).
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

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
      testWidgets(
        'authRepository.getNfcEncryptionKey() retorna null: se salta la '
        'lectura del chip y sigue el flujo normal por NfcService',
        (tester) async {
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
        },
      );
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
}
