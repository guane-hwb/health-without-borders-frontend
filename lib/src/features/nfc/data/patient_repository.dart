import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/patient_record.dart';

class PatientRepository {
  PatientRepository({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  })  : _apiClient = apiClient,
        _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  Future<Map<String, String>> _authHeaders() async {
    final String token = await _authRepository.getAccessToken();
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  Future<Map<String, String>> _refreshedAuthHeaders() async {
    final String token =
        await _authRepository.getAccessToken(forceRefresh: true);
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  Future<PatientSyncResponse> syncPatient(
      PatientFullRecord record) async {
    try {
      final Map<String, dynamic> data = await _apiClient.postJson(
        path: '/api/v1/patients/sync',
        body: record.toJson(),
        headers: await _authHeaders(),
      );
      return PatientSyncResponse.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final Map<String, dynamic> data = await _apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: record.toJson(),
          headers: await _refreshedAuthHeaders(),
        );
        return PatientSyncResponse.fromJson(data);
      }
      rethrow;
    }
  }

  Future<PatientFullRecord> scanDevice(String deviceUid) async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        path: '/api/v1/patients/scan/$deviceUid',
        headers: await _authHeaders(),
      );
      return PatientFullRecord.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final Map<String, dynamic> data = await _apiClient.getJson(
          path: '/api/v1/patients/scan/$deviceUid',
          headers: await _refreshedAuthHeaders(),
        );
        return PatientFullRecord.fromJson(data);
      }
      rethrow;
    }
  }

  Future<List<PatientFullRecord>> searchPatients({
    required String firstName,
    required String lastName,
    required String birthDate,
    String? guardianName,
  }) async {
    final Map<String, String> queryParams = <String, String>{
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
    };
    if (guardianName != null && guardianName.isNotEmpty) {
      queryParams['guardian_name'] = guardianName;
    }

    try {
      final List<dynamic> data = await _apiClient.getJsonList(
        path: '/api/v1/patients/search',
        headers: await _authHeaders(),
        queryParams: queryParams,
      );
      return data
          .map((dynamic e) =>
              PatientFullRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final List<dynamic> data = await _apiClient.getJsonList(
          path: '/api/v1/patients/search',
          headers: await _refreshedAuthHeaders(),
          queryParams: queryParams,
        );
        return data
            .map((dynamic e) =>
                PatientFullRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }
}
