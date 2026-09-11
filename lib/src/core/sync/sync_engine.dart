// lib/src/core/sync/sync_engine.dart

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_repository.dart';
import '../../features/nfc/data/patient_repository.dart';
import '../../features/nfc/domain/patient_record.dart';
import '../network/api_client.dart';
import '../network/reachability.dart';
import '../storage/local_database.dart';
import '../utils/app_logger.dart';

enum SyncOneResult { success, failure, busy, notFound }

enum _SyncOutcome { success, failure, networkFailure, abortBatch }

/// Motor de sincronización en segundo plano que envía registros locales al backend.
class SyncEngine {
  SyncEngine({
    required PatientRepository patientRepository,
    AuthRepository? authRepository,
    LocalDatabase? localDatabase,
    Stream<List<ConnectivityResult>>? connectivityStream,
    Reachability? reachability,
    List<Duration>? retryBackoff,
  }) : _patientRepo = patientRepository,
       _authRepo = authRepository,
       _localDb = localDatabase ?? LocalDatabase.instance,
       _connectivityStream = connectivityStream,
       _reachability = reachability,
       _retryBackoff = retryBackoff ?? _defaultRetryBackoff;

  final PatientRepository _patientRepo;
  final AuthRepository? _authRepo;
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

  Future<bool>? _activeSyncAllFuture;
  Completer<void>? _syncOneCompletion;
  bool get _syncOneRunning => _syncOneCompletion != null;
  Duration? _pendingServerRetryAfter;

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<int> blockedCount = ValueNotifier<int>(0);
  final ValueNotifier<int> totalCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  String? get _currentUserId => _authRepo?.currentUser?.id;

  Future<void> refreshPendingCount() async {
    try {
      final retryable = await _localDb.getRetryablePendingCount(
        ownerUserId: _currentUserId,
      );
      final blocked = await _localDb.getBlockedCount(
        ownerUserId: _currentUserId,
      );

      pendingCount.value = retryable;
      blockedCount.value = blocked;
      totalCount.value = retryable + blocked;
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

      isOnline.value = hasConnection;

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
    _retryTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;

    if (pendingCount.value <= 0) {
      _retryAttempt = 0;
      _pendingServerRetryAfter = null;
      return;
    }

    final Duration backoff =
        _retryBackoff[_retryAttempt.clamp(0, _retryBackoff.length - 1)];

    final Duration? serverHint = _pendingServerRetryAfter;
    _pendingServerRetryAfter = null;
    final Duration delay = (serverHint != null && serverHint > backoff)
        ? serverHint
        : backoff;

    _retryAttempt++;
    AppLogger.d(
      serverHint != null && serverHint > backoff
          ? 'Reintento de sincronización programado en $delay (Retry-After del servidor).'
          : 'Reintento de sincronización programado en $delay.',
    );
    _retryTimer = Timer(delay, syncAll);
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  Future<bool> syncAll() {
    if (_activeSyncAllFuture != null) {
      AppLogger.d(
        'syncAll en ejecución: uniendo llamada al ciclo en curso (single-flight).',
      );
      return _activeSyncAllFuture!;
    }

    final completer = Completer<bool>();
    _activeSyncAllFuture = completer.future;

    final Completer<void>? syncOneInFlight = _syncOneCompletion;
    final Future<bool> Function() startCycle = _executeSyncAll;

    if (syncOneInFlight != null) {
      AppLogger.d('syncAll en espera: syncOne en ejecución.');
      syncOneInFlight.future
          .catchError((_) {})
          .then((_) => startCycle())
          .then(completer.complete)
          .catchError((Object e, StackTrace st) {
            completer.completeError(e, st);
          })
          .whenComplete(() {
            _activeSyncAllFuture = null;
          });
      return _activeSyncAllFuture!;
    }

    startCycle()
        .then((result) {
          completer.complete(result);
        })
        .catchError((Object e, StackTrace st) {
          completer.completeError(e, st);
        })
        .whenComplete(() {
          _activeSyncAllFuture = null;
        });

    return _activeSyncAllFuture!;
  }

  Future<bool> _executeSyncAll() async {
    if (_currentUserId == null) {
      AppLogger.d('syncAll omitido: no hay sesión activa.');
      return false;
    }

    await refreshPendingCount();
    await _syncEmergencyLogs();
    await _syncNfcKeyVersions();

    bool allSuccessful = true;

    try {
      if (_reachability != null && !await _reachability.probe()) {
        AppLogger.d('Backend inalcanzable. Se omite el lote.');
        return false;
      }

      final List<LocalPatientEntry> allUnsynced = await _localDb
          .getUnsyncedRecords(ownerUserId: _currentUserId);

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
              'Red/Servidor inalcanzable: abandonando el lote tras $consecutiveNetworkFailures fallos de red/5xx consecutivos.',
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

      final remaining = await _localDb.getRetryablePendingCount(
        ownerUserId: _currentUserId,
      );
      onSyncStatusChanged?.call(remaining);

      return allSuccessful && remaining == 0;
    } catch (e, stack) {
      AppLogger.e('Error crítico durante syncAll', error: e, stackTrace: stack);
      return false;
    } finally {
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
        revision: entry.revision,
      );
      return _SyncOutcome.failure;
    }

    try {
      final PatientSyncResponse response =
          (entry.retiredDeviceReason != null &&
              entry.retiredDeviceReason!.isNotEmpty)
          ? await _patientRepo.syncPatient(
              record,
              retiredDeviceReason: entry.retiredDeviceReason,
            )
          : await _patientRepo.syncPatient(record);

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
        await _localDb.markSyncError(
          entry.patientId,
          errorMsg,
          revision: entry.revision,
        );
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

      final bool isTransientServerError =
          e.statusCode == 408 ||
          e.statusCode == 429 ||
          (e.statusCode != null &&
              e.statusCode! >= 500 &&
              e.statusCode! <= 599);

      final String safeMsg = (e.statusCode == 409)
          ? 'Registro duplicado (409): El chip NFC ya pertenece a otro paciente'
          : (e.statusCode == 422)
          ? 'Error de validación (422): Campos incompatibles con el backend'
          : e.message;

      await _localDb.markSyncError(
        entry.patientId,
        safeMsg,
        statusCode: e.statusCode,
        revision: entry.revision,
      );

      onRecordSynced?.call(entry.patientId, false, safeMsg);

      if (isTransientServerError && e.retryAfter != null) {
        final Duration hint = e.retryAfter!;
        if (_pendingServerRetryAfter == null ||
            hint > _pendingServerRetryAfter!) {
          _pendingServerRetryAfter = hint;
        }
      }
      return isTransientServerError
          ? _SyncOutcome.networkFailure
          : _SyncOutcome.failure;
    } catch (e, stack) {
      AppLogger.e(
        'Error no controlado sincronizando ${entry.patientId}',
        error: e,
        stackTrace: stack,
      );

      final bool isSocketException =
          e is SocketException || e.toString().contains('SocketException');
      final bool isTimeout = e is TimeoutException;

      final bool isNetworkError =
          (isSocketException || isTimeout || e is http.ClientException) &&
          isOnline.value;

      final String safeMsg = isSocketException
          ? 'Error de conexión de red (Socket)'
          : isTimeout
          ? 'Tiempo de espera agotado (Timeout)'
          : 'Error en proceso de sincronización';

      await _localDb.markSyncError(
        entry.patientId,
        safeMsg,
        revision: entry.revision,
      );
      onRecordSynced?.call(entry.patientId, false, safeMsg);

      return isNetworkError
          ? _SyncOutcome.networkFailure
          : _SyncOutcome.failure;
    }
  }

  // ── Manual controls ───────────────────────────────────────────────────────

  Future<SyncOneResult> syncOne(String patientId) async {
    if (_activeSyncAllFuture != null || _syncOneRunning) {
      return SyncOneResult.busy;
    }
    final Completer<void> completion = Completer<void>();
    _syncOneCompletion = completion;

    try {
      final entries = await _localDb.getUnsyncedRecords(
        ownerUserId: _currentUserId,
      );
      final match = entries.where((e) => e.patientId == patientId);
      if (match.isEmpty) return SyncOneResult.notFound;

      final outcome = await _syncOne(match.first);
      if (outcome == _SyncOutcome.success) {
        return SyncOneResult.success;
      } else {
        return SyncOneResult.failure;
      }
    } finally {
      _syncOneCompletion = null;
      completion.complete();
      await refreshPendingCount();
    }
  }

  /// Ships pending NFC key version sightings.
  ///
  /// Best-effort like the audit log: a failure here delays a rotation decision,
  /// never a clinical action, so it must not abort the batch.
  Future<void> _syncNfcKeyVersions() async {
    try {
      final pending = await _localDb.pendingNfcKeyVersions();
      if (pending.isEmpty) return;

      await _patientRepo.reportNfcKeyVersions(pending);

      final uids = pending
          .map((Map<String, Object?> r) => r['device_uid'] as String?)
          .whereType<String>()
          .toList();
      await _localDb.markNfcKeyVersionsSynced(uids);
      AppLogger.d('Versiones de llave NFC reportadas: ${uids.length}');
    } catch (e, stack) {
      AppLogger.e(
        'Error reportando versiones de llave NFC',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _syncEmergencyLogs() async {
    final ownerUserId = _currentUserId;
    if (ownerUserId == null) return;
    try {
      final pending = await _localDb.pendingEmergencyAccessLogs(
        ownerUserId: ownerUserId,
      );
      if (pending.isEmpty) return;

      await _patientRepo.reportEmergencyAccess(pending);

      final ids = pending
          .map((r) => (r['id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      await _localDb.markEmergencyLogsSynced(ids);
      AppLogger.d('Logs de emergencia sincronizados: ${ids.length}');
    } catch (e, stack) {
      AppLogger.e(
        'Error sincronizando logs de acceso de emergencia',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
