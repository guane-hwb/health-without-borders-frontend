import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/nfc/data/patient_repository.dart';
import '../../features/nfc/domain/patient_record.dart';
import '../network/api_client.dart';
import '../storage/local_database.dart';

/// Background sync engine that pushes local patient records to the backend.
///
/// Implements the workflow from the integration guide (section 3.2):
///   1. Monitor connectivity — detect WiFi/cellular availability.
///   2. On connection detected — query all local records where is_synced = false.
///   3. For each unsynced record — call POST /api/v1/patients/sync.
///   4. On 201 response — mark as is_synced = true, scrub clinical data.
///   5. On 4xx/5xx error — keep is_synced = false for automatic retry.
class SyncEngine {
  SyncEngine({
    required PatientRepository patientRepository,
    LocalDatabase? localDatabase,
  })  : _patientRepo = patientRepository,
        _localDb = localDatabase ?? LocalDatabase.instance;

  final PatientRepository _patientRepo;
  final LocalDatabase _localDb;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  /// Callback fired whenever the sync status changes.
  /// The int parameter is the current count of unsynced records.
  void Function(int unsyncedCount)? onSyncStatusChanged;

  /// Callback fired when a specific record finishes syncing.
  void Function(String patientId, bool success, String? error)?
      onRecordSynced;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts monitoring connectivity. When a connection is detected,
  /// automatically attempts to sync all pending records.
  void start() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasConnection) {
        syncAll();
      }
    });

    // Also try immediately on start
    syncAll();
  }

  /// Stops monitoring connectivity.
  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  /// Attempts to sync all unsynced records to the backend.
  /// Safe to call multiple times — concurrent calls are serialized.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final List<LocalPatientEntry> pending =
          await _localDb.getUnsyncedRecords();

      for (final entry in pending) {
        await _syncOne(entry);
      }

      final remaining = await _localDb.getUnsyncedCount();
      onSyncStatusChanged?.call(remaining);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncOne(LocalPatientEntry entry) async {
    final PatientFullRecord? record = entry.toPatientRecord();
    if (record == null) {
      // Record was already scrubbed or corrupted — skip
      return;
    }

    try {
      final PatientSyncResponse response =
          await _patientRepo.syncPatient(record);

      if (response.status == 'success') {
        // Mark synced and scrub clinical data per security policy
        await _localDb.markSynced(entry.patientId);
        onRecordSynced?.call(entry.patientId, true, null);
      } else {
        await _localDb.markSyncError(
          entry.patientId,
          'Sync returned status: ${response.status}',
        );
        onRecordSynced?.call(
          entry.patientId,
          false,
          response.message,
        );
      }
    } on ApiException catch (e) {
      // 400 = bad request (don't retry)
      // 401 = token expired (need re-login, stop syncing)
      // 403/422 = data issue (don't retry until user fixes)
      // 429 = rate limited (retry later)
      // 500 = server error (retry later)
      final shouldStopAll = e.statusCode == 401;
      final shouldNotRetry =
          e.statusCode == 400 || e.statusCode == 422;

      await _localDb.markSyncError(entry.patientId, e.message);
      onRecordSynced?.call(entry.patientId, false, e.message);

      if (shouldStopAll) {
        // Token expired — caller should redirect to login
        return;
      }
      if (shouldNotRetry) {
        // Data-level error — user must review and fix
        return;
      }
      // For 429, 500, network errors: keep is_synced=false for retry
    } catch (e) {
      // Network timeout or unexpected error — keep for retry
      await _localDb.markSyncError(entry.patientId, '$e');
      onRecordSynced?.call(entry.patientId, false, '$e');
    }
  }

  // ── Manual controls ───────────────────────────────────────────────────────

  /// Syncs a single specific record by patientId.
  Future<bool> syncOne(String patientId) async {
    final entries = await _localDb.getUnsyncedRecords();
    final match = entries.where((e) => e.patientId == patientId);
    if (match.isEmpty) return false;

    await _syncOne(match.first);
    final updated = await _localDb.getUnsyncedRecords();
    return !updated.any((e) => e.patientId == patientId);
  }
}