// test/widget/edit_medical_history_screen_widget_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:health_without_borders_frontend/src/features/nfc/presentation/edit_medical_history_screen.dart';

// -----------------------------------------------------------------------------
// FAKES
// -----------------------------------------------------------------------------

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  @override
  UserSession? get currentUser => null;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async => UserSession.fromEmail(email);

  @override
  Future<UserSession?> getCurrentUser() async => null;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'test-token';

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<UserSession?> restoreSession() async => null;

  @override
  ValueListenable<bool> get sessionExpired => ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get sessionWindowClosed =>
      ValueNotifier<bool>(false);

  @override
  Future<String?> getNfcEncryptionKey() async => 'fake-nfc-key-12345';

  @override
  Future<Null> getNfcKeyring() async => null;

  @override
  Future<bool> isNfcSessionExpired() async => false;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> logout({bool wipeLocalData = false}) async {}

  @override
  Future<bool> wipeLocalPhi({bool force = false}) async => true;

  @override
  bool get hasToken => false;

  @override
  ValueNotifier<UserSession?> get sessionNotifier =>
      ValueNotifier<UserSession?>(null);

  @override
  VoidCallback? onSessionInvalidated;

  @override
  Future<void> discardForeignPendingData() async {}

  @override
  Future<List<Map<String, Object?>>>
  pendingForeignEmergencyLogsForReview() async => <Map<String, Object?>>[];

  @override
  Future<List<LocalPatientEntry>> pendingForeignRecordsForReview() async =>
      <LocalPatientEntry>[];
}

class FakeLocalDatabase implements LocalDatabase {
  @override
  Future<void> logEmergencyAccess({
    required String patientUid,
    String? patientName,
    String? userId,
    String reason = 'guardian_absent_offline',
    String? ownerUserId,
    String? organizationId,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> pendingEmergencyAccessLogs({
    String? ownerUserId,
  }) async => <Map<String, Object?>>[];

  @override
  Future<int> getUnsyncedEmergencyLogCount({String? ownerUserId}) async => 0;

  @override
  Future<int> getOrphanedEmergencyLogCount() async => 0;

  @override
  Future<int> getOrphanedPendingCount() async => 0;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> deleteRecord(String patientId) async {}

  @override
  Future<List<LocalPatientEntry>> getAllRecords({String? ownerUserId}) async =>
      [];

  @override
  Future<List<MapEntry<String, String>>> getWebQuarantinedEntries() async =>
      <MapEntry<String, String>>[];

  @override
  List<String> get webQuarantinedKeysForTesting => <String>[];

  @override
  Future<int> getUnsyncedCount({String? ownerUserId}) async => 0;

  @override
  Future<List<LocalPatientEntry>> getUnsyncedRecords({
    String? ownerUserId,
  }) async => [];

  @override
  Future<void> markSyncError(
    String patientId,
    String error, {
    int? statusCode,
    int? revision,
  }) async {}

  @override
  Future<void> markSynced(
    String patientId, {
    String? createdAt,
    String? recordJson,
    int? revision,
  }) async {}

  @override
  Future<void> savePatient(
    PatientFullRecord record, {
    bool isSynced = false,
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
  }) async {}

  @override
  Future<NfcChipStatus?> getChipStatus(String patientId) async => null;

  @override
  Future<void> markChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {}

  @override
  Future<void> clearChipsDirty(
    String patientId, {
    bool patient = false,
    bool guardian = false,
  }) async {}

  @override
  Future<void> purgeStalePermanentErrors({
    Duration maxAge = const Duration(days: 7),
  }) async {}

  @override
  Future<void> destroyEncryptionKey() async {}

  @override
  Future<void> markEmergencyLogsSynced(List<int> emergencyLogIds) async {}

  @override
  Future<int> getBlockedCount({String? ownerUserId}) async => 0;

  @override
  Future<int> getRetryablePendingCount({String? ownerUserId}) async => 0;
}

// -----------------------------------------------------------------------------
// BUILD SUBJECT
// -----------------------------------------------------------------------------

Widget buildSubject(PatientFullRecord patient) {
  final authRepo = FakeAuthRepository();
  final apiClient = ApiClient(baseUrl: 'https://example.com');
  final patientRepo = PatientRepository(
    apiClient: apiClient,
    authRepository: authRepo,
  );
  final userRepo = UserRepository(
    apiClient: apiClient,
    authRepository: authRepo,
  );
  final syncEngine = SyncEngine(
    patientRepository: patientRepo,
    localDatabase: FakeLocalDatabase(),
  );

  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: AppScope(
      authRepository: authRepo,
      userRepository: userRepo,
      patientRepository: patientRepo,
      localDatabase: FakeLocalDatabase(),
      syncEngine: syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: authRepo,
      ),
      reachability: Reachability(baseUrl: 'http://localhost'),
      child: MaterialApp(home: EditMedicalHistoryScreen(patient: patient)),
    ),
  );
}

Widget buildSubjectForNavigation(PatientFullRecord patient) {
  final authRepo = FakeAuthRepository();
  final apiClient = ApiClient(baseUrl: 'https://example.com');
  final patientRepo = PatientRepository(
    apiClient: apiClient,
    authRepository: authRepo,
  );
  final userRepo = UserRepository(
    apiClient: apiClient,
    authRepository: authRepo,
  );
  final syncEngine = SyncEngine(
    patientRepository: patientRepo,
    localDatabase: FakeLocalDatabase(),
  );

  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: AppScope(
      authRepository: authRepo,
      userRepository: userRepo,
      patientRepository: patientRepo,
      localDatabase: FakeLocalDatabase(),
      syncEngine: syncEngine,
      statsRepository: StatsRepository(
        apiClient: ApiClient(baseUrl: 'http://localhost'),
        authRepository: authRepo,
      ),
      reachability: Reachability(baseUrl: 'http://localhost'),
      child: MaterialApp(
        home: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () async {
                await Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditMedicalHistoryScreen(patient: patient),
                  ),
                );
              },
              child: const Text('Abrir'),
            );
          },
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// MOCK DATA
// -----------------------------------------------------------------------------

PatientFullRecord _basePatient({
  required String id,
  BackgroundHistory? backgroundHistory,
}) {
  return PatientFullRecord(
    patientId: id,
    deviceUid: 'dev-$id',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '000000',
      ),
      firstLastName: 'Extra',
      firstName: 'Paciente',
      dob: '1990-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
    backgroundHistory: backgroundHistory,
    medicalHistory: const <MedicalHistoryItem>[],
    allergies: const <AllergyInfo>[],
    vaccinationRecord: const <VaccinationRecordItem>[],
  );
}

PatientFullRecord emptyPatient() => _basePatient(id: 'e-001');

PatientFullRecord patientWithChronicCie10() => _basePatient(
  id: 'e-002',
  backgroundHistory: BackgroundHistory(
    chronicConditions: [
      ChronicConditionItem(
        chronicDescription: 'Hipertensión',
        chronicCie10Code: 'I10',
      ),
    ],
  ),
);

PatientFullRecord patientWithChronicNoCie10() => _basePatient(
  id: 'e-003',
  backgroundHistory: BackgroundHistory(
    chronicConditions: [ChronicConditionItem(chronicDescription: 'Asma')],
  ),
);

PatientFullRecord patientWithMedications() => _basePatient(
  id: 'e-004',
  backgroundHistory: BackgroundHistory(
    medications: [
      MedicationStatementItem(
        medicationName: 'MedActivo',
        status: 'active',
        dosage: '500mg',
      ),
      MedicationStatementItem(
        medicationName: 'MedCompletado',
        status: 'completed',
      ),
      MedicationStatementItem(
        medicationName: 'MedSuspendido',
        status: 'stopped',
      ),
      MedicationStatementItem(
        medicationName: 'MedDesconocido',
        status: 'unknown',
      ),
      MedicationStatementItem(medicationName: 'MedRaro', status: 'xyz'),
    ],
  ),
);

PatientFullRecord patientWithUnknownFamilyRelationship() => _basePatient(
  id: 'e-005',
  backgroundHistory: BackgroundHistory(
    familyHistory: [
      FamilyHistoryItem(
        conditionDescription: 'Condición rara',
        relationship: '77',
      ),
    ],
  ),
);

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

Finder addButtonAt(int index) =>
    find.widgetWithIcon(ElevatedButton, Icons.add).at(index);

Finder sheetAddButton() => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.widgetWithIcon(ElevatedButton, Icons.add),
);

Finder sheetTextFields() => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.byType(TextField),
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
}

// -----------------------------------------------------------------------------
// TESTS
// -----------------------------------------------------------------------------

void main() {
  // ---------------------------------------------------------------------------
  // GROUP 1 – Condiciones crónicas
  // ---------------------------------------------------------------------------

  group('Condiciones crónicas – estado vacío y renderizado', () {
    testWidgets('muestra mensaje cuando no hay condiciones crónicas', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      expect(
        find.text('Sin condiciones crónicas registradas.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra código CIE-10 cuando está presente', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithChronicCie10()));
      await tester.pumpAndSettle();

      expect(find.text('Hipertensión'), findsOneWidget);
      expect(find.textContaining('CIE-10: I10'), findsOneWidget);
    });

    testWidgets('no muestra código CIE-10 cuando es null', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithChronicNoCie10()));
      await tester.pumpAndSettle();

      expect(find.text('Asma'), findsOneWidget);
      expect(find.textContaining('CIE-10'), findsNothing);
    });
  });

  group('Condiciones crónicas – bottom sheet agregar/eliminar', () {
    testWidgets('abre el bottom sheet de condición crónica', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(0));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Agregar condición crónica'), findsOneWidget);
    });

    testWidgets('no agrega condición crónica vacía', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(0));
      await tester.pumpAndSettle();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.text('Sin condiciones crónicas registradas.'),
        findsOneWidget,
      );
    });

    testWidgets('agrega una condición crónica válida', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(0));
      await tester.pumpAndSettle();

      await tester.enterText(sheetTextFields(), 'Diabetes mellitus');
      await tester.pump();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.text('Diabetes mellitus'), findsOneWidget);
    });

    testWidgets('elimina una condición crónica sin crashear', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithChronicCie10()));
      await tester.pumpAndSettle();

      expect(find.text('Hipertensión'), findsOneWidget);

      await tapVisible(tester, find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Hipertensión'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 2 – Medicamentos
  // ---------------------------------------------------------------------------

  group('Medicamentos – estado vacío y renderizado', () {
    testWidgets('muestra mensaje cuando no hay medicamentos', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      expect(find.text('Sin medicamentos registrados.'), findsOneWidget);
    });

    testWidgets('muestra todas las etiquetas de estado y dosis', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(patientWithMedications()));
      await tester.pumpAndSettle();

      expect(find.text('MedActivo'), findsOneWidget);
      expect(find.text('Activo · 500mg'), findsOneWidget);

      expect(find.text('MedCompletado'), findsOneWidget);
      expect(find.text('Completado'), findsOneWidget);

      expect(find.text('MedSuspendido'), findsOneWidget);
      expect(find.text('Suspendido'), findsOneWidget);

      expect(find.text('MedDesconocido'), findsOneWidget);
      expect(find.text('Desconocido'), findsOneWidget);

      expect(find.text('MedRaro'), findsOneWidget);
      expect(find.text('xyz'), findsOneWidget); // fallback al código crudo
    });
  });

  group('Medicamentos – bottom sheet agregar/eliminar', () {
    testWidgets('abre el bottom sheet de medicamento', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(1));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Agregar medicamento'), findsOneWidget);
    });

    testWidgets('no agrega medicamento con nombre vacío', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(1));
      await tester.pumpAndSettle();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Sin medicamentos registrados.'), findsOneWidget);
    });

    testWidgets('agrega medicamento con nombre y dosis', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(1));
      await tester.pumpAndSettle();

      final fields = sheetTextFields();
      await tester.enterText(fields.at(0), 'Metformina');
      await tester.enterText(fields.at(1), '850mg cada 12h');
      await tester.pump();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.text('Metformina'), findsOneWidget);
      expect(find.text('Activo · 850mg cada 12h'), findsOneWidget);
    });

    testWidgets('agrega medicamento sin dosis (queda null)', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(1));
      await tester.pumpAndSettle();

      final fields = sheetTextFields();
      await tester.enterText(fields.at(0), 'Ibuprofeno');
      await tester.pump();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofeno'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget); // sin sufijo de dosis
    });

    testWidgets('elimina un medicamento sin crashear', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithMedications()));
      await tester.pumpAndSettle();

      expect(find.text('MedActivo'), findsOneWidget);

      await tapVisible(tester, find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('MedActivo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 3 – dropdown (_addItem)
  // ---------------------------------------------------------------------------

  group('Historial familiar – bottom sheet real con dropdown', () {
    testWidgets('el bottom sheet de historial familiar tiene un dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(2));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(DropdownButton<String>),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no agrega historial familiar con descripción vacía', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(2));
      await tester.pumpAndSettle();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('cambia la relación en el dropdown y agrega el ítem', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));
      await tester.pumpAndSettle();

      await tapVisible(tester, addButtonAt(2));
      await tester.pumpAndSettle();

      await tester.enterText(sheetTextFields(), 'Cáncer de mama');
      await tester.pump();

      await tapVisible(tester, find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Hermanos'));
      await tester.pumpAndSettle();

      await tapVisible(tester, sheetAddButton());
      await tester.pumpAndSettle();

      expect(find.text('Cáncer de mama'), findsOneWidget);
      expect(find.textContaining('Hermanos'), findsOneWidget);
    });

    testWidgets('relación desconocida usa el código crudo (rama de fallback)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(patientWithUnknownFamilyRelationship()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Condición rara'), findsOneWidget);
      expect(find.textContaining('77'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 4
  // ---------------------------------------------------------------------------

  group('Botones inferiores', () {
    testWidgets('botón "Volver" inferior hace pop', (tester) async {
      await tester.pumpWidget(buildSubjectForNavigation(emptyPatient()));

      await tapVisible(tester, find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_ios);
      await tapVisible(tester, backButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('botón "Volver" del header superior hace pop', (tester) async {
      await tester.pumpWidget(buildSubjectForNavigation(emptyPatient()));

      await tapVisible(tester, find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsOneWidget);

      // Ícono del header (SharedReadNfcHeader usa arrow_back, distinto del
      // botón inferior que usa arrow_back_ios).
      final headerBackButton = find.byIcon(Icons.arrow_back);
      expect(headerBackButton, findsOneWidget);

      await tapVisible(tester, headerBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('botón "Guardar" hace pop', (tester) async {
      await tester.pumpWidget(buildSubjectForNavigation(emptyPatient()));

      await tapVisible(tester, find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsOneWidget);

      final saveButton = find.byIcon(Icons.save);
      await tapVisible(tester, saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditMedicalHistoryScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
