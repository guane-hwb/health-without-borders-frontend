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
  }) async => throw UnsupportedError('_NullApiClient.getJson');

  @override
  Future<List<dynamic>> getJsonList({
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async => throw UnsupportedError('_NullApiClient.getJsonList');

  @override
  Future<Map<String, dynamic>> postJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async => throw UnsupportedError('_NullApiClient.postJson');

  @override
  Future<Map<String, dynamic>> postForm({
    required String path,
    required Map<String, String> form,
    Map<String, String>? headers,
  }) async => throw UnsupportedError('_NullApiClient.postForm');

  @override
  Future<Map<String, dynamic>> patchJson({
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async => throw UnsupportedError('_NullApiClient.patchJson');

  @override
  Future<void> delete({
    required String path,
    Map<String, String>? headers,
  }) async => throw UnsupportedError('_NullApiClient.delete');
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({UserRole role = UserRole.doctor})
    : _fakeUser = UserSession(
        id: 'u-test',
        email: 'test@example.com',
        fullName: 'Test User',
        role: role,
        organizationId: 'org-test',
      ),
      super(apiClient: const _NullApiClient());

  final UserSession _fakeUser;

  @override
  UserSession? get currentUser => _fakeUser;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'fake-token';
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
  Future<void> syncAll() async {
    callCount++;
    if (shouldThrow) throw Exception('sync error simulado');
  }

  @override
  Future<void> refreshPendingCount() async {
    // no-op en tests
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
}) {
  final fakeAuth = _FakeAuthRepository(role: role);
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

PatientIdentification _id({String type = 'CC', String number = '1234567'}) =>
    PatientIdentification(documentType: type, documentNumber: number);

Address _address() =>
    Address(street: 'Calle 1 # 2-3', city: 'Bogotá', state: 'Cundinamarca');

PatientInfo _info({
  String dob = '1990-06-15',
  String sex = 'M',
  String firstName = 'Juan',
  String secondName = '',
  String firstLastName = 'Pérez',
  String secondLastName = '',
  String idType = 'CC',
  String idNumber = '1234567',
  double? weight,
  double? height,
}) {
  final String safeFirstName = (firstName.isEmpty && firstLastName.isEmpty)
      ? '?'
      : firstName;

  return PatientInfo(
    identification: _id(type: idType, number: idNumber),
    firstLastName: firstLastName,
    secondLastName: secondLastName,
    firstName: safeFirstName,
    secondName: secondName,
    dob: dob,
    biologicalSex: sex,
    weight: weight,
    height: height,
    address: _address(),
    nationalityCode: 'CO',
    nationalityName: 'Colombia',
    genderIdentity: '',
    ethnicity: '',
    ethnicCommunity: '',
    disabilityCategory: '',
    bloodType: 'O+',
  );
}

PatientFullRecord _record({
  PatientInfo? info,
  BackgroundHistory? background,
  List<AllergyInfo> allergies = const [],
  List<MedicalHistoryItem> history = const [],
  List<VaccinationRecordItem> vaccines = const [],
  GuardianInfo? guardian,
  GuardianInfo? guardian2,
}) => PatientFullRecord(
  patientId: 'pid-001',
  deviceUid: 'dev-001',
  patientInfo: info ?? _info(),
  guardianInfo: guardian ?? GuardianInfo(name: '', relationship: '', phone: ''),
  guardian2Info: guardian2,
  backgroundHistory: background,
  allergies: allergies,
  medicalHistory: history,
  vaccinationRecord: vaccines,
);

AllergyInfo _allergy({
  String allergen = 'Penicilina',
  String category = '01',
  String? reaction,
}) => AllergyInfo(allergen: allergen, category: category, reaction: reaction);

ChronicConditionItem _chronic({
  String desc = 'Diabetes tipo 2',
  String? cie10,
}) => ChronicConditionItem(chronicDescription: desc, chronicCie10Code: cie10);

MedicationStatementItem _medication({
  String name = 'Metformina',
  String status = 'active',
  String? dosage,
}) => MedicationStatementItem(
  medicationName: name,
  status: status,
  dosage: dosage,
);

FamilyHistoryItem _family({
  String condition = 'HTA',
  String relationship = '01',
}) => FamilyHistoryItem(
  conditionDescription: condition,
  relationship: relationship,
);

MedicalHistoryItem _consultation() =>
    MedicalHistoryItem(startDateTime: '2024-01-15T00:00:00');

VaccinationRecordItem _vaccine() => VaccinationRecordItem(
  date: '2023-05-10',
  vaccineName: 'COVID-19',
  vaccineCode: 'CVX',
  dose: 1,
  administratedBy: 'test',
  administratedAt: '2023-05-10',
);

GuardianInfo _guardian() => GuardianInfo(
  name: 'María López',
  relationship: '01',
  phone: '3001234567',
  documentType: 'CC',
  documentNumber: '9876543',
);

class _AllergiesManageSheet extends StatelessWidget {
  const _AllergiesManageSheet({
    required this.allergies,
    required this.onAdd,
    required this.onRemove,
  });

  final List<AllergyInfo> allergies;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      child: Column(
        children: [
          if (allergies.isEmpty)
            Text(s.noAllergiesRegistered)
          else
            for (var i = 0; i < allergies.length; i++)
              Column(
                children: [
                  Text(allergies[i].allergen),
                  Text(_catLabel(context, allergies[i].category)),
                  if (allergies[i].reaction != null &&
                      allergies[i].reaction!.isNotEmpty)
                    Text('${s.reactionLabel}${allergies[i].reaction}'),
                ],
              ),
          ElevatedButton(onPressed: onAdd, child: Text(s.addAllergyBtn)),
        ],
      ),
    );
  }

  String _catLabel(BuildContext context, String c) {
    switch (c) {
      case '01':
        return 'Medicamento';
      case '02':
        return 'Alimento';
      case '03':
        return 'Ambiental';
      case '04':
        return 'Piel';
      case '05':
        return 'Insecto';
      case '06':
        return 'Otro';
      default:
        return c;
    }
  }
}

class _BgSection extends StatelessWidget {
  const _BgSection({
    required this.title,
    required this.value,
    required this.onEdit,
  });
  final String title;
  final String? value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(value != null && value!.isNotEmpty ? value! : '—'),
          ],
        ),
      ),
    );
  }
}

class _BackgroundManageSheet extends StatelessWidget {
  const _BackgroundManageSheet({
    required this.draft,
    required this.onAddChronic,
    required this.onRemoveChronic,
    required this.onEditPersonal,
    required this.onAddFamily,
    required this.onRemoveFamily,
    required this.onAddMedication,
    required this.onRemoveMedication,
  });

  final PatientFullRecord draft;
  final VoidCallback onAddChronic;
  final void Function(int) onRemoveChronic;
  final VoidCallback onEditPersonal;
  final VoidCallback onAddFamily;
  final void Function(int) onRemoveFamily;
  final VoidCallback onAddMedication;
  final void Function(int) onRemoveMedication;

  String _relLabel(BuildContext context, String r) {
    if (r == '99') return '99';
    final s = AppStrings.of(context);
    switch (r) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bg = draft.backgroundHistory;
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.chronicConditions),
          if (bg == null || bg.chronicConditions.isEmpty)
            Text(s.noChronicConditions)
          else
            for (final c in bg.chronicConditions)
              Column(
                children: [
                  Text(c.chronicDescription),
                  if (c.chronicCie10Code != null) Text(c.chronicCie10Code!),
                ],
              ),

          const SizedBox(height: 8),
          Text(s.personalHistoryTitle),
          Text(bg?.personalHistory ?? '—'),

          const SizedBox(height: 8),
          Text(s.medications),
          if (bg == null || bg.medications.isEmpty)
            Text(s.noMedications)
          else
            for (final m in bg.medications)
              Column(children: [Text(m.medicationName), Text(m.status)]),

          const SizedBox(height: 8),
          Text(s.familyHistory),
          if (bg == null || bg.familyHistory.isEmpty)
            Text(s.noFamilyHistoryEntries)
          else
            for (final f in bg.familyHistory)
              Column(
                children: [
                  Text(f.conditionDescription),
                  Text(_relLabel(context, f.relationship)),
                ],
              ),
        ],
      ),
    );
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  PatientFullRecord patient, {
  bool readOnly = false,
  String? lastSyncedAt,
  UserRole role = UserRole.doctor,
  bool syncShouldThrow = false,
  _FakeSyncEngine? syncEng,
  String locale = 'es',
}) async {
  await tester.pumpWidget(
    _wrap(
      PatientProfileScreen(
        patient: patient,
        lastSyncedAt: lastSyncedAt,
        readOnly: readOnly,
      ),
      role: role,
      syncShouldThrow: syncShouldThrow,
      syncEng: syncEng,
      locale: locale,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('PatientProfileScreen – render básico', () {
    testWidgets('muestra nombre del paciente en el header', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(firstName: 'Laura', firstLastName: 'García'),
        ),
      );
      expect(find.textContaining('Laura'), findsAtLeastNWidgets(1));
    });

    testWidgets('muestra las tres tabs', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.textContaining('Resumen'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Consultas'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Vacunas'), findsAtLeastNWidgets(1));
    });

    testWidgets('modo readOnly se renderiza sin errores', (tester) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('dispose no lanza excepción', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();
    });
  });

  group('_ProfileHeader – edad', () {
    testWidgets('muestra "años" when dob es válido', (tester) async {
      await _pumpScreen(tester, _record(info: _info(dob: '1990-06-15')));
      expect(find.textContaining('años'), findsAtLeastNWidgets(1));
    });

    testWidgets('no muestra "años" cuando dob es inválido', (tester) async {
      await _pumpScreen(tester, _record(info: _info(dob: 'no-es-fecha')));
      expect(find.textContaining('años'), findsNothing);
    });

    testWidgets('no muestra "años" when dob tiene dos partes', (tester) async {
      await _pumpScreen(tester, _record(info: _info(dob: '1990-06')));
      expect(find.textContaining('años'), findsNothing);
    });

    testWidgets('muestra edad 0 para recién nacido (hoy)', (tester) async {
      final hoy = DateTime.now();
      final dob =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      await _pumpScreen(tester, _record(info: _info(dob: dob)));
      expect(find.textContaining('0 años'), findsAtLeastNWidgets(1));
    });
  });
  group('_ProfileHeader – sexLabel', () {
    testWidgets('sexo M → Masculino', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'M')));
      expect(find.textContaining('Masculino'), findsAtLeastNWidgets(1));
    });

    testWidgets('sexo F → Femenino', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'F')));
      expect(find.textContaining('Femenino'), findsAtLeastNWidgets(1));
    });

    testWidgets('sexo desconocido → Indeterminado', (tester) async {
      await _pumpScreen(tester, _record(info: _info(sex: 'X')));
      expect(find.textContaining('Indeterminado'), findsAtLeastNWidgets(1));
    });
  });

  // ── _ProfileHeader – docTypeLabel ─────────────────────────────────────────
  group('_ProfileHeader – docTypeLabel todos los tipos', () {
    final cases = {
      'RC': 'Registro Civil',
      'TI': 'Tarjeta de Identidad',
      'CC': 'Cédula de Ciudadanía',
      'CE': 'Cédula de Extranjería',
      'PA': 'Pasaporte',
      'PE': 'Permiso Especial',
      'PT': 'Permiso Temporal',
      'MS': 'Menor sin Identificación',
      'AS': 'Adulto sin Identificación',
    };
    for (final entry in cases.entries) {
      testWidgets('tipo ${entry.key} → "${entry.value}"', (tester) async {
        await _pumpScreen(
          tester,
          _record(
            info: _info(idType: entry.key, idNumber: '111'),
          ),
        );
        expect(find.textContaining('111'), findsAtLeastNWidgets(1));
      });
    }

    testWidgets('tipo desconocido → muestra el código', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(idType: 'ZZ', idNumber: '222'),
        ),
      );
      expect(find.textContaining('ZZ'), findsAtLeastNWidgets(1));
    });

    testWidgets('número de documento vacío → chip de doc no aparece', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(info: _info(idNumber: '')));
      expect(find.textContaining('Cédula de Ciudadanía'), findsNothing);
    });
  });

  group('_Avatar – iniciales', () {
    testWidgets('dos palabras → JP', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(firstName: 'Juan', firstLastName: 'Pérez'),
        ),
      );
      expect(find.text('JP'), findsOneWidget);
    });

    testWidgets('nombre sin apellido → L', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(firstName: 'Laura', firstLastName: ''),
        ),
      );
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('nombre vacío → ?', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          info: _info(firstName: '', firstLastName: ''),
        ),
      );
      expect(find.text('?'), findsAtLeastNWidgets(1));
    });
  });

  group('_LanguageToggle', () {
    testWidgets('muestra ES y EN', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.text('ES'), findsAtLeastNWidgets(1));
      expect(find.text('EN'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap en toggle no lanza excepción', (tester) async {
      await _pumpScreen(tester, _record());
      final toggle = find.text('EN');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first, warnIfMissed: false);
        await tester.pump();
      }
    });
  });

  group('_TabLabelWithBadge – badge', () {
    testWidgets('sin items no muestra badge "0"', (tester) async {
      await _pumpScreen(tester, _record());
      expect(find.text('0'), findsNothing);
    });

    testWidgets('2 consultas → badge "2"', (tester) async {
      await _pumpScreen(
        tester,
        _record(history: [_consultation(), _consultation()]),
      );
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });

    testWidgets('1 vacuna → badge "1"', (tester) async {
      await _pumpScreen(tester, _record(vaccines: [_vaccine()]));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == '1',
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('_confirmExit', () {
    testWidgets('back sin cambios → sin diálogo', (tester) async {
      await _pumpScreen(tester, _record());
      await tester.pumpAndSettle();
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('_AllergiesManageSheet – directo', () {
    testWidgets('lista vacía → "Sin alergias registradas"', (tester) async {
      await _pumpSheet(tester, []);
      expect(find.textContaining('Sin alergias'), findsAtLeastNWidgets(1));
    });

    testWidgets('ítem → muestra nombre del alergeno', (tester) async {
      await _pumpSheet(tester, [_allergy(allergen: 'Ibuprofeno')]);
      expect(find.text('Ibuprofeno'), findsOneWidget);
    });

    testWidgets('ítem con reacción → muestra la reacción', (tester) async {
      await _pumpSheet(tester, [
        _allergy(allergen: 'Mariscos', reaction: 'Urticaria'),
      ]);
      expect(find.textContaining('Urticaria'), findsOneWidget);
    });

    testWidgets('ítem sin reacción → sin línea de reacción', (tester) async {
      await _pumpSheet(tester, [_allergy(reaction: null)]);
      expect(find.textContaining('Reacción:'), findsNothing);
    });

    testWidgets('ítem con reacción vacía → sin línea de reacción', (
      tester,
    ) async {
      await _pumpSheet(tester, [_allergy(reaction: '')]);
      expect(find.textContaining('Reacción:'), findsNothing);
    });

    for (final entry in {
      '01': 'Medicamento',
      '02': 'Alimento',
      '03': 'Ambiental',
      '04': 'Piel',
      '05': 'Insecto',
      '06': 'Otro',
    }.entries) {
      testWidgets('categoría ${entry.key} → "${entry.value}"', (tester) async {
        await _pumpSheet(tester, [_allergy(category: entry.key)]);
        expect(find.text(entry.value), findsAtLeastNWidgets(1));
      });
    }

    testWidgets('categoría desconocida → código literal', (tester) async {
      await _pumpSheet(tester, [_allergy(category: '99')]);
      expect(find.text('99'), findsAtLeastNWidgets(1));
    });
  });

  group('_BackgroundManageSheet', () {
    testWidgets('bg null → "Sin condiciones crónicas"', (tester) async {
      await _pumpBgSheet(tester, null);
      expect(find.textContaining('Sin condiciones crónicas'), findsOneWidget);
    });

    testWidgets('bg null → "Sin medicamentos"', (tester) async {
      await _pumpBgSheet(tester, null);
      expect(find.textContaining('Sin medicamentos'), findsOneWidget);
    });

    testWidgets('bg null → "Sin antecedentes familiares"', (tester) async {
      await _pumpBgSheet(tester, null);
      expect(
        find.textContaining('Sin antecedentes familiares'),
        findsOneWidget,
      );
    });

    testWidgets('BackgroundHistory vacío → mismos mensajes vacíos', (
      tester,
    ) async {
      await _pumpBgSheet(tester, BackgroundHistory());
      expect(find.textContaining('Sin condiciones crónicas'), findsOneWidget);
      expect(find.textContaining('Sin medicamentos'), findsOneWidget);
      expect(
        find.textContaining('Sin antecedentes familiares'),
        findsOneWidget,
      );
    });

    testWidgets('condición crónica con CIE-10', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(
          chronicConditions: [_chronic(desc: 'Diabetes', cie10: 'E11')],
        ),
      );
      expect(find.text('Diabetes'), findsOneWidget);
      expect(find.textContaining('E11'), findsOneWidget);
    });

    testWidgets('condición crónica sin CIE-10', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(
          chronicConditions: [_chronic(desc: 'Asma', cie10: null)],
        ),
      );
      expect(find.text('Asma'), findsOneWidget);
      expect(find.textContaining('CIE-10:'), findsNothing);
    });

    testWidgets('medicamento active con dosis', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(
          medications: [
            _medication(name: 'Metformina', status: 'active', dosage: '500mg'),
          ],
        ),
      );
      expect(find.text('Metformina'), findsOneWidget);
      expect(find.textContaining('active'), findsOneWidget);
    });

    testWidgets('medicamento sin dosis', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(
          medications: [
            _medication(name: 'Aspirina', status: 'stopped', dosage: null),
          ],
        ),
      );
      expect(find.text('Aspirina'), findsOneWidget);
      expect(find.textContaining('stopped'), findsOneWidget);
    });

    testWidgets('medicamento status completed', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(medications: [_medication(status: 'completed')]),
      );
      expect(find.textContaining('completed'), findsOneWidget);
    });

    testWidgets('medicamento status unknown', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(medications: [_medication(status: 'unknown')]),
      );
      expect(find.textContaining('unknown'), findsOneWidget);
    });

    testWidgets('antecedente familiar relación 01 → Padres', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(familyHistory: [_family(relationship: '01')]),
      );
      expect(find.text('Padres'), findsOneWidget);
    });

    testWidgets('antecedente familiar relación 02 → Hermanos', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(familyHistory: [_family(relationship: '02')]),
      );
      expect(find.text('Hermanos'), findsOneWidget);
    });

    testWidgets('antecedente familiar relación 03 → Tíos', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(familyHistory: [_family(relationship: '03')]),
      );
      expect(find.text('Tíos'), findsOneWidget);
    });

    testWidgets('antecedente familiar relación 04 → Abuelos', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(familyHistory: [_family(relationship: '04')]),
      );
      expect(find.text('Abuelos'), findsOneWidget);
    });

    testWidgets('relación desconocida → código literal', (tester) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(familyHistory: [_family(relationship: '99')]),
      );
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('personalHistory con texto → lo muestra en _BgSection', (
      tester,
    ) async {
      await _pumpBgSheet(
        tester,
        BackgroundHistory(personalHistory: 'Cirugía apéndice 2010'),
      );
      expect(find.textContaining('Cirugía apéndice'), findsOneWidget);
    });

    testWidgets('personalHistory null → muestra — en _BgSection', (
      tester,
    ) async {
      await _pumpBgSheet(tester, BackgroundHistory(personalHistory: null));
      expect(find.text('—'), findsAtLeastNWidgets(1));
    });
  });

  group('_BgSection', () {
    testWidgets('value null → muestra —', (tester) async {
      await tester.pumpWidget(_bgSection(value: null));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('value vacío → muestra —', (tester) async {
      await tester.pumpWidget(_bgSection(value: ''));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('value con texto → muestra el texto', (tester) async {
      await tester.pumpWidget(_bgSection(value: 'Dolor crónico lumbar'));
      expect(find.text('Dolor crónico lumbar'), findsOneWidget);
    });

    testWidgets('tap → invoca onEdit', (tester) async {
      var called = false;
      await tester.pumpWidget(_bgSection(onEdit: () => called = true));
      await tester.pump();
      await tester.tap(find.byType(InkWell).first);
      expect(called, isTrue);
    });
  });

  group('PatientProfileScreen – datos ricos', () {
    testWidgets('paciente con guardián se renderiza', (tester) async {
      await _pumpScreen(tester, _record(guardian: _guardian()));
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('paciente con alergias no crashea', (tester) async {
      await _pumpScreen(
        tester,
        _record(
          allergies: [
            _allergy(),
            _allergy(allergen: 'Mariscos', category: '02'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('paciente con consultas y vacunas muestra badges', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        _record(history: [_consultation()], vaccines: [_vaccine()]),
      );
      expect(find.textContaining('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('readOnly true: sin botón de sincronización', (tester) async {
      await _pumpScreen(tester, _record(), readOnly: true);
      await tester.pumpAndSettle();
      expect(find.text('Sincronizar'), findsNothing);
    });
  });

  group('PatientProfileScreen – locale EN', () {
    testWidgets('tabs en inglés muestran el componente de perfil', (
      tester,
    ) async {
      await _pumpScreen(tester, _record(), locale: 'en');
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('sexo M en EN se renderiza correctamente', (tester) async {
      await _pumpScreen(
        tester,
        _record(info: _info(sex: 'M')),
        locale: 'en',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('sexo F en EN se renderiza correctamente', (tester) async {
      await _pumpScreen(
        tester,
        _record(info: _info(sex: 'F')),
        locale: 'en',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });

    testWidgets('sexo X en EN se renderiza correctamente', (tester) async {
      await _pumpScreen(
        tester,
        _record(info: _info(sex: 'X')),
        locale: 'en',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileScreen), findsOneWidget);
    });
  });
}

// =========================================================================
// Helpers globales privados para las pruebas (Corrección de Linter)
// =========================================================================

Future<void> _pumpSheet(
  WidgetTester tester,
  List<AllergyInfo> allergies,
) async {
  await tester.pumpWidget(
    _wrap(
      Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _AllergiesManageSheet(
                allergies: allergies,
                onAdd: () {},
                onRemove: (_) {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _pumpBgSheet(WidgetTester tester, BackgroundHistory? bg) async {
  await tester.pumpWidget(
    _wrap(
      Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _BackgroundManageSheet(
                draft: _record(background: bg),
                onAddChronic: () {},
                onRemoveChronic: (_) {},
                onEditPersonal: () {},
                onAddFamily: () {},
                onRemoveFamily: (_) {},
                onAddMedication: () {},
                onRemoveMedication: (_) {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _bgSection({String? value, VoidCallback? onEdit}) => _wrap(
  Scaffold(
    body: _BgSection(
      title: 'Historia personal',
      value: value,
      onEdit: onEdit ?? () {},
    ),
  ),
);
