import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ─────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class _FakePatientFullRecord implements PatientFullRecord {
  const _FakePatientFullRecord(this._json);
  final Map<String, dynamic> _json;

  @override
  Map<String, dynamic> toJson() => _json;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockApiClient apiClient;
  late MockAuthRepository authRepository;
  late PatientRepository repository;

  const String fakeToken = 'fake-jwt-token';
  final Map<String, String> expectedAuthHeader = <String, String>{
    'Authorization': 'Bearer $fakeToken',
  };

  setUp(() {
    apiClient = MockApiClient();
    authRepository = MockAuthRepository();
    repository = PatientRepository(
      apiClient: apiClient,
      authRepository: authRepository,
    );

    when(
      () => authRepository.getAccessToken(),
    ).thenAnswer((_) async => fakeToken);
  });

  group('syncPatient', () {
    test('POSTs to /api/v1/patients/sync with auth header and returns '
        'PatientSyncResponse on success (201)', () async {
      final record = _FakePatientFullRecord(<String, dynamic>{
        'document_number': '12345678',
        'first_name': 'Ana',
        'last_name': 'Gomez',
      });

      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-001',
        'status': 'synced',
      };

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.syncPatient(record as PatientFullRecord);

      expect(result, isA<PatientSyncResponse>());
      verify(
        () => apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: record.toJson(),
          headers: expectedAuthHeader,
        ),
      ).called(1);
      verify(() => authRepository.getAccessToken()).called(1);
    });

    test('propagates ApiException on 401 (expired token)', () async {
      final record = _FakePatientFullRecord(<String, dynamic>{});

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(ApiException('Token expired', statusCode: 401));

      expect(
        () => repository.syncPatient(record as PatientFullRecord),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'propagates ApiException on 403 (nurse adding medical history)',
      () async {
        final record = _FakePatientFullRecord(<String, dynamic>{});

        when(
          () => apiClient.postJson(
            path: '/api/v1/patients/sync',
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          ApiException('Nurse cannot add medical history', statusCode: 403),
        );

        expect(
          () => repository.syncPatient(record as PatientFullRecord),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('propagates ApiException on 422 (validation error)', () async {
      final record = _FakePatientFullRecord(<String, dynamic>{});

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(ApiException('Validation failed', statusCode: 422));

      expect(
        () => repository.syncPatient(record as PatientFullRecord),
        throwsA(isA<ApiException>()),
      );
    });

    test('propagates ApiException on 500', () async {
      final record = _FakePatientFullRecord(<String, dynamic>{});

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(ApiException('Internal error', statusCode: 500));

      expect(
        () => repository.syncPatient(record as PatientFullRecord),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('scanDevice', () {
    const String deviceUid = 'abc-123';

    test('GETs /api/v1/patients/scan/{device_uid} without guardian header '
        'when guardianDeviceUid is null', () async {
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-001',
      };

      when(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$deviceUid',
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.scanDevice(deviceUid);

      expect(result, isA<PatientFullRecord>());
      final captured =
          verify(
                () => apiClient.getJson(
                  path: '/api/v1/patients/scan/$deviceUid',
                  headers: captureAny(named: 'headers'),
                ),
              ).captured.single
              as Map<String, String>;

      expect(captured, expectedAuthHeader);
      expect(captured.containsKey('X-Guardian-Device-UID'), isFalse);
    });

    test('GETs without guardian header when guardianDeviceUid is empty '
        'string', () async {
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-001',
      };

      when(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$deviceUid',
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.scanDevice(
        deviceUid,
        guardianDeviceUid: '',
      );

      expect(result, isA<PatientFullRecord>());
      final captured =
          verify(
                () => apiClient.getJson(
                  path: '/api/v1/patients/scan/$deviceUid',
                  headers: captureAny(named: 'headers'),
                ),
              ).captured.single
              as Map<String, String>;

      expect(captured.containsKey('X-Guardian-Device-UID'), isFalse);
    });

    test('adds trimmed X-Guardian-Device-UID header when provided', () async {
      const String guardianUid = '  guardian-xyz  ';
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-002',
      };

      when(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$deviceUid',
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.scanDevice(
        deviceUid,
        guardianDeviceUid: guardianUid,
      );

      expect(result, isA<PatientFullRecord>());
      final captured =
          verify(
                () => apiClient.getJson(
                  path: '/api/v1/patients/scan/$deviceUid',
                  headers: captureAny(named: 'headers'),
                ),
              ).captured.single
              as Map<String, String>;

      expect(captured['X-Guardian-Device-UID'], 'guardian-xyz');
      expect(captured['Authorization'], 'Bearer $fakeToken');
    });

    test('URL-encodes special characters in deviceUid', () async {
      const String rawDeviceUid = '  uid with spaces/slash  ';
      final String expectedSafeUid = Uri.encodeComponent(rawDeviceUid.trim());

      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-003',
      };

      when(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$expectedSafeUid',
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.scanDevice(rawDeviceUid);

      expect(result, isA<PatientFullRecord>());
      verify(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$expectedSafeUid',
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('propagates ApiException with "Guardian bracelet scan required '
        'for minors." on 403', () async {
      when(
        () => apiClient.getJson(
          path: '/api/v1/patients/scan/$deviceUid',
          headers: any(named: 'headers'),
        ),
      ).thenThrow(
        ApiException(
          'Guardian bracelet scan required for minors.',
          statusCode: 403,
        ),
      );

      expect(
        () => repository.scanDevice(deviceUid),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('searchPatient', () {
    const String documentNumber = '12345678';
    const String birthDate = '1990-05-12';
    const String firstName = 'Ana';
    const String lastName = 'Gomez';

    test('POSTs required fields only when guardianName is null', () async {
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-010',
      };

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/search',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.searchPatient(
        documentNumber: documentNumber,
        birthDate: birthDate,
        firstName: firstName,
        lastName: lastName,
      );

      expect(result, isA<PatientFullRecord>());

      final captured = verify(
        () => apiClient.postJson(
          path: '/api/v1/patients/search',
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;

      final Map<String, dynamic> capturedHeaders =
          captured.firstWhere((c) => (c as Map).containsKey('Authorization'))
              as Map<String, dynamic>;
      final Map<String, dynamic> capturedBody =
          captured.firstWhere((c) => (c as Map).containsKey('document_number'))
              as Map<String, dynamic>;

      expect(capturedHeaders, expectedAuthHeader);
      expect(capturedBody, <String, dynamic>{
        'document_number': documentNumber,
        'birth_date': birthDate,
        'first_name': firstName,
        'last_name': lastName,
      });
      expect(capturedBody.containsKey('guardian_name'), isFalse);
    });

    test('includes guardian_name in body when guardianName is provided '
        'and non-empty', () async {
      const String guardianName = 'Maria Gomez';
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-011',
      };

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/search',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => responseJson);

      final result = await repository.searchPatient(
        documentNumber: documentNumber,
        birthDate: birthDate,
        firstName: firstName,
        lastName: lastName,
        guardianName: guardianName,
      );

      expect(result, isA<PatientFullRecord>());

      final capturedBody =
          verify(
                () => apiClient.postJson(
                  path: '/api/v1/patients/search',
                  headers: any(named: 'headers'),
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(capturedBody['guardian_name'], guardianName);
    });

    test('omits guardian_name when guardianName is an empty string', () async {
      final Map<String, dynamic> responseJson = <String, dynamic>{
        'id': 'patient-012',
      };

      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/search',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => responseJson);

      await repository.searchPatient(
        documentNumber: documentNumber,
        birthDate: birthDate,
        firstName: firstName,
        lastName: lastName,
        guardianName: '',
      );

      final capturedBody =
          verify(
                () => apiClient.postJson(
                  path: '/api/v1/patients/search',
                  headers: any(named: 'headers'),
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(capturedBody.containsKey('guardian_name'), isFalse);
    });

    test('propagates ApiException on 404 (no match found)', () async {
      when(
        () => apiClient.postJson(
          path: '/api/v1/patients/search',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException('Patient not found', statusCode: 404));

      expect(
        () => repository.searchPatient(
          documentNumber: documentNumber,
          birthDate: birthDate,
          firstName: firstName,
          lastName: lastName,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
