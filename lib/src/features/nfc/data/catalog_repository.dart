import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/catalog_data.dart';

class CatalogRepository {
  CatalogRepository({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  })  : _apiClient = apiClient,
        _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  CatalogData? _cached;

  Future<CatalogData> getCatalogs({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    try {
      final String token = await _authRepository.getAccessToken();
      final Map<String, dynamic> data = await _apiClient.getJson(
        path: '/api/v1/catalogs/sync',
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
      _cached = CatalogData.fromJson(data);
      return _cached!;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final String token =
            await _authRepository.getAccessToken(forceRefresh: true);
        final Map<String, dynamic> data = await _apiClient.getJson(
          path: '/api/v1/catalogs/sync',
          headers: <String, String>{'Authorization': 'Bearer $token'},
        );
        _cached = CatalogData.fromJson(data);
        return _cached!;
      }
      rethrow;
    }
  }
}
