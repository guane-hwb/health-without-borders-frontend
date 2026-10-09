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

  /// The server codes diagnoses with the LLM and writes to the FHIR Store
  /// inside the /sync request: p95 25.6 s and up to 68 s in production.
  ///
  /// A timeout does not mean nothing was saved. The retry is safe (visits and
  /// vaccinations merge by their ids) and may come back with
  /// `stale_payload_base_version` when the first attempt was saved.
  static const Duration syncTimeout = Duration(seconds: 90);

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
      timeout: syncTimeout,
    );
    return PatientSyncResponse.fromJson(data);
  }

  // ── POST /api/v1/patients/scan ──────────────────────────────────────────
  /// Retrieves a patient by scanning their NFC wristband.
  ///
  /// Both UIDs travel in the body: in the URL, the wristband UID (PHI) ended
  /// up in Cloud Run's request logs.
  ///
  /// A minor (<18) answers 403 `guardian_required`: the caller asks for the
  /// guardian's card and calls again with [guardianDeviceUid]. A stored
  /// record the server can no longer read answers 500
  /// `stored_record_invalid`; trying again does not help.
  Future<PatientFullRecord> scanDevice(
    String deviceUid, {
    String? guardianDeviceUid,
  }) async {
    final String guardian = guardianDeviceUid?.trim() ?? '';
    final Map<String, dynamic> data = await _apiClient.postJson(
      path: '/api/v1/patients/scan',
      headers: await _authHeaders(),
      body: <String, dynamic>{
        'device_uid': deviceUid.trim(),
        'guardian_device_uid': guardian.isEmpty ? null : guardian,
      },
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

  /// Normalises a stored timestamp to UTC ISO-8601.
  ///
  /// Rows written by a build that stored naive local time are still pending on
  /// upgraded devices, and a chip nobody reads again keeps its row forever. The
  /// whole batch is one request, so a single stale row would be enough to have
  /// the server reject every observation alongside it. Converting here fixes
  /// those rows on their way out instead of stranding them.
  static String? _asUtcIso(Object? value) {
    final String raw = value?.toString() ?? '';
    if (raw.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw);
    // tryParse reads a suffix-less value as local time, which is exactly how
    // the old rows were written.
    return parsed?.toUtc().toIso8601String() ?? raw;
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
                'observed_at': _asUtcIso(e['observed_at']),
              },
            )
            .toList(),
      },
      headers: await _authHeaders(),
    );
  }
}
