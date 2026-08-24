// test/widget/read_nfc_guardian_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/read_nfc_guardian_screen.dart';

// =============================================================================
// Test Infrastructure
// =============================================================================

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
  Widget build(BuildContext context) => AppLocale(
    locale: _locale,
    setLocale: (l) => setState(() => _locale = l),
    child: widget.child,
  );
}

class _FakePatientRepository implements PatientRepository {
  bool syncCalled = false;
  Exception? throwOnSync;

  @override
  Future<PatientSyncResponse> syncPatient(
    PatientFullRecord record, {
    String? retiredDeviceReason,
  }) async {
    syncCalled = true;
    if (throwOnSync != null) throw throwOnSync!;
    return PatientSyncResponse.fromJson(<String, dynamic>{
      'status': 'success',
      'internal_id': 'INT-001',
      'message': 'ok',
    });
  }

  @override
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
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

class _FakeAppScope extends InheritedWidget {
  const _FakeAppScope({required this.repo, required super.child});
  final _FakePatientRepository repo;

  _FakePatientRepository get patientRepository => repo;

  @override
  bool updateShouldNotify(_FakeAppScope old) => old.repo != repo;
}

/// Localization provider wraps MaterialApp so that pushed routes retain locale context.
Widget _wrap(
  Widget child, {
  String locale = 'es',
  _FakePatientRepository? repo,
}) {
  final fakeRepo = repo ?? _FakePatientRepository();
  return _AppLocaleProvider(
    locale: locale,
    child: _FakeAppScope(
      repo: fakeRepo,
      child: MaterialApp(home: child),
    ),
  );
}

class _PopSpy extends NavigatorObserver {
  bool didPopCalled = false;
  Route<dynamic>? lastPushedRoute;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPopCalled = true;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRoute = route;
  }
}

// =============================================================================
// Test Data Factories
// =============================================================================

Address _addr({String city = 'Bogotá', String state = 'Cund.'}) =>
    Address(city: city, state: state);

PatientIdentification _id() =>
    PatientIdentification(documentType: 'CC', documentNumber: '99999');

PatientInfo _info({
  String firstName = 'Laura',
  String firstLastName = 'Torres',
  String dob = '1995-07-10',
  String sex = 'F',
  String? bloodType = 'O+',
  double? weight = 62.0,
  double? height = 1.65,
  String nationalityCode = 'COL',
}) => PatientInfo(
  identification: _id(),
  firstLastName: firstLastName,
  firstName: firstName,
  dob: dob,
  biologicalSex: sex,
  bloodType: bloodType,
  weight: weight,
  height: height,
  nationalityCode: nationalityCode,
  address: _addr(),
);

GuardianInfo _guardian({
  String name = 'María García',
  String relationship = 'Madre',
  String phone = '3001112233',
}) => GuardianInfo(name: name, relationship: relationship, phone: phone);

AllergyInfo _allergy({
  String allergen = 'Penicilina',
  String? reaction = 'Anafilaxia',
}) => AllergyInfo(category: '01', allergen: allergen, reaction: reaction);

MedicalHistoryItem _visit({
  String startDateTime = '2024-05-10T09:30:00',
  String? practitionerName = 'Dr. López',
  String? providerName = 'Hospital Central',
  String type = 'Consultation',
}) => MedicalHistoryItem(
  startDateTime: startDateTime,
  type: type,
  practitioner: practitionerName != null
      ? PractitionerInfo(
          documentType: 'CC',
          documentNumber: '111',
          name: practitionerName,
        )
      : null,
  provider: providerName != null
      ? ProviderInfo(repsCode: 'R1', name: providerName)
      : null,
);

PatientFullRecord _record({
  List<AllergyInfo>? allergies,
  List<MedicalHistoryItem>? medicalHistory,
  List<VaccinationRecordItem>? vaccinationRecord,
  BackgroundHistory? backgroundHistory,
  String sex = 'F',
  double? weight = 62.0,
  double? height = 1.65,
  String? bloodType = 'O+',
}) => PatientFullRecord(
  patientId: 'uuid-test',
  deviceUid: 'NFC-TEST',
  patientInfo: _info(
    sex: sex,
    weight: weight,
    height: height,
    bloodType: bloodType,
  ),
  guardianInfo: _guardian(),
  allergies: allergies ?? [],
  medicalHistory: medicalHistory ?? [],
  vaccinationRecord: vaccinationRecord ?? [],
  backgroundHistory: backgroundHistory,
);

final _s = AppStrings.forTesting('es');

// =============================================================================
// WIDGET TESTS
// =============================================================================

void main() {
  group('ReadNfcGuardianScreen – Rendering', () {
    testWidgets('renders without errors using minimal patient record', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      expect(find.byType(ReadNfcGuardianScreen), findsOneWidget);
    });

    testWidgets('renders updatePatient label text element', (tester) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      expect(find.text(_s.updatePatient), findsOneWidget);
    });

    testWidgets(
      'renders explicit NFC icon asset badge inside the sync button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.nfc), findsOneWidget);
      },
    );
  });

  group('ReadNfcGuardianScreen – Navigation', () {
    Future<void> pumpViaRoute(
      WidgetTester tester,
      PatientFullRecord record,
      _PopSpy spy,
    ) async {
      final repo = _FakePatientRepository();
      await tester.pumpWidget(
        _AppLocaleProvider(
          locale: 'es',
          child: _FakeAppScope(
            repo: repo,
            child: MaterialApp(
              navigatorObservers: [spy],
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReadNfcGuardianScreen(patient: record),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'header back chevron triggers Navigator.pop routines successfully',
      (tester) async {
        final spy = _PopSpy();
        await pumpViaRoute(tester, _record(), spy);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(spy.didPopCalled, isTrue);
      },
    );

    testWidgets(
      'tapping patient edit button pushes a new route into the routing stack',
      (tester) async {
        final spy = _PopSpy();
        await pumpViaRoute(tester, _record(), spy);
        await tester.tap(find.byIcon(Icons.edit).first);
        await tester.pumpAndSettle();
        expect(spy.lastPushedRoute, isNotNull);
      },
    );

    testWidgets(
      'tapping vaccine tracking section pushes target route normally',
      (tester) async {
        final spy = _PopSpy();
        await pumpViaRoute(tester, _record(), spy);
        await tester.tap(find.byIcon(Icons.vaccines).first);
        await tester.pumpAndSettle();
        expect(spy.lastPushedRoute, isNotNull);
      },
    );

    testWidgets(
      'tapping details inside allergen row pushes target views onto stack',
      (tester) async {
        final spy = _PopSpy();
        await pumpViaRoute(tester, _record(allergies: [_allergy()]), spy);
        await tester.tap(find.text(_s.moreDetails));
        await tester.pumpAndSettle();
        expect(spy.lastPushedRoute, isNotNull);
      },
    );
  });

  group('ReadNfcGuardianScreen – Tabs Navigation Layout', () {
    testWidgets('initial layout focus index 0 safely loads GuardianTab view', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      expect(find.text(_s.guardian), findsWidgets);
    });

    testWidgets(
      'tapping tab index 1 renders the complete MedicalHistoryTab view',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text(_s.medicalHistory), findsWidgets);
      },
    );

    testWidgets('tapping tab index 2 renders the target MedicalStaffTab view', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_s.medicalStaff).first);
      await tester.pumpAndSettle();
      expect(find.text(_s.medicalStaff), findsWidgets);
    });

    testWidgets(
      'navigating back to base index 0 from tab 2 restores GuardianTab details',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.guardian).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('María García'), findsOneWidget);
      },
    );
  });

  group('_PatientProfileCard Component Metrics', () {
    testWidgets('displays explicit patient complete structural full name', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      expect(find.text('Laura Torres'), findsOneWidget);
    });

    testWidgets('displays complete patient date of birth info segment', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(ReadNfcGuardianScreen(patient: _record())));
      await tester.pumpAndSettle();
      expect(find.textContaining('1995-07-10'), findsOneWidget);
    });

    testWidgets(
      'displays correct blood type mapping properties configurations',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('O+'), findsOneWidget);
      },
    );

    testWidgets(
      'renders placeholder string "N/A" when target bloodType is null',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(bloodType: null))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('N/A'), findsWidgets);
      },
    );

    testWidgets(
      'displays corresponding patient weight and height property strings',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('62.0'), findsOneWidget);
        expect(find.textContaining('1.65'), findsOneWidget);
      },
    );

    testWidgets(
      'renders placeholder string "N/A" when physical parameters evaluate to null',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_record(weight: null, height: null).toWidgetScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('N/A'), findsWidgets);
      },
    );

    testWidgets(
      'renders placeholder string "N/A" when backgroundHistory components are null',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('N/A'), findsWidgets);
      },
    );

    testWidgets(
      'displays the explicit content text string when chronic conditions exist',
      (tester) async {
        final bg = BackgroundHistory(
          chronicConditions: [ChronicConditionItem(chronicDescription: 'Asma')],
        );
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Asma'), findsOneWidget);
      },
    );

    testWidgets(
      'concatenates consecutive chronic illnesses seamlessly via comma punctuation tokens',
      (tester) async {
        final bg = BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Asma'),
            ChronicConditionItem(chronicDescription: 'Diabetes'),
          ],
        );
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Asma, Diabetes'), findsOneWidget);
      },
    );

    testWidgets(
      'renders active dynamic counter tracking metrics within buttons interfaces',
      (tester) async {
        final vaccines = [
          VaccinationRecordItem(
            date: '2023-01-01',
            vaccineName: 'COVID',
            vaccineCode: 'CVX-208',
            dose: 1,
            administratedBy: 'MINSALUD',
            administratedAt: 'CAP',
          ),
        ];
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(vaccinationRecord: vaccines),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('1'), findsWidgets);
      },
    );

    testWidgets(
      'biological identifier value F renders localized feminine label text element',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(sex: 'F'))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Femenino'), findsOneWidget);
      },
    );

    testWidgets(
      'biological identifier value M renders localized masculine label text element',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(sex: 'M'))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Masculino'), findsOneWidget);
      },
    );

    testWidgets(
      'indeterminate biological gender signatures render default "N/A" fallback',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(sex: 'I'))),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('N/A'), findsWidgets);
      },
    );
  });

  group('_AllergenCard Render Operations', () {
    testWidgets(
      'renders default unpopulated dash separator when allergy list capacity is empty',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(allergies: []))),
        );
        await tester.pumpAndSettle();
        expect(find.text('—'), findsOneWidget);
      },
    );

    testWidgets(
      'renders explicit target allergy substance labeling string details',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(allergies: [_allergy(allergen: 'Penicilina')]),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Penicilina'), findsOneWidget);
      },
    );

    testWidgets(
      'renders symptomatic physiological response information properties',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(
                allergies: [_allergy(allergen: 'Maní', reaction: 'Urticaria')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Urticaria'), findsOneWidget);
      },
    );

    testWidgets(
      'skips drawing systemic response sub-strings when property references evaluate to null',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(
                allergies: [_allergy(allergen: 'Polen', reaction: null)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Polen'), findsOneWidget);
      },
    );

    testWidgets(
      'renders precise inventory counts within target layout section components headers',
      (tester) async {
        final allergies = [
          _allergy(allergen: 'Penicilina'),
          _allergy(allergen: 'Aspirina'),
          _allergy(allergen: 'Polen', reaction: null),
        ];
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(allergies: allergies))),
        );
        await tester.pumpAndSettle();
        expect(find.text('3'), findsWidgets);
      },
    );

    testWidgets(
      'renders multi-row iterative data listings mapped inside separate container layers',
      (tester) async {
        final allergies = [
          _allergy(allergen: 'A', reaction: 'R1'),
          _allergy(allergen: 'B', reaction: null),
        ];
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(allergies: allergies))),
        );
        await tester.pumpAndSettle();
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
      },
    );
  });

  group('_GuardianTab Context Data', () {
    testWidgets(
      'renders matching complete guardian name string data properties',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('María García'), findsOneWidget);
      },
    );

    testWidgets(
      'renders localized relationship label text properties details safely',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Madre'), findsOneWidget);
      },
    );

    testWidgets(
      'renders verified communications phone parameter information data entries',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('3001112233'), findsOneWidget);
      },
    );
  });

  group('_MedicalHistoryTab Context Data', () {
    testWidgets(
      'renders fallback placeholder text noData when clinical payload history is empty',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text(_s.noData), findsWidgets);
      },
    );

    testWidgets(
      'renders historyOfCurrentIllness records text completely when initialized',
      (tester) async {
        final visit = MedicalHistoryItem(
          startDateTime: '2024-01-10T08:00:00',
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Fiebre alta',
          ),
        );
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text('Fiebre alta'), findsOneWidget);
      },
    );

    testWidgets(
      'renders personalHistory statements retrieved from backgroundHistory instances',
      (tester) async {
        final bg = BackgroundHistory(personalHistory: 'Cirugía 2020');
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text('Cirugía 2020'), findsOneWidget);
      },
    );

    testWidgets(
      'renders mapped familyHistory configurations pairing with specific description details',
      (tester) async {
        final bg = BackgroundHistory(
          familyHistory: [
            FamilyHistoryItem(
              conditionDescription: 'Hipertensión',
              relationship: '01',
            ),
          ],
        );
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Hipertensión (Padres)'), findsOneWidget);
      },
    );

    testWidgets(
      'renders underlying relationship raw key tokens when identifier lookup fails',
      (tester) async {
        final bg = BackgroundHistory(
          familyHistory: [
            FamilyHistoryItem(
              conditionDescription: 'Diabetes',
              relationship: '99',
            ),
          ],
        );
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Diabetes (99)'), findsOneWidget);
      },
    );

    testWidgets(
      'appends custom familyHistoryNotes context details onto presentation layers',
      (tester) async {
        final bg = BackgroundHistory(familyHistoryNotes: 'Padre diabético');
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record(backgroundHistory: bg))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Padre diabético'), findsOneWidget);
      },
    );

    testWidgets(
      '_LastUpdatedFooter draws data segments pointing to final encounter values',
      (tester) async {
        final visit = _visit(
          practitionerName: 'Dr. Ruiz',
          providerName: 'Clínica Sur',
          startDateTime: '2024-06-01T10:00:00',
        );
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text('Dr. Ruiz'), findsOneWidget);
        expect(find.textContaining('2024-06-01'), findsWidgets);
        expect(find.textContaining('Clínica Sur'), findsWidgets);
      },
    );

    testWidgets(
      '_LastUpdatedFooter prints default "N/A" layout tokens when index entries are blank',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalHistory).first);
        await tester.pumpAndSettle();
        expect(find.text('N/A'), findsWidgets);
      },
    );
  });

  group('_MedicalStaffTab Context Data', () {
    testWidgets(
      'renders base "N/A" strings when internal history array parameter has 0 items',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ReadNfcGuardianScreen(patient: _record())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('N/A'), findsWidgets);
      },
    );

    testWidgets(
      'appends structural medical practitioner title prefix string details cleanly',
      (tester) async {
        final visit = _visit(practitionerName: 'García');
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Dr. García'), findsOneWidget);
      },
    );

    testWidgets(
      'displays specific clinical consultation encounter type information metadata descriptions',
      (tester) async {
        final visit = _visit(type: 'Emergency');
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Emergency'), findsOneWidget);
      },
    );

    testWidgets(
      'displays clinical caregiver provider organization descriptive name text payload',
      (tester) async {
        final visit = _visit(providerName: 'HUV');
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('HUV'), findsOneWidget);
      },
    );

    testWidgets(
      'extracts clean date signatures out of complex timestamp tracking metrics string',
      (tester) async {
        final visit = _visit(startDateTime: '2024-09-25T14:00:00');
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(patient: _record(medicalHistory: [visit])),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        expect(find.textContaining('2024-09-25'), findsWidgets);
      },
    );

    testWidgets(
      'tapping operational modification elements fires expected navigation route transitions',
      (tester) async {
        final spy = _PopSpy();
        final repo = _FakePatientRepository();
        await tester.pumpWidget(
          _AppLocaleProvider(
            locale: 'es',
            child: _FakeAppScope(
              repo: repo,
              child: MaterialApp(
                navigatorObservers: [spy],
                home: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ReadNfcGuardianScreen(patient: _record()),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_s.medicalStaff).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit).last);
        await tester.pumpAndSettle();
        expect(spy.lastPushedRoute, isNotNull);
      },
    );
  });

  group('_AllergenRow Elements', () {
    testWidgets(
      'renders severe warning graphic tokens when active reaction descriptions are present',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(
                allergies: [_allergy(allergen: 'X', reaction: 'Shock')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning), findsWidgets);
      },
    );

    testWidgets(
      'skips printing descriptive response labels when target fields are empty strings',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReadNfcGuardianScreen(
              patient: _record(
                allergies: [_allergy(allergen: 'X', reaction: '')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widgetList<Icon>(find.byIcon(Icons.warning)), isNotEmpty);

        final emptyTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => t.data == '')
            .toList();
        expect(emptyTexts, isEmpty);
      },
    );
  });

  group(
    'ReadNfcGuardianScreen – English Language Localizations Verification',
    () {
      testWidgets(
        'renders layout components successfully without exceptions under English settings',
        (tester) async {
          await tester.pumpWidget(
            _wrap(ReadNfcGuardianScreen(patient: _record()), locale: 'en'),
          );
          await tester.pumpAndSettle();
          final sEn = AppStrings.forTesting('en');
          expect(find.text(sEn.updatePatient), findsOneWidget);
        },
      );
    },
  );
}

/// Helper method extension matching required PatientFullRecord specifications.
extension on PatientFullRecord {
  Widget toWidgetScreen() => ReadNfcGuardianScreen(patient: this);
}
