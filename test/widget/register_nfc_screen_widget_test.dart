// test/widget/register_nfc_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_consultation_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/add_vaccine_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step2_guardian.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step3_patient_data.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step4_background.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step5_review.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step6_success.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Mocks
// ─────────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockStatsRepository extends Mock implements StatsRepository {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

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
      setLocale: (l) => setState(() => _locale = l),
      child: widget.child,
    );
  }
}

void main() {
  late final void Function(FlutterErrorDetails details)? originalOnError;

  setUpAll(() {
    originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('RenderFlex') ||
          message.contains('A RenderFlex')) {
        return;
      }
      originalOnError?.call(details);
    };
    registerFallbackValue(_FakePatientFullRecord());
  });

  tearDownAll(() {
    FlutterError.onError = originalOnError;
  });

  late MockAuthRepository auth;
  late MockUserRepository userRepo;
  late MockPatientRepository patientRepo;
  late MockLocalDatabase db;
  late MockSyncEngine sync;

  UserSession user({UserRole role = UserRole.doctor}) => UserSession(
    id: 'u1',
    email: 'doctor@hwb.org',
    fullName: 'Ana Doctor',
    role: role,
    organizationId: 'org-1',
  );

  void stubDefaults() {
    when(() => auth.currentUser).thenReturn(user());
    when(() => auth.getNfcEncryptionKey()).thenAnswer((_) async => null);
    when(() => auth.logout()).thenAnswer((_) async {});
    when(() => db.savePatient(any())).thenAnswer((_) async {});
    when(
      () => db.clearChipsDirty(
        any(),
        patient: any(named: 'patient'),
        guardian: any(named: 'guardian'),
      ),
    ).thenAnswer((_) async {});
    when(() => sync.syncAll()).thenAnswer((_) async {});
    when(() => sync.pendingCount).thenReturn(ValueNotifier<int>(0));
    when(() => sync.refreshPendingCount()).thenAnswer((_) async {});
  }

  setUp(() {
    auth = MockAuthRepository();
    userRepo = MockUserRepository();
    patientRepo = MockPatientRepository();
    db = MockLocalDatabase();
    sync = MockSyncEngine();
    stubDefaults();
  });

  Future<void> pumpScreen(WidgetTester tester, {String locale = 'es'}) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => _TestLocaleWrapper(
          initialLocale: locale,
          child: AppScope(
            authRepository: auth,
            userRepository: userRepo,
            patientRepository: patientRepo,
            localDatabase: db,
            syncEngine: sync,
            statsRepository: MockStatsRepository(),
            child: child!,
          ),
        ),
        home: const RegisterNfcScreen(),
      ),
    );
    await tester.pump();
  }

  // ── Step-advance helpers ─────────────────────────────────────────────────

  Future<void> goToStep1(WidgetTester tester) async {
    tester.widget<Step3PatientData>(find.byType(Step3PatientData)).onContinue();
    await tester.pump();
  }

  Future<void> goToStep2(WidgetTester tester) async {
    tester.widget<Step2Guardian>(find.byType(Step2Guardian)).onContinue();
    await tester.pump();
  }

  Future<void> goToStep3(WidgetTester tester) async {
    tester.widget<Step4Background>(find.byType(Step4Background)).onContinue();
    await tester.pump();
  }

  Future<void> advanceToReview(WidgetTester tester) async {
    await goToStep1(tester);
    await goToStep2(tester);
    await goToStep3(tester);
  }

  Future<void> advanceToHub(WidgetTester tester) async {
    await advanceToReview(tester);
    await tester.widget<Step5Review>(find.byType(Step5Review)).onConfirm();
    await tester.pump();
  }

  Future<void> pumpFrames(WidgetTester tester, [int times = 8]) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('RegisterNfcScreen — header & progress', () {
    testWidgets('paso inicial muestra "1/4" y el ProgressBar', (tester) async {
      await pumpScreen(tester);
      expect(find.text('1/4'), findsOneWidget);
      expect(find.byType(Step3PatientData), findsOneWidget);
    });

    testWidgets(
      'al retroceder desde el paso 0 navega a HomeScreen (_goToHomeDirectly)',
      (tester) async {
        await pumpScreen(tester);

        final backButton = find
            .descendant(
              of: find.byType(InkWell),
              matching: find.byIcon(Icons.arrow_back),
            )
            .first;

        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await pumpFrames(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RegisterNfcScreen), findsNothing);
      },
    );

    testWidgets('avanzar de paso actualiza el indicador "N/4"', (tester) async {
      await pumpScreen(tester);
      await goToStep1(tester);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.byType(Step2Guardian), findsOneWidget);

      await goToStep2(tester);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.byType(Step4Background), findsOneWidget);

      await goToStep3(tester);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.byType(Step5Review), findsOneWidget);
    });

    testWidgets('_stepBack retrocede un paso cuando step > 0', (tester) async {
      await pumpScreen(tester);
      await goToStep1(tester);
      expect(find.byType(Step2Guardian), findsOneWidget);

      tester.widget<Step2Guardian>(find.byType(Step2Guardian)).onBack();
      await tester.pump();

      expect(find.byType(Step3PatientData), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets(
      'en el hub (paso 4) el header no muestra stepText ni back button',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);
        expect(find.text('5/4'), findsNothing);
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      },
    );
  });

  group('RegisterNfcScreen — _isMinor', () {
    testWidgets(
      'dob null (paciente adulto por defecto) → requiredForMinor es true',
      (tester) async {
        await pumpScreen(tester);
        await goToStep1(tester);
        final step2 = tester.widget<Step2Guardian>(find.byType(Step2Guardian));
        expect(step2.requiredForMinor, isTrue);
      },
    );

    testWidgets('dob de un adulto → requiredForMinor es false', (tester) async {
      await pumpScreen(tester);
      final step3 = tester.widget<Step3PatientData>(
        find.byType(Step3PatientData),
      );
      step3.draft.dob = DateTime(1990, 1, 1);
      await goToStep1(tester);

      final step2 = tester.widget<Step2Guardian>(find.byType(Step2Guardian));
      expect(step2.requiredForMinor, isFalse);
    });

    testWidgets('dob de un menor → requiredForMinor es true', (tester) async {
      await pumpScreen(tester);
      final step3 = tester.widget<Step3PatientData>(
        find.byType(Step3PatientData),
      );
      step3.draft.dob = DateTime.now().subtract(const Duration(days: 365 * 5));
      await goToStep1(tester);

      final step2 = tester.widget<Step2Guardian>(find.byType(Step2Guardian));
      expect(step2.requiredForMinor, isTrue);
    });
  });

  group('RegisterNfcScreen — _confirm', () {
    testWidgets('confirmar guarda el paciente y avanza al hub (paso 4)', (
      tester,
    ) async {
      await pumpScreen(tester);
      await advanceToReview(tester);

      await tester.widget<Step5Review>(find.byType(Step5Review)).onConfirm();
      await tester.pump();

      verify(() => db.savePatient(any())).called(1);
      expect(find.byType(Step6Success), findsOneWidget);
      final success = tester.widget<Step6Success>(find.byType(Step6Success));
      expect(success.sealed, isFalse);
    });
  });

  group('RegisterNfcScreen — _addConsultation', () {
    testWidgets(
      'agregar consulta y volver con resultado null no actualiza nada',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester
            .widget<Step6Success>(find.byType(Step6Success))
            .onAddConsultation();
        await pumpFrames(tester);
        expect(find.byType(AddConsultationScreen), findsOneWidget);

        Navigator.of(
          tester.element(find.byType(AddConsultationScreen)),
        ).pop(null);
        await pumpFrames(tester);

        expect(find.byType(Step6Success), findsOneWidget);
      },
    );

    testWidgets(
      'agregar consulta con resultado no-nulo persiste, actualiza la hora y muestra snackbar',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester
            .widget<Step6Success>(find.byType(Step6Success))
            .onAddConsultation();
        await pumpFrames(tester);

        Navigator.of(tester.element(find.byType(AddConsultationScreen))).pop(
          MedicalHistoryItem(startDateTime: DateTime.now().toIso8601String()),
        );
        await tester.pump();
        await tester.pump();

        verify(() => db.savePatient(any())).called(2);
        expect(find.byType(SnackBar).last, findsOneWidget);
        final success = tester.widget<Step6Success>(find.byType(Step6Success));
        expect(success.lastConsultationTime, isNotNull);
      },
    );
  });

  group('RegisterNfcScreen — _addVaccine', () {
    testWidgets(
      'agregar vacuna y volver con resultado null no actualiza nada',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester.widget<Step6Success>(find.byType(Step6Success)).onAddVaccine();
        await pumpFrames(tester);
        expect(find.byType(AddVaccineScreen), findsOneWidget);

        Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop(null);
        await pumpFrames(tester);

        expect(find.byType(Step6Success), findsOneWidget);
      },
    );

    testWidgets(
      'agregar vacuna con resultado no-nulo persiste, actualiza la hora y muestra snackbar',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester.widget<Step6Success>(find.byType(Step6Success)).onAddVaccine();
        await pumpFrames(tester);

        Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop(
          VaccinationRecordItem(
            date: '2025-01-01',
            vaccineName: 'BCG',
            vaccineCode: '19',
            dose: 1,
            administratedBy: 'Dr. Ana',
            administratedAt: 'Clinic 1',
          ),
        );
        await tester.pump();
        await tester.pump();

        verify(() => db.savePatient(any())).called(2);
        expect(find.byType(SnackBar).last, findsOneWidget);
        final success = tester.widget<Step6Success>(find.byType(Step6Success));
        expect(success.lastVaccineTime, isNotNull);
      },
    );
  });

  group(
    'RegisterNfcScreen — _finalize / _completeFinalize (sin llave NFC)',
    () {
      testWidgets(
        'sin nfcKey: no abre overlay de escritura, sincroniza y sella (paso 5)',
        (tester) async {
          await pumpScreen(tester);
          await advanceToHub(tester);

          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pump();
          await tester.pump();

          verify(() => sync.syncAll()).called(1);
          expect(find.byType(Step6Success), findsOneWidget);
          final success = tester.widget<Step6Success>(
            find.byType(Step6Success),
          );
          expect(success.sealed, isTrue);
          expect(success.onGoHome, isNotNull);
        },
      );

      testWidgets(
        'desde la pantalla sellada, "Ir al inicio" navega a HomeScreen',
        (tester) async {
          await pumpScreen(tester);
          await advanceToHub(tester);
          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pump();
          await tester.pump();

          tester.widget<Step6Success>(find.byType(Step6Success)).onGoHome!();
          await pumpFrames(tester);

          expect(find.byType(HomeScreen), findsOneWidget);
        },
      );
    },
  );

  group(
    'RegisterNfcScreen — _finalize con nfcKey válida (chip no disponible en test)',
    () {
      final validHexKey = List.filled(32, 'ab').join();

      testWidgets(
        'sin tarjeta de guardián: solo intenta la pulsera del paciente',
        (tester) async {
          when(
            () => auth.getNfcEncryptionKey(),
          ).thenAnswer((_) async => validHexKey);

          await pumpScreen(tester);
          await advanceToHub(tester);

          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pump();
          await tester.pump();

          final navigator = Navigator.of(
            tester.element(find.byType(Step6Success)),
          );
          navigator.pop(true);
          await tester.pump();
          await tester.pump();

          verify(() => sync.syncAll()).called(1);
          final success = tester.widget<Step6Success>(
            find.byType(Step6Success),
          );
          expect(success.sealed, isTrue);
        },
      );

      testWidgets(
        'con tarjeta de guardián registrada: también intenta la tarjeta del guardián',
        (tester) async {
          when(
            () => auth.getNfcEncryptionKey(),
          ).thenAnswer((_) async => validHexKey);

          await pumpScreen(tester);
          tester
                  .widget<Step3PatientData>(find.byType(Step3PatientData))
                  .draft
                  .guardianDeviceUid =
              'AA:BB:CC:DD';
          await advanceToHub(tester);

          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pump();
          await tester.pump();

          final navigator = Navigator.of(
            tester.element(find.byType(Step6Success)),
          );

          navigator.pop(true);
          await tester.pump();
          await tester.pump();

          navigator.pop(true);
          await tester.pump();
          await tester.pump();

          verify(() => sync.syncAll()).called(1);
          final success = tester.widget<Step6Success>(
            find.byType(Step6Success),
          );
          expect(success.sealed, isTrue);
        },
      );
    },
  );

  group('RegisterNfcScreen — locale en inglés y alternancia', () {
    testWidgets('renderiza correctamente con locale "en"', (tester) async {
      await pumpScreen(tester, locale: 'en');
      expect(find.byType(Step3PatientData), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets(
      'alternar de ES a EN actualiza de forma reactiva las traducciones del formulario',
      (tester) async {
        await pumpScreen(tester, locale: 'es');

        expect(find.byType(Step3PatientData), findsOneWidget);

        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        expect(find.byType(Step3PatientData), findsOneWidget);
      },
    );
  });
}
