// lib/src/features/auth/data/user_repository.dart

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_session.dart';

// ── OrgSummary (nuevo — usado por ManageOrganizationsScreen) ──────────────

class OrgSummary {
  const OrgSummary({
    required this.id,
    required this.name,
    required this.isActive,
    this.userCount = 0,
    this.patientCount = 0,
  });

  final String id;
  final String name;
  final bool isActive;
  final int userCount;
  final int patientCount;

  /// An organization is safe to hard-delete only when it has no members.
  bool get isEmpty => userCount == 0 && patientCount == 0;

  factory OrgSummary.fromJson(Map<String, dynamic> j) => OrgSummary(
    id: j['id'] as String,
    name: j['name'] as String,
    isActive: (j['is_active'] as bool?) ?? true,
    userCount: (j['user_count'] as num?)?.toInt() ?? 0,
    patientCount: (j['patient_count'] as num?)?.toInt() ?? 0,
  );
}

// ── Repository ────────────────────────────────────────────────────────────

class UserRepository {
  UserRepository({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  }) : _apiClient = apiClient,
       _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  Future<Map<String, String>> _authHeaders() async {
    final String token = await _authRepository.getAccessToken();
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  // ── GET /api/v1/users/me ──────────────────────────────────────────────────

  Future<UserSession> getMe() async {
    final data = await _apiClient.getJson(
      path: '/api/v1/users/me',
      headers: await _authHeaders(),
    );
    return UserSession.fromJson(data);
  }

  // ── GET /api/v1/users/ ────────────────────────────────────────────────────
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

  // ── POST /api/v1/users/ ───────────────────────────────────────────────────
  // org_admin can create doctor or nurse accounts.

  Future<UserSession> createUser({
    required String email,
    required String fullName,
    required String role, // "doctor" | "nurse" | "org_admin"
    required String password,
    String? organizationId, // only needed by superadmin
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'full_name': fullName,
      'role': role,
      'password': password,
      'organization_id': organizationId,
    };
    final data = await _apiClient.postJson(
      path: '/api/v1/users/',
      body: body,
      headers: await _authHeaders(),
    );
    return UserSession.fromJson(data);
  }

  // ── GET /api/v1/organizations/ ────────────────────────────────────────────
  // superadmin only.

  Future<List<OrgSummary>> listOrganizations() async {
    final List<dynamic> list = await _apiClient.getJsonList(
      path: '/api/v1/organizations/',
      headers: await _authHeaders(),
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrgSummary.fromJson)
        .toList();
  }

  // ── POST /api/v1/organizations/ ───────────────────────────────────────────
  // superadmin only — paso 1 al crear una organización.

  Future<OrgSummary> createOrganization(String name) async {
    final data = await _apiClient.postJson(
      path: '/api/v1/organizations/',
      body: {'name': name, 'is_active': true},
      headers: await _authHeaders(),
    );
    return OrgSummary.fromJson(data);
  }

  // ── POST /api/v1/users/ con role=org_admin ────────────────────────────────
  // superadmin only — paso 2 al crear una organización.

  Future<UserSession> createOrgAdminUser({
    required String fullName,
    required String email,
    required String password,
    required String organizationId,
  }) async {
    return createUser(
      email: email,
      fullName: fullName,
      role: 'org_admin',
      password: password,
      organizationId: organizationId,
    );
  }

  // ── POST /api/v1/organizations/ (atomic org + admin) ──────────────────────
  // superadmin only — crea la organización y su org_admin en UNA transacción.

  Future<OrgSummary> createOrganizationWithAdmin({
    required String name,
    required String adminFullName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final data = await _apiClient.postJson(
      path: '/api/v1/organizations/',
      body: {
        'name': name,
        'is_active': true,
        'admin': {
          'full_name': adminFullName,
          'email': adminEmail,
          'password': adminPassword,
        },
      },
      headers: await _authHeaders(),
    );
    return OrgSummary.fromJson(data);
  }

  // ── PATCH /api/v1/organizations/{id} ──────────────────────────────────────
  // superadmin only — activa/desactiva (soft) una organización.

  Future<OrgSummary> setOrganizationActive(String id, bool isActive) async {
    final data = await _apiClient.patchJson(
      path: '/api/v1/organizations/$id',
      body: {'is_active': isActive},
      headers: await _authHeaders(),
    );
    return OrgSummary.fromJson(data);
  }

  // ── DELETE /api/v1/organizations/{id} ─────────────────────────────────────
  // superadmin only — hard-delete; el backend responde 409 si NO está vacía.

  Future<void> deleteOrganization(String id) async {
    await _apiClient.delete(
      path: '/api/v1/organizations/$id',
      headers: await _authHeaders(),
    );
  }

  // ── PATCH /api/v1/users/{id} ──────────────────────────────────────────────
  // superadmin / org_admin — activa/desactiva (soft) un usuario.

  Future<UserSession> setUserActive(String id, bool isActive) async {
    final data = await _apiClient.patchJson(
      path: '/api/v1/users/$id',
      body: {'is_active': isActive},
      headers: await _authHeaders(),
    );
    return UserSession.fromJson(data);
  }

  // ── DELETE /api/v1/users/{id} ─────────────────────────────────────────────
  // superadmin / org_admin — hard-delete con guards del backend.

  Future<void> deleteUser(String id) async {
    await _apiClient.delete(
      path: '/api/v1/users/$id',
      headers: await _authHeaders(),
    );
  }
}
