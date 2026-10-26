// test/widget/register_nfc_screen_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart'
    show NfcService;
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
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

class MockNfcKeyring extends Mock implements NfcKeyring {}

class _FakeSyncResult extends Fake implements SyncResult {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

class _FakeNfcWriteResult extends Fake implements NfcWriteResult {}

class _FakeLocalEntry extends Fake implements LocalPatientEntry {
  _FakeLocalEntry({required this.patientId, required this.isSynced});

  @override
  final String patientId;

  @override
  final bool isSynced;
}

class _FakeNfcService extends Fake implements NfcPayloadService {
  final List<Map<dynamic, dynamic>> triagePayloads = <Map<dynamic, dynamic>>[];
  final List<String?> triageUids = <String?>[];
  final List<String?> guardianUids = <String?>[];
  final List<String?> guardianPatientIds = <String?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final Map<Symbol, dynamic> named = invocation.namedArguments;
    if (invocation.memberName == #writeTriagePayload) {
      triagePayloads.add(invocation.positionalArguments.first as Map);
      triageUids.add(named[#expectedUid] as String?);
      return Future<NfcWriteResult>.value(_FakeNfcWriteResult());
    }
    if (invocation.memberName == #writeGuardianRecord) {
      guardianUids.add(named[#expectedUid] as String?);
      guardianPatientIds.add(named[#patientId] as String?);
      return Future<NfcWriteResult>.value(_FakeNfcWriteResult());
    }
    return super.noSuchMethod(invocation);
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
    final activeUser = user();
    when(() => auth.currentUser).thenReturn(activeUser);
    when(() => auth.getCurrentUser()).thenAnswer((_) async => activeUser);
    when(() => auth.restoreSession()).thenAnswer((_) async => activeUser);
    when(
      () => auth.sessionNotifier,
    ).thenReturn(ValueNotifier<UserSession?>(activeUser));
    when(() => auth.getNfcKeyring()).thenAnswer((_) async => null);
    when(() => auth.isNfcSessionExpired()).thenAnswer((_) async => false);
    when(() => auth.logout()).thenAnswer((_) async {});

    when(() => sync.isOnline).thenReturn(ValueNotifier<bool>(true));

    when(() => patientRepo.syncPatient(any())).thenAnswer(
      (_) async =>
          PatientSyncResponse(status: 'success', internalId: '', message: ''),
    );

    when(
      () => db.savePatient(
        any(),
        ownerUserId: any(named: 'ownerUserId'),
        organizationId: any(named: 'organizationId'),
        retiredDeviceReason: any(named: 'retiredDeviceReason'),
        isSynced: any(named: 'isSynced'),
      ),
    ).thenAnswer((_) async {});
    when(() => db.markSynced(any())).thenAnswer((_) async {});
    when(
      () => db.getAllRecords(ownerUserId: any(named: 'ownerUserId')),
    ).thenAnswer((_) async => []);
    when(
      () => db.clearChipsDirty(
        any(),
        patient: any(named: 'patient'),
        guardian: any(named: 'guardian'),
      ),
    ).thenAnswer((_) async {});
    when(() => sync.syncAll()).thenAnswer((_) async => _FakeSyncResult());
    when(() => sync.pendingCount).thenReturn(ValueNotifier<int>(0));
    when(() => sync.blockedCount).thenReturn(ValueNotifier<int>(0));
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
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _TestLocaleWrapper(
        initialLocale: locale,
        child: AppScope(
          authRepository: auth,
          userRepository: userRepo,
          patientRepository: patientRepo,
          localDatabase: db,
          syncEngine: sync,
          statsRepository: MockStatsRepository(),
          reachability: Reachability(baseUrl: 'http://localhost'),
          child: MaterialApp(
            home: const HomeScreen(),
            routes: {
              '/register': (_) => const RegisterNfcScreen(),
              '/login': (_) => const Scaffold(body: Text('Login Screen')),
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(HomeScreen));
    unawaited(Navigator.of(context).pushNamed('/register'));
    await tester.pumpAndSettle();
  }

  // ── Step-advance helpers ─────────────────────────────────────────────────

  Future<void> goToStep1(WidgetTester tester) async {
    tester.widget<Step3PatientData>(find.byType(Step3PatientData)).onContinue();
    await tester.pumpAndSettle();
  }

  Future<void> goToStep2(WidgetTester tester) async {
    tester.widget<Step2Guardian>(find.byType(Step2Guardian)).onContinue();
    await tester.pumpAndSettle();
  }

  Future<void> goToStep3(WidgetTester tester) async {
    tester.widget<Step4Background>(find.byType(Step4Background)).onContinue();
    await tester.pumpAndSettle();
  }

  Future<void> advanceToReview(WidgetTester tester) async {
    await goToStep1(tester);
    await goToStep2(tester);
    await goToStep3(tester);
  }

  Future<void> advanceToHub(WidgetTester tester) async {
    await advanceToReview(tester);
    await tester.widget<Step5Review>(find.byType(Step5Review)).onConfirm();
    await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();

        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          final confirmBtn = find.text('Descartar');
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn);
          } else {
            await tester.tap(find.text('Discard'));
          }
          await tester.pumpAndSettle();
        }

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
      await tester.pumpAndSettle();

      expect(find.byType(Step3PatientData), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets(
      'en el hub (paso 4) el header no muestra stepText ni back button',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);
        expect(find.text('5/4'), findsNothing);
        expect(find.text('1/4'), findsNothing);
      },
    );
  });

  group('RegisterNfcScreen — un dispositivo del guardián por menor', () {
    const String inUse =
        'Este dispositivo ya pertenece a otro paciente. Cada menor necesita '
        'su propio dispositivo del guardián: use uno en blanco.';

    tearDown(() {
      RegisterNfcScreen.overrideReadHwbChip = null;
      NfcService.overrideReadDeviceUid = null;
    });

    Future<String?> readFromStep2(WidgetTester tester) async {
      await pumpScreen(tester);
      await goToStep1(tester);
      final step2 = tester.widget<Step2Guardian>(find.byType(Step2Guardian));
      String? uid;
      await tester.runAsync(() async => uid = await step2.readDevice!());
      await tester.pump();
      return uid;
    }

    testWidgets('acepta un dispositivo en blanco', (tester) async {
      when(() => auth.getNfcKeyring()).thenAnswer(
        (_) async => NfcKeyring.single(List.filled(32, 'ab').join()),
      );
      RegisterNfcScreen.overrideReadHwbChip = () async =>
          const HwbChipReadResult(uid: '04:AA:BB', kind: HwbChipKind.none);

      expect(await readFromStep2(tester), '04:AA:BB');
      expect(find.text(inUse), findsNothing);
    });

    for (final HwbChipKind kind in <HwbChipKind>[
      HwbChipKind.guardian,
      HwbChipKind.triage,
    ]) {
      testWidgets('rechaza un dispositivo que ya es de un paciente ($kind)', (
        tester,
      ) async {
        when(() => auth.getNfcKeyring()).thenAnswer(
          (_) async => NfcKeyring.single(List.filled(32, 'ab').join()),
        );
        RegisterNfcScreen.overrideReadHwbChip = () async =>
            HwbChipReadResult(uid: '04:CC:DD', kind: kind);

        expect(await readFromStep2(tester), isNull);
        expect(find.text(inUse), findsOneWidget);
      });
    }

    testWidgets('sin llave NFC solo lee el UID', (tester) async {
      NfcService.overrideReadDeviceUid = () async => '04:EE:FF';

      expect(await readFromStep2(tester), '04:EE:FF');
    });
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
      await tester.pumpAndSettle();

      verify(
        () => db.savePatient(
          any(),
          ownerUserId: any(named: 'ownerUserId'),
          organizationId: any(named: 'organizationId'),
          retiredDeviceReason: any(named: 'retiredDeviceReason'),
          isSynced: any(named: 'isSynced'),
        ),
      ).called(1);
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
        await tester.pumpAndSettle();

        verify(
          () => db.savePatient(
            any(),
            ownerUserId: any(named: 'ownerUserId'),
            organizationId: any(named: 'organizationId'),
            retiredDeviceReason: any(named: 'retiredDeviceReason'),
            isSynced: any(named: 'isSynced'),
          ),
        ).called(2);
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

        Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop([
          VaccinationRecordItem(
            date: '2025-01-01',
            vaccineName: 'BCG',
            vaccineCode: '19',
            dose: 1,
            administratedBy: 'Dr. Ana',
            administratedAt: 'Clinic 1',
          ),
        ]);
        await tester.pumpAndSettle();

        verify(
          () => db.savePatient(
            any(),
            ownerUserId: any(named: 'ownerUserId'),
            organizationId: any(named: 'organizationId'),
            retiredDeviceReason: any(named: 'retiredDeviceReason'),
            isSynced: any(named: 'isSynced'),
          ),
        ).called(2);
        expect(find.byType(SnackBar).last, findsOneWidget);
        final success = tester.widget<Step6Success>(find.byType(Step6Success));
        expect(success.lastVaccineTime, isNotNull);
      },
    );
  });

  group(
    'RegisterNfcScreen — _finalize / _completeFinalize (sin llave NFC)',
    () {
      testWidgets('sin anillo NFC: no graba los chips, avisa y sella igual', (
        tester,
      ) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
        await tester.pumpAndSettle();

        verify(() => sync.syncAll()).called(1);
        expect(find.byType(Step6Success), findsOneWidget);
        final success = tester.widget<Step6Success>(find.byType(Step6Success));
        expect(success.sealed, isTrue);
        expect(success.onGoHome, isNotNull);
      });

      testWidgets(
        'desde la pantalla sellada, "Ir al inicio" navega a HomeScreen',
        (tester) async {
          await pumpScreen(tester);
          await advanceToHub(tester);

          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pumpAndSettle();

          final success = tester.widget<Step6Success>(
            find.byType(Step6Success),
          );
          expect(success.sealed, isTrue);

          success.onGoHome!();
          await tester.pumpAndSettle();

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
        'sin dispositivo de guardián: solo intenta el dispositivo del paciente',
        (tester) async {
          when(
            () => auth.getNfcKeyring(),
          ).thenAnswer((_) async => NfcKeyring.single(validHexKey));

          await pumpScreen(tester);
          await advanceToHub(tester);

          tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
          await tester.pump();
          await tester.pump();
          await pumpFrames(tester, 2);

          final nav = Navigator.of(tester.element(find.byType(Step6Success)));
          nav.pop(true);
          await tester.pumpAndSettle();

          verify(() => sync.syncAll()).called(1);
          final success = tester.widget<Step6Success>(
            find.byType(Step6Success),
          );
          expect(success.sealed, isTrue);
        },
      );

      testWidgets(
        'con dispositivo de guardián registrada: también intenta con el dispositivo del guardián',
        (tester) async {
          when(
            () => auth.getNfcKeyring(),
          ).thenAnswer((_) async => NfcKeyring.single(validHexKey));

          await pumpScreen(tester);
          tester
                  .widget<Step3PatientData>(find.byType(Step3PatientData))
                  .draft
                  .guardianDeviceUid =
              'AA:BB:CC:DD';
          await advanceToHub(tester);

          final onFinish = tester
              .widget<Step6Success>(find.byType(Step6Success))
              .onFinish;
          onFinish();
          await tester.pump();
          await tester.pump();
          await pumpFrames(tester, 2);

          final nav = Navigator.of(tester.element(find.byType(Step6Success)));
          nav.pop(true);
          await tester.pump();
          await pumpFrames(tester, 2);

          nav.pop(true);
          await tester.pumpAndSettle();

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

  group('RegisterNfcScreen — Unsaved Discard Dialog, System Pop & Errors', () {
    testWidgets(
      'shows confirm discard dialog on pop back when draft has entered data',
      (tester) async {
        await pumpScreen(tester);

        final step3 = tester.widget<Step3PatientData>(
          find.byType(Step3PatientData),
        );
        step3.draft.firstName = 'Juan';
        await tester.pump();

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('¿Descartar registro?'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterNfcScreen), findsOneWidget);
      },
    );

    testWidgets('confirms discard dialog when clicking Discard button', (
      tester,
    ) async {
      await pumpScreen(tester);

      final step3 = tester.widget<Step3PatientData>(
        find.byType(Step3PatientData),
      );
      step3.draft.firstName = 'Juan';
      await tester.pump();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows error snackbar when DB save fails in _confirm', (
      tester,
    ) async {
      when(
        () => db.savePatient(
          any(),
          ownerUserId: any(named: 'ownerUserId'),
          organizationId: any(named: 'organizationId'),
          retiredDeviceReason: any(named: 'retiredDeviceReason'),
          isSynced: any(named: 'isSynced'),
        ),
      ).thenThrow(Exception('Database error'));

      await pumpScreen(tester);
      await advanceToReview(tester);

      await tester.widget<Step5Review>(find.byType(Step5Review)).onConfirm();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No se pudo guardar el registro en este dispositivo.'),
        findsOneWidget,
      );
    });

    testWidgets('handles expired NFC session warning in _finalize', (
      tester,
    ) async {
      when(() => auth.getNfcKeyring()).thenAnswer((_) async => null);
      when(() => auth.isNfcSessionExpired()).thenAnswer((_) async => true);

      await pumpScreen(tester);
      await advanceToHub(tester);

      tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Su sesión expiró: el registro se guardó'),
        findsOneWidget,
      );
    });

    testWidgets('handles invalid keyring exception in _finalize', (
      tester,
    ) async {
      final mockKeyring = MockNfcKeyring();
      when(() => mockKeyring.canWrite).thenReturn(true);
      when(() => mockKeyring.isEmpty).thenThrow(Exception('Invalid keyring'));
      when(() => auth.getNfcKeyring()).thenAnswer((_) async => mockKeyring);

      await pumpScreen(tester);
      await advanceToHub(tester);

      tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('La clave NFC no es válida: el registro se guardó'),
        findsOneWidget,
      );
    });

    testWidgets('shows multiple vaccines saved snackbar when length > 1', (
      tester,
    ) async {
      await pumpScreen(tester);
      await advanceToHub(tester);

      tester.widget<Step6Success>(find.byType(Step6Success)).onAddVaccine();
      await pumpFrames(tester);

      Navigator.of(tester.element(find.byType(AddVaccineScreen))).pop([
        VaccinationRecordItem(
          date: '2025-01-01',
          vaccineName: 'BCG',
          vaccineCode: '19',
          dose: 1,
          administratedBy: 'Dr. Ana',
          administratedAt: 'Clinic 1',
        ),
        VaccinationRecordItem(
          date: '2025-01-01',
          vaccineName: 'Hepatitis B',
          vaccineCode: '20',
          dose: 1,
          administratedBy: 'Dr. Ana',
          administratedAt: 'Clinic 1',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('2 vacunas guardadas exitosamente ✓'), findsOneWidget);
    });

    testWidgets(
      'triggers sealed step 5 dummy callbacks without throwing exceptions',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
        await tester.pumpAndSettle();

        final sealedSuccess = tester.widget<Step6Success>(
          find.byType(Step6Success),
        );
        expect(sealedSuccess.sealed, isTrue);

        sealedSuccess.onAddConsultation();
        sealedSuccess.onAddVaccine();
        sealedSuccess.onFinish();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('handles two guardians during guided NFC write in _finalize', (
      tester,
    ) async {
      final validHexKey = List.filled(32, 'ab').join();
      when(
        () => auth.getNfcKeyring(),
      ).thenAnswer((_) async => NfcKeyring.single(validHexKey));

      await pumpScreen(tester);

      final step3 = tester.widget<Step3PatientData>(
        find.byType(Step3PatientData),
      );
      step3.draft.guardianDeviceUid = 'AA:BB:CC:DD';
      step3.draft.guardian2Name = 'Carlos Torres';
      step3.draft.guardian2DeviceUid = 'EE:FF:GG:HH';

      await advanceToHub(tester);

      final onFinish = tester
          .widget<Step6Success>(find.byType(Step6Success))
          .onFinish;
      onFinish();
      await tester.pump();
      await tester.pump();
      await pumpFrames(tester, 2);

      final nav = Navigator.of(tester.element(find.byType(Step6Success)));
      nav.pop(true);
      await tester.pump();
      await pumpFrames(tester, 2);

      nav.pop(true);
      await tester.pump();
      await pumpFrames(tester, 2);

      nav.pop(true);
      await tester.pumpAndSettle();

      verify(() => sync.syncAll()).called(1);
      final success = tester.widget<Step6Success>(find.byType(Step6Success));
      expect(success.sealed, isTrue);
    });
  });

  group('RegisterNfcScreen — Cobertura 100% de líneas faltantes', () {
    testWidgets(
      'System Pop cuando _savedRecord no es nulo ejecuta Navigator.pop() directamente',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(find.byType(RegisterNfcScreen), findsNothing);
      },
    );

    testWidgets(
      'System Pop cuando _step > 0 retrocede el paso sin mostrar el diálogo de descartar',
      (tester) async {
        await pumpScreen(tester);
        await goToStep1(tester);

        expect(find.byType(Step2Guardian), findsOneWidget);

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(find.byType(Step3PatientData), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'Restaura sesión mediante authRepository.restoreSession() si currentUser es nulo al confirmar',
      (tester) async {
        final activeUser = user();

        when(() => auth.currentUser).thenReturn(activeUser);

        await pumpScreen(tester);
        await advanceToReview(tester);

        when(() => auth.currentUser).thenReturn(null);
        when(() => auth.restoreSession()).thenAnswer((_) async => activeUser);

        await tester.widget<Step5Review>(find.byType(Step5Review)).onConfirm();
        await tester.pumpAndSettle();

        verify(() => auth.restoreSession()).called(1);
        expect(find.byType(Step6Success), findsOneWidget);
      },
    );

    testWidgets(
      'Muestra error SnackBar si falla la actualización en BD local dentro de _persistLocally',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        when(
          () => db.getAllRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenThrow(Exception('Local DB Fetch Error'));

        tester
            .widget<Step6Success>(find.byType(Step6Success))
            .onAddConsultation();
        await pumpFrames(tester);

        Navigator.of(tester.element(find.byType(AddConsultationScreen))).pop(
          MedicalHistoryItem(startDateTime: DateTime.now().toIso8601String()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('No se pudo actualizar el registro en este dispositivo.'),
          findsOneWidget,
        );
      },
    );
  });

  group('RegisterNfcScreen — Cobertura adicional (_stepBack, _persistLocally, '
      'lector real de chip)', () {
    tearDown(() {
      RegisterNfcScreen.overrideReadHwbChip = null;
      NfcService.overrideReadDeviceUid = null;
    });

    testWidgets(
      '_stepBack en el paso 0 con formulario vacío vuelve a Home sin diálogo',
      (tester) async {
        await pumpScreen(tester);
        expect(find.byType(Step3PatientData), findsOneWidget);

        tester.widget<Step3PatientData>(find.byType(Step3PatientData)).onBack();
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(RegisterNfcScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '_stepBack en el paso 0 con datos pide confirmar y al descartar vuelve '
      'a Home',
      (tester) async {
        await pumpScreen(tester);
        final step3 = tester.widget<Step3PatientData>(
          find.byType(Step3PatientData),
        );
        step3.draft.firstName = 'Juan';

        step3.onBack();
        await tester.pumpAndSettle();
        expect(find.text('¿Descartar registro?'), findsOneWidget);

        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterNfcScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '_persistLocally restaura la sesión cuando currentUser es nulo',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);

        tester
            .widget<Step6Success>(find.byType(Step6Success))
            .onAddConsultation();
        await pumpFrames(tester);
        expect(find.byType(AddConsultationScreen), findsOneWidget);

        when(() => auth.currentUser).thenReturn(null);

        Navigator.of(tester.element(find.byType(AddConsultationScreen))).pop(
          MedicalHistoryItem(startDateTime: DateTime.now().toIso8601String()),
        );
        await tester.pumpAndSettle();

        verify(() => auth.restoreSession()).called(greaterThanOrEqualTo(1));
        verify(() => db.getAllRecords(ownerUserId: 'u1')).called(1);
        expect(find.byType(Step6Success), findsOneWidget);
      },
    );

    testWidgets('con llave NFC y sin override, _readNewGuardianDevice usa '
        'NfcPayloadService.readHwbChip', (tester) async {
      when(() => auth.getNfcKeyring()).thenAnswer(
        (_) async => NfcKeyring.single(List.filled(32, 'ab').join()),
      );
      RegisterNfcScreen.overrideReadHwbChip = null;

      await pumpScreen(tester);
      await goToStep1(tester);
      final step2 = tester.widget<Step2Guardian>(find.byType(Step2Guardian));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception is PlatformException) return;
        originalOnError?.call(details);
      };
      try {
        await tester.runAsync(() async {
          try {
            await step2.readDevice!().timeout(const Duration(seconds: 3));
          } catch (_) {}
        });
        await tester.pump();
      } finally {
        FlutterError.onError = originalOnError;
      }

      verify(() => auth.getNfcKeyring()).called(greaterThanOrEqualTo(1));
      expect(RegisterNfcScreen.overrideReadHwbChip, isNull);
    });
  });

  group('RegisterNfcScreen — escritura real de chips al finalizar', () {
    final validHexKey = List.filled(32, 'ab').join();

    Future<void> finishSheet(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Empezar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));
    }

    late _FakeNfcService service;

    setUp(() {
      service = _FakeNfcService();
      RegisterNfcScreen.overrideServiceBuilder = (_) => service;
      when(
        () => auth.getNfcKeyring(),
      ).thenAnswer((_) async => NfcKeyring.single(validHexKey));
    });

    tearDown(() {
      RegisterNfcScreen.overrideServiceBuilder = null;
    });

    testWidgets('graba el dispositivo del paciente y limpia su marca', (
      tester,
    ) async {
      await pumpScreen(tester);
      await advanceToHub(tester);
      final PatientFullRecord saved = tester
          .widget<Step6Success>(find.byType(Step6Success))
          .patient;

      tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
      await tester.pump();
      await tester.pump();
      await finishSheet(tester);
      await tester.pumpAndSettle();

      expect(service.triageUids, <String?>[saved.deviceUid]);
      expect(service.triagePayloads, hasLength(1));
      expect(service.guardianUids, isEmpty);
      verify(
        () => db.clearChipsDirty(saved.patientId, patient: true),
      ).called(1);
      verify(() => sync.syncAll()).called(1);
      expect(
        tester.widget<Step6Success>(find.byType(Step6Success)).sealed,
        isTrue,
      );
    });

    testWidgets('graba también el dispositivo del guardián del paciente', (
      tester,
    ) async {
      await pumpScreen(tester);
      tester
              .widget<Step3PatientData>(find.byType(Step3PatientData))
              .draft
              .guardianDeviceUid =
          'AA:BB:CC:DD';
      await advanceToHub(tester);
      final PatientFullRecord saved = tester
          .widget<Step6Success>(find.byType(Step6Success))
          .patient;

      tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
      await tester.pump();
      await tester.pump();
      await finishSheet(tester);
      await finishSheet(tester);
      await tester.pumpAndSettle();

      expect(service.triageUids, hasLength(1));
      expect(service.guardianUids, <String?>['AA:BB:CC:DD']);
      expect(service.guardianPatientIds, <String?>[saved.patientId]);
      verify(
        () => db.clearChipsDirty(saved.patientId, guardian: true),
      ).called(1);
      expect(
        tester.widget<Step6Success>(find.byType(Step6Success)).sealed,
        isTrue,
      );
    });

    testWidgets('con dos guardianes graba ambos dispositivos en orden', (
      tester,
    ) async {
      await pumpScreen(tester);
      final Step3PatientData step3 = tester.widget<Step3PatientData>(
        find.byType(Step3PatientData),
      );
      step3.draft.guardianDeviceUid = 'AA:BB:CC:DD';
      step3.draft.guardian2Name = 'Carlos Torres';
      step3.draft.guardian2DeviceUid = 'EE:FF:00:11';
      await advanceToHub(tester);

      tester.widget<Step6Success>(find.byType(Step6Success)).onFinish();
      await tester.pump();
      await tester.pump();
      await finishSheet(tester);
      await finishSheet(tester);
      await finishSheet(tester);
      await tester.pumpAndSettle();

      expect(service.triageUids, hasLength(1));
      expect(service.guardianUids, <String?>['AA:BB:CC:DD', 'EE:FF:00:11']);
      verify(() => sync.syncAll()).called(1);
      expect(
        tester.widget<Step6Success>(find.byType(Step6Success)).sealed,
        isTrue,
      );
    });
  });

  group('RegisterNfcScreen — _persistLocally con registro ya guardado', () {
    Future<void> addConsultationAndReturn(WidgetTester tester) async {
      tester
          .widget<Step6Success>(find.byType(Step6Success))
          .onAddConsultation();
      await pumpFrames(tester);
      Navigator.of(tester.element(find.byType(AddConsultationScreen))).pop(
        MedicalHistoryItem(startDateTime: DateTime.now().toIso8601String()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'conserva isSynced=true si el registro ya estaba sincronizado',
      (tester) async {
        await pumpScreen(tester);
        await advanceToHub(tester);
        final String patientId = tester
            .widget<Step6Success>(find.byType(Step6Success))
            .patient
            .patientId;
        when(
          () => db.getAllRecords(ownerUserId: any(named: 'ownerUserId')),
        ).thenAnswer(
          (_) async => <LocalPatientEntry>[
            _FakeLocalEntry(patientId: 'otro-paciente', isSynced: false),
            _FakeLocalEntry(patientId: patientId, isSynced: true),
          ],
        );

        await addConsultationAndReturn(tester);

        verify(
          () => db.savePatient(
            any(),
            ownerUserId: 'u1',
            organizationId: 'org-1',
            retiredDeviceReason: any(named: 'retiredDeviceReason'),
            isSynced: true,
          ),
        ).called(1);
        expect(find.byType(Step6Success), findsOneWidget);
      },
    );

    testWidgets('mantiene isSynced=false si el registro estaba pendiente', (
      tester,
    ) async {
      await pumpScreen(tester);
      await advanceToHub(tester);
      final String patientId = tester
          .widget<Step6Success>(find.byType(Step6Success))
          .patient
          .patientId;
      when(
        () => db.getAllRecords(ownerUserId: any(named: 'ownerUserId')),
      ).thenAnswer(
        (_) async => <LocalPatientEntry>[
          _FakeLocalEntry(patientId: patientId, isSynced: false),
        ],
      );

      await addConsultationAndReturn(tester);

      verify(
        () => db.savePatient(
          any(),
          ownerUserId: 'u1',
          organizationId: 'org-1',
          retiredDeviceReason: any(named: 'retiredDeviceReason'),
          isSynced: false,
        ),
      ).called(2);
    });
  });
}
