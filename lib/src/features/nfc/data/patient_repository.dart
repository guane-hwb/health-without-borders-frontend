// lib/src/features/nfc/data/patient_repository.dart

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
  Future<PatientSyncResponse> syncPatient(
    PatientFullRecord record, {
    String? retiredDeviceReason,
  }) async {
    final Map<String, dynamic> body = Map<String, dynamic>.from(
      record.toJson(),
    );
    // Transport-only signal for bracelet/guardian re-labeling. Injected here
    // rather than in PatientFullRecord.toJson() so it never gets written to an
    // NFC tag (toJson also feeds the tag payload). The backend consumes it to
    // record the retirement reason and drops it from the stored record.
    if (retiredDeviceReason != null && retiredDeviceReason.isNotEmpty) {
      body['retiredDeviceReason'] = retiredDeviceReason;
    }
    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/patients/sync',
      body: body,
      headers: await _authHeaders(),
      timeout: const Duration(seconds: 10),
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
  Future<PatientFullRecord> searchPatient({
    required String documentNumber,
    required String birthDate,
    required String firstName,
    required String lastName,
    String? guardianName,
  }) async {
    final Map<String, dynamic> searchBody = <String, dynamic>{
      'document_number': documentNumber,
      'birth_date': birthDate,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (guardianName != null && guardianName.isNotEmpty) {
      searchBody['guardian_name'] = guardianName;
    }

    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/patients/search',
      headers: await _authHeaders(),
      body: searchBody,
    );
    return PatientFullRecord.fromJson(data);
  }

  // ── POST /api/v1/patients/emergency-access ──────────────────────────────
  /// Envía la bitácora de accesos break-glass registrados offline.
  Future<void> reportEmergencyAccess(List<Map<String, Object?>> entries) async {
    if (entries.isEmpty) return;
    await _apiClient.postJson(
      path: '/api/v1/patients/emergency-access',
      body: <String, dynamic>{'entries': entries},
      headers: await _authHeaders(),
    );
  }

  /// Reports which NFC key version each scanned chip was found on.
  ///
  /// Only the four telemetry fields are sent — UID, role, version, timestamp.
  /// Whatever else the local row carries (sync bookkeeping) stays on the
  /// device, so the wire payload cannot drift into holding anything else.
  Future<void> reportNfcKeyVersions(List<Map<String, Object?>> entries) async {
    if (entries.isEmpty) return;
    await _apiClient.postJson(
      path: '/api/v1/patients/nfc-key-versions',
      body: <String, dynamic>{
        'entries': entries
            .map(
              (Map<String, Object?> e) => <String, dynamic>{
                'device_uid': e['device_uid'],
                'device_role': e['device_role'],
                'key_version': e['key_version'],
                'had_header': (e['had_header'] as num?)?.toInt() == 1,
                'observed_at': e['observed_at'],
              },
            )
            .toList(),
      },
      headers: await _authHeaders(),
    );
  }
}
