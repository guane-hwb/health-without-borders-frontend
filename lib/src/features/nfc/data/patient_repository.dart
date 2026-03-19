import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

class PatientRepository {
  PatientRepository({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  })  : _apiClient = apiClient,
        _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  Future<Map<String, dynamic>> syncPatient(Map<String, dynamic> payload) async {
    try {
      final String token = await _authRepository.getAccessToken();
      return await _apiClient.postJson(
        path: '/api/v1/patients/sync',
        body: payload,
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final String refreshedToken = await _authRepository.getAccessToken(
          forceRefresh: true,
        );
        return _apiClient.postJson(
          path: '/api/v1/patients/sync',
          body: payload,
          headers: <String, String>{'Authorization': 'Bearer $refreshedToken'},
        );
      }
      rethrow;
    }
  }
}
