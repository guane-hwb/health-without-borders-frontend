// lib/src/core/sync/sync_engine.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/nfc/data/patient_repository.dart';
import '../../features/nfc/domain/patient_record.dart';
import '../network/api_client.dart';
import '../storage/local_database.dart';
import '../utils/app_logger.dart';

/// Background sync engine that pushes local patient records to the backend.
class SyncEngine {
  SyncEngine({
    required PatientRepository patientRepository,
    LocalDatabase? localDatabase,
    Stream<List<ConnectivityResult>>? connectivityStream,
  }) : _patientRepo = patientRepository,
       _localDb = localDatabase ?? LocalDatabase.instance,
       _connectivityStream = connectivityStream;

  final PatientRepository _patientRepo;
  final LocalDatabase _localDb;
  final Stream<List<ConnectivityResult>>? _connectivityStream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Future<void> refreshPendingCount() async {
    try {
      pendingCount.value = await _localDb.getUnsyncedCount();
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
        AppLogger.d(
          'Conexión detectada. Iniciando sincronización en segundo plano...',
        );
        syncAll();
      }
    });

    syncAll();
  }

  void stop() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  /// Codigos HTTP que indican un error permanente a nivel de datos o conflicto
  /// de manilla, los cuales NO deben reintentarse automaticamente en segundo plano.
  static const Set<int> _permanentErrorCodes = <int>{400, 409, 422};

  Future<void> syncAll() async {
    await refreshPendingCount();
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final List<LocalPatientEntry> allUnsynced = await _localDb
          .getUnsyncedRecords();

      final pending = allUnsynced.where((entry) {
        final code = entry.syncErrorCode;
        return code == null || !_permanentErrorCodes.contains(code);
      }).toList();

      AppLogger.d('Iniciando syncAll: ${pending.length} registros pendientes.');

      for (final entry in pending) {
        await _syncOne(entry);
      }

      final remaining = await _localDb.getUnsyncedCount();
      pendingCount.value = remaining;
      onSyncStatusChanged?.call(remaining);
    } catch (e, stack) {
      AppLogger.e('Error crítico durante syncAll', error: e, stackTrace: stack);
    } finally {
      _isSyncing = false;
      await refreshPendingCount();
    }
  }

  Future<void> _syncOne(LocalPatientEntry entry) async {
    final PatientFullRecord? record = entry.toPatientRecord();
    if (record == null) {
      AppLogger.e('Omitiendo registro corrupto con ID: ${entry.patientId}');
      return;
    }

    try {
      final PatientSyncResponse response = await _patientRepo.syncPatient(
        record,
      );

      if (response.status == 'success') {
        AppLogger.d('Registro sincronizado exitosamente: ${entry.patientId}');
        await _localDb.markSynced(entry.patientId, createdAt: entry.createdAt);
        onRecordSynced?.call(entry.patientId, true, null);
      } else {
        AppLogger.e(
          'Fallo en sincronización para ${entry.patientId}: ${response.message}',
        );
        await _localDb.markSyncError(
          entry.patientId,
          'Sync returned status: ${response.status}',
        );
        onRecordSynced?.call(entry.patientId, false, response.message);
      }
    } on ApiException catch (e) {
      final shouldStopAll = e.statusCode == 401;
      final shouldNotRetry =
          e.statusCode == 400 || e.statusCode == 409 || e.statusCode == 422;

      AppLogger.e(
        'ApiException (${e.statusCode}) sincronizando ${entry.patientId}: ${e.message}',
      );

      await _localDb.markSyncError(
        entry.patientId,
        e.message,
        statusCode: e.statusCode,
      );
      onRecordSynced?.call(entry.patientId, false, e.message);

      if (shouldStopAll || shouldNotRetry) {
        return;
      }
    } catch (e, stack) {
      AppLogger.e(
        'Error no controlado sincronizando ${entry.patientId}',
        error: e,
        stackTrace: stack,
      );
      await _localDb.markSyncError(entry.patientId, '$e');
      onRecordSynced?.call(entry.patientId, false, '$e');
    }
  }

  // ── Manual controls ───────────────────────────────────────────────────────

  Future<bool> syncOne(String patientId) async {
    final entries = await _localDb.getUnsyncedRecords();
    final match = entries.where((e) => e.patientId == patientId);
    if (match.isEmpty) return false;

    await _syncOne(match.first);
    final updated = await _localDb.getUnsyncedRecords();
    await refreshPendingCount();
    return !updated.any((e) => e.patientId == patientId);
  }
}
