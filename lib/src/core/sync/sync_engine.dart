// lib/src/core/sync/sync_engine.dart

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/nfc/data/patient_repository.dart';
import '../../features/nfc/domain/patient_record.dart';
import '../network/api_client.dart';
import '../network/reachability.dart';
import '../storage/local_database.dart';
import '../utils/app_logger.dart';

enum SyncOneResult { success, failure, busy, notFound }

enum _SyncOutcome { success, failure, networkFailure, abortBatch }

/// Background sync engine that pushes local patient records to the backend.
class SyncEngine {
  SyncEngine({
    required PatientRepository patientRepository,
    LocalDatabase? localDatabase,
    Stream<List<ConnectivityResult>>? connectivityStream,
    Reachability? reachability,
    List<Duration>? retryBackoff,
  }) : _patientRepo = patientRepository,
       _localDb = localDatabase ?? LocalDatabase.instance,
       _connectivityStream = connectivityStream,
       _reachability = reachability,
       _retryBackoff = retryBackoff ?? _defaultRetryBackoff;

  final PatientRepository _patientRepo;
  final LocalDatabase _localDb;
  final Stream<List<ConnectivityResult>>? _connectivityStream;
  final Reachability? _reachability;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  final List<Duration> _retryBackoff;

  static const List<Duration> _defaultRetryBackoff = <Duration>[
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  bool _isSyncing = false;

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<int> blockedCount = ValueNotifier<int>(0);

  Future<void> refreshPendingCount() async {
    try {
      pendingCount.value = await _localDb.getUnsyncedCount();
      blockedCount.value = await _localDb.getBlockedCount();
    } catch (e, stack) {
      AppLogger.e(
        'Error al refrescar conteo de pendientes',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void Function(int unsyncedCount)? onSyncStatusChanged;
  void Function(String patientId, bool success, String? error)? onRecordSynced;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void start() {
    _connectivitySub?.cancel();
    final Stream<List<ConnectivityResult>> stream =
        _connectivityStream ?? Connectivity().onConnectivityChanged;
    _connectivitySub = stream.listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        _retryAttempt = 0;
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          AppLogger.d(
            'Conexión estable detectada. Iniciando sincronización en segundo plano...',
          );
          syncAll();
        });
      }
    });

    syncAll();
  }

  void stop() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (pendingCount.value == 0) {
      _retryAttempt = 0;
      return;
    }
    final Duration delay =
        _retryBackoff[_retryAttempt.clamp(0, _retryBackoff.length - 1)];
    _retryAttempt++;
    AppLogger.d('Reintento de sincronización programado en $delay.');
    _retryTimer = Timer(delay, syncAll);
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  Future<bool> syncAll() async {
    await refreshPendingCount();
    if (_isSyncing) return false;

    if (_reachability != null && !await _reachability.probe()) {
      AppLogger.d('Backend inalcanzable. Se omite el lote.');
      _scheduleRetry();
      return false;
    }

    _isSyncing = true;
    bool allSuccessful = true;

    try {
      final List<LocalPatientEntry> allUnsynced = await _localDb
          .getUnsyncedRecords();

      final pending = allUnsynced.where((entry) {
        final code = entry.syncErrorCode;
        return code == null || !kPermanentSyncErrorCodes.contains(code);
      }).toList();

      AppLogger.d('Iniciando syncAll: ${pending.length} registros pendientes.');

      const int maxConsecutiveNetworkFailures = 3;
      int consecutiveNetworkFailures = 0;

      for (final entry in pending) {
        final outcome = await _syncOne(entry);
        if (outcome == _SyncOutcome.abortBatch) {
          allSuccessful = false;
          AppLogger.e('Lote abortado por sesión caducada.');
          break;
        }
        if (outcome == _SyncOutcome.networkFailure) {
          allSuccessful = false;
          consecutiveNetworkFailures++;
          if (consecutiveNetworkFailures >= maxConsecutiveNetworkFailures) {
            AppLogger.e(
              'Red inutilizable: abandonando el lote tras $consecutiveNetworkFailures fallos de red consecutivos.',
            );
            break;
          }
          continue;
        }
        consecutiveNetworkFailures = 0;
        if (outcome != _SyncOutcome.success) {
          allSuccessful = false;
        }
      }

      final remaining = await _localDb.getRetryablePendingCount();
      pendingCount.value = remaining;
      onSyncStatusChanged?.call(remaining);

      return allSuccessful && remaining == 0;
    } catch (e, stack) {
      AppLogger.e('Error crítico durante syncAll', error: e, stackTrace: stack);
      return false;
    } finally {
      _isSyncing = false;
      await refreshPendingCount();
      _scheduleRetry();
    }
  }

  Future<_SyncOutcome> _syncOne(LocalPatientEntry entry) async {
    final PatientFullRecord? record = entry.toPatientRecord();
    if (record == null) {
      AppLogger.e('Omitiendo registro corrupto con ID: ${entry.patientId}');
      await _localDb.markSyncError(
        entry.patientId,
        'Registro local ilegible (fallo de descifrado)',
        statusCode: 422,
      );
      return _SyncOutcome.failure;
    }

    try {
      final PatientSyncResponse response = await _patientRepo.syncPatient(
        record,
      );

      final bool fhirOk =
          response.fhirStatus == null ||
          response.fhirStatus!.isEmpty ||
          response.fhirStatus == 'success';

      if (response.status == 'success' && fhirOk) {
        AppLogger.d('Registro sincronizado exitosamente: ${entry.patientId}');

        await _localDb.markSynced(
          entry.patientId,
          createdAt: entry.createdAt,
          recordJson: entry.recordJson,
          revision: entry.revision,
        );
        onRecordSynced?.call(entry.patientId, true, null);
        return _SyncOutcome.success;
      } else {
        final String errorMsg = !fhirOk
            ? 'Envío FHIR fallido: ${response.fhirStatus}'
            : 'Sync returned status: ${response.status}';
        AppLogger.e(
          'Fallo en sincronización para ${entry.patientId}: $errorMsg',
        );
        await _localDb.markSyncError(entry.patientId, errorMsg);
        onRecordSynced?.call(entry.patientId, false, response.message);
        return _SyncOutcome.failure;
      }
    } on ApiException catch (e) {
      AppLogger.e(
        'ApiException (${e.statusCode}) sincronizando ${entry.patientId}: ${e.message}',
      );

      if (e.statusCode == 401) {
        onRecordSynced?.call(entry.patientId, false, 'Sesión expirada');
        return _SyncOutcome.abortBatch;
      }

      final String safeMsg = (e.statusCode == 422)
          ? 'Error de validación (422): Campos incompatibles con el backend'
          : e.message;

      await _localDb.markSyncError(
        entry.patientId,
        safeMsg,
        statusCode: e.statusCode,
      );
      onRecordSynced?.call(entry.patientId, false, safeMsg);
      return _SyncOutcome.failure;
    } catch (e, stack) {
      AppLogger.e(
        'Error no controlado sincronizando ${entry.patientId}',
        error: e,
        stackTrace: stack,
      );
      final bool isNetworkError =
          e is TimeoutException ||
          e is SocketException ||
          e is http.ClientException ||
          e.toString().contains('SocketException');

      final String safeMsg = isNetworkError
          ? 'Error de conexión de red'
          : 'Error en proceso de sincronización';

      await _localDb.markSyncError(entry.patientId, safeMsg);
      onRecordSynced?.call(entry.patientId, false, safeMsg);
      return isNetworkError
          ? _SyncOutcome.networkFailure
          : _SyncOutcome.failure;
    }
  }

  // ── Manual controls ───────────────────────────────────────────────────────

  Future<SyncOneResult> syncOne(String patientId) async {
    if (_isSyncing) return SyncOneResult.busy;

    final entries = await _localDb.getUnsyncedRecords();
    final match = entries.where((e) => e.patientId == patientId);
    if (match.isEmpty) return SyncOneResult.notFound;

    _isSyncing = true;
    try {
      final outcome = await _syncOne(match.first);
      if (outcome == _SyncOutcome.success) {
        return SyncOneResult.success;
      } else {
        return SyncOneResult.failure;
      }
    } finally {
      _isSyncing = false;
      await refreshPendingCount();
    }
  }
}
