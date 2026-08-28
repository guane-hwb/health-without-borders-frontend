// test/unit/edit_patient_screen_test.dart

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
import 'package:health_without_borders_frontend/src/features/nfc/presentation/edit_patient_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncEngine extends Mock implements SyncEngine {}

class FakePatientFullRecord extends Fake implements PatientFullRecord {}

class MockReachability extends Mock implements Reachability {}

AppScope _buildTestScope({
  Widget? child,
  MockLocalDatabase? dbMock,
  MockSyncEngine? syncMock,
}) {
  final auth = MockAuthRepository();
  when(
    () => auth.sessionNotifier,
  ).thenReturn(ValueNotifier<UserSession?>(null));

  final user = MockUserRepository();
  final repo = MockPatientRepository();
  final db = dbMock ?? MockLocalDatabase();
  final sync = syncMock ?? MockSyncEngine();

  when(() => db.savePatient(any<PatientFullRecord>())).thenAnswer((_) async {});
  when(
    () => db.markChipsDirty(
      any<String>(),
      guardian: any<bool>(named: 'guardian'),
    ),
  ).thenAnswer((_) async {});
  when(() => sync.syncAll()).thenAnswer((_) async => true);

  final resolvedReach = MockReachability();
  when(() => resolvedReach.probe()).thenAnswer((_) async => true);

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
    reachability: resolvedReach,
    child: child ?? const SizedBox.shrink(),
  );
}

Widget _wrap(
  Widget child, {
  String locale = 'es',
  MockLocalDatabase? dbMock,
  MockSyncEngine? syncMock,
}) {
  final scope = _buildTestScope(dbMock: dbMock, syncMock: syncMock);
  return AppScope(
    authRepository: scope.authRepository,
    userRepository: scope.userRepository,
    patientRepository: scope.patientRepository,
    localDatabase: scope.localDatabase,
    syncEngine: scope.syncEngine,
    reachability: scope.reachability,
    statsRepository: scope.statsRepository,
    child: MaterialApp(
      home: _AppLocaleProvider(locale: locale, child: child),
    ),
  );
}

class _AppLocaleProvider extends StatefulWidget {
  const _AppLocaleProvider({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_AppLocaleProvider> createState() => _AppLocaleProviderState();
}

class _AppLocaleProviderState extends State<_AppLocaleProvider> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
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

PatientFullRecord _makeRecord({
  String firstName = 'Laura',
  String firstLastName = 'Torres',
  String? secondLastName,
  String? secondName,
  String dob = '1995-07-10',
  String sex = 'F',
  String? bloodType = 'A+',
  double? weight = 58.0,
  double? height = 162.0,
  String nationalityCode = 'COL',
  String street = 'Calle 10 #20-30',
  String city = 'Bogotá',
  String state = 'Cundinamarca',
  String documentType = 'CC',
  String documentNumber = '10203040',
}) => PatientFullRecord(
  patientId: 'uuid-widget-test',
  deviceUid: 'NFC-WIDGET',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: documentType,
      documentNumber: documentNumber,
    ),
    firstLastName: firstLastName,
    secondLastName: secondLastName,
    firstName: firstName,
    secondName: secondName,
    dob: dob,
    biologicalSex: sex,
    nationalityCode: nationalityCode,
    bloodType: bloodType,
    weight: weight,
    height: height,
    address: Address(street: street, city: city, state: state),
  ),
  guardianInfo: GuardianInfo(
    name: 'Acudiente',
    relationship: 'Padre',
    phone: '3001112233',
  ),
);

class _PopSpy extends NavigatorObserver {
  bool didPopCalled = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPopCalled = true;
  }
}

Future<void> _pumpViaRoute(
  WidgetTester tester,
  PatientFullRecord record,
  _PopSpy spy, {
  String locale = 'es',
  MockLocalDatabase? dbMock,
  MockSyncEngine? syncMock,
}) async {
  final scope = _buildTestScope(dbMock: dbMock, syncMock: syncMock);
  await tester.pumpWidget(
    AppScope(
      authRepository: scope.authRepository,
      userRepository: scope.userRepository,
      patientRepository: scope.patientRepository,
      localDatabase: scope.localDatabase,
      syncEngine: scope.syncEngine,
      reachability: scope.reachability,
      statsRepository: scope.statsRepository,
      child: MaterialApp(
        navigatorObservers: [spy],
        home: _AppLocaleProvider(
          locale: locale,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _AppLocaleProvider(
                      locale: locale,
                      child: EditPatientScreen(patient: record),
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

final _s = AppStrings.forTesting('es');

void main() {
  setUpAll(() {
    registerFallbackValue(FakePatientFullRecord());
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('EditPatientScreen – campos read-only', () {
    testWidgets('muestra nombre completo del paciente', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text('Laura Torres'), findsOneWidget);
    });

    testWidgets('muestra nombre con segundo nombre y segundo apellido', (
      tester,
    ) async {
      final record = _makeRecord(
        firstName: 'Ana',
        secondName: 'Lucía',
        firstLastName: 'Ramírez',
        secondLastName: 'Gómez',
      );
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: record)));
      await tester.pumpAndSettle();
      expect(find.text('Ana Lucía Ramírez Gómez'), findsOneWidget);
    });

    testWidgets('muestra tipo y número de documento concatenados', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text('CC 10203040'), findsOneWidget);
    });

    testWidgets('muestra fecha de nacimiento', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text('1995-07-10'), findsOneWidget);
    });

    testWidgets('muestra tipo de sangre', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text('A+'), findsOneWidget);
    });

    testWidgets('muestra "N/A" cuando bloodType es null', (tester) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(bloodType: null))),
      );
      await tester.pumpAndSettle();
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('muestra sexo femenino como "Femenino"', (tester) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(sex: 'F'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Femenino'), findsOneWidget);
    });

    testWidgets('muestra sexo masculino como "Masculino"', (tester) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(sex: 'M'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Masculino'), findsOneWidget);
    });

    testWidgets('muestra sexo indeterminado como "Indeterminado"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(sex: 'I'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Indeterminado'), findsOneWidget);
    });

    testWidgets('sexo desconocido muestra el código raw', (tester) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(sex: 'X'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('los campos read-only muestran el ícono de candado', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });
  });

  group('EditPatientScreen – etiquetas de sección (i18n español)', () {
    testWidgets('muestra título de sección info read-only', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text(_s.patientInfoReadOnly), findsOneWidget);
    });

    testWidgets('muestra subtítulo de campos protegidos', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text(_s.fieldsProtected), findsOneWidget);
    });

    testWidgets('muestra sección info editable', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.text(_s.editableInfo), findsOneWidget);
    });

    testWidgets('muestra sección de dirección', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final sectionHeaderFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == _s.address &&
            widget.style?.fontSize == 15 &&
            widget.style?.fontWeight == FontWeight.w700,
      );

      expect(sectionHeaderFinder, findsOneWidget);
    });
  });

  group('EditPatientScreen – campos editables pre-rellenos', () {
    testWidgets('peso pre-relleno desde PatientInfo', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '58.0'), findsOneWidget);
    });

    testWidgets('altura pre-rellena desde PatientInfo', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '162.0'), findsOneWidget);
    });

    testWidgets('calle pre-rellena desde Address', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Calle 10 #20-30'), findsOneWidget);
    });

    testWidgets('ciudad pre-rellena desde Address', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Bogotá'), findsOneWidget);
    });

    testWidgets('departamento pre-relleno desde Address', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Cundinamarca'), findsOneWidget);
    });

    testWidgets('peso y altura vacíos cuando PatientInfo no los tiene', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditPatientScreen(patient: _makeRecord(weight: null, height: null)),
        ),
      );
      await tester.pumpAndSettle();

      final emptyTextFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((tf) => tf.controller?.text == '')
          .toList();
      expect(emptyTextFields.length, greaterThanOrEqualTo(2));
    });
  });

  group('EditPatientScreen – dropdown de nacionalidad', () {
    testWidgets('muestra "Colombia" cuando nationalityCode es COL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(nationalityCode: 'COL'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Colombia'), findsWidgets);
    });

    testWidgets('nationalityCode desconocido cae en COL sin romper el widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(nationalityCode: 'XXX'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsWidgets);
    });

    testWidgets('el usuario puede cambiar la nacionalidad a Venezuela', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(nationalityCode: 'COL'))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Colombia').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Venezuela').last);
      await tester.pumpAndSettle();

      expect(find.text('Venezuela'), findsWidgets);
    });

    testWidgets('el usuario puede cambiar la nacionalidad a Ecuador', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord(nationalityCode: 'COL'))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Colombia').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ecuador').last);
      await tester.pumpAndSettle();

      expect(find.text('Ecuador'), findsWidgets);
    });
  });

  group('EditPatientScreen – edición de campos de texto', () {
    testWidgets('el usuario puede editar el campo peso', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final weightField = find.widgetWithText(TextField, '58.0');
      await tester.tap(weightField);
      await tester.pumpAndSettle();
      await tester.enterText(weightField, '61.0');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '61.0'), findsOneWidget);
    });

    testWidgets('el usuario puede editar el campo altura', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final heightField = find.widgetWithText(TextField, '162.0');
      await tester.tap(heightField);
      await tester.pumpAndSettle();
      await tester.enterText(heightField, '165.0');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '165.0'), findsOneWidget);
    });

    testWidgets('el usuario puede editar el campo calle', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final streetField = find.widgetWithText(TextField, 'Calle 10 #20-30');
      await tester.tap(streetField);
      await tester.pumpAndSettle();
      await tester.enterText(streetField, 'Carrera 15 #30-40');
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Carrera 15 #30-40'),
        findsOneWidget,
      );
    });

    testWidgets('el usuario puede editar el campo ciudad', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final cityField = find.widgetWithText(TextField, 'Bogotá');
      await tester.tap(cityField);
      await tester.pumpAndSettle();
      await tester.enterText(cityField, 'Medellín');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Medellín'), findsOneWidget);
    });

    testWidgets('el usuario puede editar el campo departamento', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      final stateField = find.widgetWithText(TextField, 'Cundinamarca');
      await tester.tap(stateField);
      await tester.pumpAndSettle();
      await tester.enterText(stateField, 'Antioquia');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Antioquia'), findsOneWidget);
    });
  });

  group(
    'EditPatientScreen – botones de acción y verficación (v2-edit-patient-sin-verify)',
    () {
      testWidgets('el botón Volver dispara Navigator.pop', (tester) async {
        final spy = _PopSpy();
        await _pumpViaRoute(tester, _makeRecord(), spy);

        await tester.tap(find.byIcon(Icons.arrow_back_ios));
        await tester.pumpAndSettle();

        expect(spy.didPopCalled, isTrue);
      });

      testWidgets(
        'el botón Guardar dispara Navigator.pop y verifica persistencia',
        (tester) async {
          final spy = _PopSpy();
          final dbMock = MockLocalDatabase();
          final syncMock = MockSyncEngine();

          when(
            () => dbMock.savePatient(any<PatientFullRecord>()),
          ).thenAnswer((_) async {});
          when(
            () => dbMock.markChipsDirty(
              any<String>(),
              guardian: any<bool>(named: 'guardian'),
            ),
          ).thenAnswer((_) async {});
          when(() => syncMock.syncAll()).thenAnswer((_) async => true);

          await _pumpViaRoute(
            tester,
            _makeRecord(),
            spy,
            dbMock: dbMock,
            syncMock: syncMock,
          );

          await tester.tap(find.byIcon(Icons.save));
          await tester.pumpAndSettle();

          expect(spy.didPopCalled, isTrue);
          verify(() => dbMock.savePatient(any<PatientFullRecord>())).called(1);
          verify(
            () => dbMock.markChipsDirty('uuid-widget-test', guardian: true),
          ).called(1);
          verify(() => syncMock.syncAll()).called(1);
        },
      );

      testWidgets('Guardar conserva las listas clínicas del registro original '
          '(v2-edit-patient-sin-verify)', (tester) async {
        final dbMock = MockLocalDatabase();
        final syncMock = MockSyncEngine();

        when(
          () => dbMock.savePatient(any<PatientFullRecord>()),
        ).thenAnswer((_) async {});
        when(
          () => dbMock.markChipsDirty(
            any<String>(),
            guardian: any<bool>(named: 'guardian'),
          ),
        ).thenAnswer((_) async {});
        when(() => syncMock.syncAll()).thenAnswer((_) async => true);

        final original = PatientFullRecord(
          patientId: 'uuid-widget-test',
          deviceUid: 'NFC-WIDGET',
          patientInfo: _makeRecord().patientInfo,
          guardianInfo: _makeRecord().guardianInfo,
          guardian2Info: GuardianInfo(
            name: 'Segundo acudiente',
            relationship: 'Madre',
            phone: '3009998877',
          ),
          backgroundHistory: BackgroundHistory(
            personalHistory:
                'Antecedente relevante que no debe perderse al editar.',
          ),
          allergies: <AllergyInfo>[
            AllergyInfo(category: '01', allergen: 'Penicilina'),
          ],
          medicalHistory: <MedicalHistoryItem>[
            MedicalHistoryItem(startDateTime: '2026-07-30T10:00:00.000Z'),
          ],
          vaccinationRecord: <VaccinationRecordItem>[
            VaccinationRecordItem(
              date: '2026-07-30',
              vaccineName: 'BCG',
              vaccineCode: '19',
              dose: 1,
              administratedBy: 'Enfermera R.',
              administratedAt: 'IPS Sur',
            ),
          ],
        );

        final spy = _PopSpy();
        await _pumpViaRoute(
          tester,
          original,
          spy,
          dbMock: dbMock,
          syncMock: syncMock,
        );

        final weightField = find.widgetWithText(TextField, '58.0');
        await tester.tap(weightField);
        await tester.pumpAndSettle();
        await tester.enterText(weightField, '61.5');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        final saved =
            verify(() => dbMock.savePatient(captureAny())).captured.single
                as PatientFullRecord;

        expect(saved.patientInfo.weight, 61.5);
        expect(saved.allergies, hasLength(1));
        expect(saved.allergies.single.allergen, 'Penicilina');
        expect(saved.medicalHistory, hasLength(1));
        expect(saved.vaccinationRecord, hasLength(1));
        expect(saved.vaccinationRecord.single.vaccineName, 'BCG');
        expect(saved.backgroundHistory, original.backgroundHistory);
        expect(saved.guardian2Info, original.guardian2Info);

        verify(
          () => dbMock.markChipsDirty('uuid-widget-test', guardian: true),
        ).called(1);
      });

      testWidgets('el botón Volver muestra la etiqueta i18n correcta', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(EditPatientScreen(patient: _makeRecord())),
        );
        await tester.pumpAndSettle();

        expect(find.text(_s.back), findsOneWidget);
      });

      testWidgets('el botón Guardar muestra la etiqueta i18n correcta', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(EditPatientScreen(patient: _makeRecord())),
        );
        await tester.pumpAndSettle();

        expect(find.text(_s.save), findsOneWidget);
      });
    },
  );

  group('EditPatientScreen – locale inglés', () {
    testWidgets('renderiza sin errores en inglés', (tester) async {
      await tester.pumpWidget(
        _wrap(EditPatientScreen(patient: _makeRecord()), locale: 'en'),
      );
      await tester.pumpAndSettle();

      final sEn = AppStrings.forTesting('en');
      expect(find.text(sEn.patientInfoReadOnly), findsOneWidget);
      expect(find.text(sEn.save), findsOneWidget);
    });
  });

  group('EditPatientScreen – lifecycle', () {
    testWidgets('dispose no lanza excepciones', (tester) async {
      await tester.pumpWidget(_wrap(EditPatientScreen(patient: _makeRecord())));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });
  });
}
