import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/patient_record.dart';

class PatientRepository {
  PatientRepository({
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

  // ── POST /api/v1/patients/sync ──────────────────────────────────────────
  /// Syncs a patient record to the cloud.
  /// Returns [PatientSyncResponse] on 201.
  /// Throws [ApiException] on 401 (expired token), 403 (nurse adding
  /// medical history), 422 (validation), or 500.
  Future<PatientSyncResponse> syncPatient(PatientFullRecord record) async {
    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/patients/sync',
      body: record.toJson(),
      headers: await _authHeaders(),
    );
    return PatientSyncResponse.fromJson(data);
  }

  // ── GET /api/v1/patients/scan/{device_uid} ──────────────────────────────
  /// Retrieves a patient by scanning their NFC wristband.
  ///
  /// If the patient is a minor (<18), the backend returns 403 with
  /// "Guardian bracelet scan required for minors."  In that case, the
  /// caller should prompt for the guardian's NFC scan and call this
  /// method again with [guardianDeviceUid] (sent as the X-Guardian-Device-UID header).
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
  }) async {
    final Map<String, String> headers = await _authHeaders();
    if (guardianDeviceUid != null && guardianDeviceUid.isNotEmpty) {
      headers['X-Guardian-Device-UID'] = guardianDeviceUid.trim();
    }

    final String safeDeviceUid = Uri.encodeComponent(deviceUid.trim());

    final Map<String, dynamic> data = await _apiClient.getJson(
      path: '/api/v1/patients/scan/$safeDeviceUid',
      headers: headers,
    );
    return PatientFullRecord.fromJson(data);
  }

  // ── POST /api/v1/patients/search ────────────────────────────────────────
  /// Strict patient lookup by identity fields.
  /// Returns exactly one patient or throws 404.
  ///
  /// All four parameters are mandatory per the backend contract:
  ///   - documentNumber (exact match)
  ///   - birthDate (YYYY-MM-DD, exact match)
  ///   - firstName (exact, case-insensitive)
  ///   - lastName (matches first OR second last name, case-insensitive)
  ///
  /// Optional: guardianName adds an extra verification layer.
  ///
  /// The criteria travel in the request body (not the query string) so that
  /// the document number, names and birth date never leak into access logs,
  /// proxies or browser history.
  Future<PatientFullRecord> searchPatient({
    required String documentNumber,
    required String birthDate,
    required String firstName,
    required String lastName,
    String? guardianName,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'document_number': documentNumber,
      'birth_date': birthDate,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (guardianName != null && guardianName.isNotEmpty) {
      body['guardian_name'] = guardianName;
    }

    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/patients/search',
      headers: await _authHeaders(),
      body: body,
    );
    return PatientFullRecord.fromJson(data);
  }
}
