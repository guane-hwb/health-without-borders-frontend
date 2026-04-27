// lib/src/features/auth/data/user_repository.dart
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_session.dart';

class UserRepository {
  UserRepository({
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

  // ── GET /api/v1/users/me ─────────────────────────────────────────────────

  Future<UserSession> getMe() async {
    final data = await _apiClient.getJson(
      path: '/api/v1/users/me',
      headers: await _authHeaders(),
    );
    return UserSession.fromJson(data);
  }

  // ── GET /api/v1/users/ ───────────────────────────────────────────────────
  // Available for org_admin and superadmin only.

  Future<List<UserSession>> listUsers() async {
    final List<dynamic> list = await _apiClient.getJsonList(
      path: '/api/v1/users/',
      headers: await _authHeaders(),
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserSession.fromJson)
        .toList();
  }

  // ── POST /api/v1/users/ ──────────────────────────────────────────────────
  // org_admin can create doctor or nurse accounts.

  Future<UserSession> createUser({
    required String email,
    required String fullName,
    required String role, // "doctor" | "nurse"
    required String password,
    String? organizationId, // only needed by superadmin
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'full_name': fullName,
      'role': role,
      'password': password,
      'organization_id': ?organizationId,
    };
    final data = await _apiClient.postJson(
      path: '/api/v1/users/',
      body: body,
      headers: await _authHeaders(),
    );
    return UserSession.fromJson(data);
  }
}