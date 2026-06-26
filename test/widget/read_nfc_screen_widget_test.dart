// test/widget/read_nfc_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/read_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakePatientRepository implements PatientRepository {
  bool throw403ForGuardian = false;
  bool throwGenericError = false;
  bool throwGuardianError = false;
  String? lastCapturedGuardianUid;
  bool shouldDelay = false;

  @override
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
  }) async {
    lastCapturedGuardianUid = guardianDeviceUid;

    if (shouldDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (throwGenericError) {
      throw ApiException('Error de base de datos', statusCode: 500);
    }

    if (throw403ForGuardian && guardianDeviceUid == null) {
      throw ApiException(
        'Guardian bracelet scan required for minors.',
        statusCode: 403,
      );
    }

    if (throwGenericError) {
      return Future.error(
        ApiException('Error de base de datos', statusCode: 500),
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
  Future<PatientSyncResponse> syncPatient(PatientFullRecord record) =>
      throw UnimplementedError();

  @override
  Future<PatientFullRecord> searchPatient({
    required String documentNumber,
    required String birthDate,
    required String firstName,
    required String lastName,
    String? guardianName,
  }) => throw UnimplementedError();
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required super.child,
    required this.fakePatientRepository,
  });

  final FakePatientRepository fakePatientRepository;

  PatientRepository get patientRepository => fakePatientRepository;

  static AppScope of(BuildContext context) {
    final AppScope? result = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(result != null, 'No AppScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class _FakeLocaleProvider extends StatelessWidget {
  const _FakeLocaleProvider({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppLocale(locale: 'es', setLocale: (_) {}, child: child);
  }
}

Widget _buildTestableWidget({
  required Widget child,
  required FakePatientRepository repo,
}) {
  return _FakeLocaleProvider(
    child: AppScope(
      fakePatientRepository: repo,
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

  setUp(() {
    fakeRepo = FakePatientRepository();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      2000,
      2000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('ReadNfcScreen — Flujos base', () {
    testWidgets(
      'Debe renderizar el TextField del Paso 1 (Paciente) por defecto',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
        );
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'Ingreso Manual Adulto: avanza al perfil y muestra CircularProgressIndicator',
      (tester) async {
        fakeRepo.shouldDelay = true;

        await tester.pumpWidget(
          _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-ADULTO-88');
        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();
      },
    );

    testWidgets('Botón Atrás en Paso 2: limpia formulario y regresa a Paso 1', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;

      await tester.pumpWidget(
        _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
      );
      await tester.pump();

      await _advanceToStep2(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('_buildGuardianStep — renderizado completo del Paso 2', () {
    testWidgets('Paso 2 muestra TextField para UID del tutor', (tester) async {
      fakeRepo.throw403ForGuardian = true;

      await tester.pumpWidget(
        _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
      );
      await tester.pump();

      await _advanceToStep2(tester);

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Paso 2 muestra OutlinedButton para enviar UID del tutor', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;

      await tester.pumpWidget(
        _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
      );
      await tester.pump();

      await _advanceToStep2(tester);

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Paso 2 muestra ícono wifi (botón NFC) para tutor', (
      tester,
    ) async {
      fakeRepo.throw403ForGuardian = true;

      await tester.pumpWidget(
        _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
      );
      await tester.pump();

      await _advanceToStep2(tester);

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });
  });

  // ── _NfcButton scanning state ─────────────────────────────────────────────

  group('_NfcButton — estado de escaneo', () {
    testWidgets(
      'El botón NFC es tappable (onTap != null) cuando no está scanning',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
        );
        await tester.pump();

        expect(find.byIcon(Icons.wifi), findsOneWidget);
        await tester.tap(find.byIcon(Icons.wifi));
        await tester.pump();
      },
    );
  });
  group('_openProfile — reset de estado al volver del perfil del paciente', () {
    testWidgets(
      'Al volver del perfil adulto, la pantalla regresa al estado inicial',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(child: const ReadNfcScreen(), repo: fakeRepo),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'HWB-ADULTO-RESET');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

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
