// test/widget/edit_guardian_screen_widget_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/edit_guardian_screen.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Fakes
// ─────────────────────────────────────────────────────────────────────────────

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
  Future<String?> getNfcEncryptionKey() async => 'fake-nfc-key-12345';

  @override
  Future<NfcKeyring?> getNfcKeyring() async =>
      NfcKeyring.single('fake-nfc-key-12345');

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

// ─────────────────────────────────────────────────────────────────────────────
//  Test data
// ─────────────────────────────────────────────────────────────────────────────

PatientFullRecord _makePatient({
  String guardianName = 'María López',
  String guardianPhone = '30012547',
  String guardianRelationship = '01',
  String? deviceUid,
}) {
  return PatientFullRecord(
    patientId: 'p-test-001',
    deviceUid: 'd-test-001',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '123456789',
      ),
      firstLastName: 'Pérez',
      firstName: 'Juan',
      dob: '2000-06-15',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(
      name: guardianName,
      phone: guardianPhone,
      relationship: guardianRelationship,
      deviceUid: deviceUid,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper: Wraps EditGuardianScreen with all required providers
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildSubject({
  required PatientFullRecord patient,
  String locale = 'es',
}) {
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
    locale: locale,
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
      child: MaterialApp(home: EditGuardianScreen(patient: patient)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Group 1: Initial Rendering ────────────────────────────────────────
  group('EditGuardianScreen — renderizado inicial', () {
    testWidgets('muestra el título "Editar / actualizar" en el header', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.text('Editar / actualizar'), findsOneWidget);
    });

    testWidgets('muestra el título de la sección "Guardián"', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.text('Guardián (menores de 18)'), findsOneWidget);
    });

    testWidgets('muestra exactamente 4 campos TextField', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('muestra exactamente 2 dropdowns', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.byType(DropdownButton<String>), findsNWidgets(2));
    });

    testWidgets('muestra los botones Atrás y Guardar', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.text('Atrás'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('muestra los íconos de los botones de acción', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });

  // ── Group 2: Guardian data pre-loading ────────────────────────────
  group('EditGuardianScreen — pre-carga de datos', () {
    testWidgets('el campo de nombre muestra el nombre del guardián', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(guardianName: 'Carlos Ruiz')),
      );
      await tester.pump();
      expect(find.text('Carlos Ruiz'), findsOneWidget);
    });

    testWidgets('el campo de teléfono muestra el teléfono del guardián', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(guardianPhone: '3109876543')),
      );
      await tester.pump();
      expect(find.text('3109876543'), findsOneWidget);
    });

    testWidgets('el dropdown de tipo de documento muestra CC por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.text('Cédula de Ciudadanía'), findsOneWidget);
    });

    testWidgets('el dropdown de país muestra Colombia por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();
      expect(find.text('Colombia'), findsOneWidget);
    });

    testWidgets(
      'el campo de número de documento inicia vacío aunque el guardián tenga datos',
      (tester) async {
        await tester.pumpWidget(_buildSubject(patient: _makePatient()));
        await tester.pump();
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        final docNumField = textFields.elementAt(1);
        expect(docNumField.controller?.text ?? '', isEmpty);
      },
    );

    testWidgets(
      'el campo de dirección inicia vacío aunque el guardián tenga datos',
      (tester) async {
        await tester.pumpWidget(_buildSubject(patient: _makePatient()));
        await tester.pump();
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        final addressField = textFields.elementAt(2);
        expect(addressField.controller?.text ?? '', isEmpty);
      },
    );
  });

  // ── Group 3: Interaction with text fields ────────────────────────────
  group('EditGuardianScreen — edición de campos', () {
    testWidgets('el campo de nombre acepta entrada de texto', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      final nameField = find.byType(TextField).at(0);
      await tester.tap(nameField);
      await tester.enterText(nameField, 'Ana Torres');
      await tester.pump();

      expect(find.text('Ana Torres'), findsOneWidget);
    });

    testWidgets('el campo de teléfono acepta entrada numérica', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      final phoneField = find.byType(TextField).at(3);
      await tester.enterText(phoneField, '3157654321');
      await tester.pump();

      expect(find.text('3157654321'), findsOneWidget);
    });

    testWidgets('el campo de número de documento acepta texto', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      final docNumField = find.byType(TextField).at(1);
      await tester.tap(docNumField);
      await tester.enterText(docNumField, '9876543210');
      await tester.pump();

      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('el campo de dirección acepta texto', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      final addressField = find.byType(TextField).at(2);
      await tester.tap(addressField);
      await tester.enterText(addressField, 'Calle 50 # 10-20');
      await tester.pump();

      expect(find.text('Calle 50 # 10-20'), findsOneWidget);
    });
  });

  // ── Group 4: Interaction with dropdowns ─────────────────────────────────
  group('EditGuardianScreen — dropdowns', () {
    testWidgets('el dropdown de tipo de documento muestra las 3 opciones', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      expect(find.text('Cédula de Ciudadanía'), findsWidgets);
      expect(find.text('Pasaporte'), findsOneWidget);
      expect(find.text('Cédula Extranjería'), findsOneWidget);
    });

    testWidgets('el dropdown de tipo de documento cambia a Pasaporte', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pasaporte').last);
      await tester.pumpAndSettle();

      expect(find.text('Pasaporte'), findsOneWidget);
    });

    testWidgets('el dropdown de país muestra las 2 opciones disponibles', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      // Open the second dropdown (country)
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();

      expect(find.text('Colombia'), findsWidgets);
      expect(find.text('Venezuela'), findsOneWidget);
    });

    testWidgets('el dropdown de país cambia a Venezuela', (tester) async {
      await tester.pumpWidget(_buildSubject(patient: _makePatient()));
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Venezuela').last);
      await tester.pumpAndSettle();

      expect(find.text('Venezuela'), findsOneWidget);
    });
  });

  // ── Group 5: Navigation ─────────────────────────────────────────────────
  group('EditGuardianScreen — navegación', () {
    testWidgets('el botón Atrás hace pop de la pantalla', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool popped = false;

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

      await tester.pumpWidget(
        AppLocale(
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
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EditGuardianScreen(patient: _makePatient()),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
              navigatorObservers: [_PopObserver(onPop: () => popped = true)],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('el botón Guardar hace pop de la pantalla', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool popped = false;

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

      await tester.pumpWidget(
        AppLocale(
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
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EditGuardianScreen(patient: _makePatient()),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
              navigatorObservers: [_PopObserver(onPop: () => popped = true)],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('el botón de flecha en el header hace pop de la pantalla', (
      tester,
    ) async {
      bool popped = false;

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

      await tester.pumpWidget(
        AppLocale(
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
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EditGuardianScreen(patient: _makePatient()),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
              navigatorObservers: [_PopObserver(onPop: () => popped = true)],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });

  // ── Group 6: Location (ES / EN) ──────────────────────────────────────────
  group('EditGuardianScreen — localización', () {
    testWidgets('en locale ES muestra "Guardar"', (tester) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(), locale: 'es'),
      );
      await tester.pump();
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('en locale EN muestra "Save"', (tester) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(), locale: 'en'),
      );
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('en locale ES muestra "Atrás"', (tester) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(), locale: 'es'),
      );
      await tester.pump();
      expect(find.text('Atrás'), findsOneWidget);
    });

    testWidgets('en locale EN muestra "Back"', (tester) async {
      await tester.pumpWidget(
        _buildSubject(patient: _makePatient(), locale: 'en'),
      );
      await tester.pump();
      expect(find.text('Back'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Auxiliary observer for detecting pops in navigation tests
// ─────────────────────────────────────────────────────────────────────────────

class _PopObserver extends NavigatorObserver {
  _PopObserver({required this.onPop});
  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}
