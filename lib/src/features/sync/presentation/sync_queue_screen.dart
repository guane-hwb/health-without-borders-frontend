// lib/src/features/sync/presentation/sync_queue_screen.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/profile/patient_profile_screen.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});
  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  List<LocalPatientEntry> _entries = [];
  bool _loading = true, _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final scope = AppScope.of(context);
    final e = await scope.localDatabase.getUnsyncedRecords();

    if (mounted) {
      setState(() {
        _entries = e;
        _loading = false;
      });
      await scope.syncEngine.refreshPendingCount();
    }
  }

  Future<void> _syncAll() async {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final messenger = ScaffoldMessenger.of(context);
    final scope = AppScope.of(context);

    final netResult = await Connectivity().checkConnectivity();
    final reachable =
        !netResult.contains(ConnectivityResult.none) &&
        await scope.reachability.probe();

    if (!reachable) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Sin conexión a Internet. Conéctese a una red para sincronizar.'
                  : 'No internet connection. Connect to a network to sync.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _syncing = true);
    try {
      await scope.syncEngine.syncAll();
      await _load();
      if (mounted) {
        final remaining = _entries.length;
        if (remaining == 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(s.syncedSuccessfully),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isEs
                    ? 'Quedan $remaining registros pendientes por sincronizar.'
                    : '$remaining records remain pending.',
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Fallo al sincronizar. Intente de nuevo más tarde.'
                  : 'Sync failed. Please try again later.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _syncOne(String id) async {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final messenger = ScaffoldMessenger.of(context);
    final scope = AppScope.of(context);

    final netResult = await Connectivity().checkConnectivity();
    final reachable =
        !netResult.contains(ConnectivityResult.none) &&
        await scope.reachability.probe();

    if (!reachable) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEs ? 'Sin conexión a Internet.' : 'No internet connection.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final result = await scope.syncEngine.syncOne(id);
    if (mounted) {
      final (String message, Color color) = switch (result) {
        SyncOneResult.success => (s.syncedSuccessfully, AppColors.success),
        SyncOneResult.notFound => (s.syncedSuccessfully, AppColors.success),
        SyncOneResult.busy => (s.synchronizing, AppColors.secondary),
        SyncOneResult.failure => (s.syncFailedRetry, AppColors.error),
      };
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
      _load();
    }
  }

  void _review(LocalPatientEntry e) {
    final r = e.toPatientRecord();
    if (r == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientProfileScreen(patient: r, readOnly: true),
      ),
    );
  }

  Future<void> _delete(LocalPatientEntry e) async {
    final s = AppStrings.of(context);
    final db = AppScope.of(context).localDatabase;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteRecord),
        content: Text('${s.deleteRecordConfirm}\n\n${e.maskedName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await db.deleteRecord(e.patientId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.syncTitle,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _LocaleSwitcher(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      const SizedBox(),
                      const Spacer(),
                      if (_entries.isNotEmpty)
                        SizedBox(
                          height: 33,
                          child: ElevatedButton.icon(
                            onPressed: _syncing ? null : _syncAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.disabled,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            icon: _syncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.cloud_upload,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                            label: Text(
                              s.syncAll,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 80,
                                color: AppColors.success.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.allSynced,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.noRecordsPending,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 60),
                          itemCount: _entries.length,
                          itemBuilder: (_, i) => _SyncCard(
                            entry: _entries[i],
                            s: s,
                            onSync: () => _syncOne(_entries[i].patientId),
                            onReview: () => _review(_entries[i]),
                            onDelete: () => _delete(_entries[i]),
                          ),
                        ),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocaleSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context).locale;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['es', 'en'].map((lang) {
          final selected = locale == lang;
          return GestureDetector(
            onTap: () => AppLocale.of(context).setLocale(lang),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.entry,
    required this.s,
    required this.onSync,
    required this.onReview,
    required this.onDelete,
  });
  final LocalPatientEntry entry;
  final AppStrings s;
  final VoidCallback onSync, onReview, onDelete;

  @override
  Widget build(BuildContext context) {
    final isConflict = entry.syncErrorCode == 409;
    final hasErr = entry.syncError?.isNotEmpty == true;
    final isEs = s.isEs;

    String? errorMessage;
    if (hasErr) {
      if (isConflict) {
        errorMessage = isEs
            ? 'Esta manilla ya está registrada para otro paciente. Registra al paciente con una manilla nueva.'
            : 'This bracelet is already registered to another patient. Register the patient with a new bracelet.';
      } else if (entry.syncErrorCode == 403) {
        errorMessage = isEs
            ? 'Acceso denegado (403): Tu rol no permite registrar historia médica completa.'
            : 'Access denied (403): Your role cannot register full medical history.';
      } else if (entry.syncErrorCode == 422) {
        errorMessage = isEs
            ? 'Error de validación (422): El registro contiene campos incompatibles con el backend.'
            : 'Validation error (422): The record contains incompatible fields.';
      } else {
        errorMessage = entry.syncError;
      }
    }

    final String badgeLabel = hasErr
        ? (isConflict
              ? (isEs ? 'Duplicado' : 'Duplicate')
              : (isEs ? 'Error' : 'Error'))
        : s.pending;

    final date = entry.createdAt.contains('T')
        ? entry.createdAt.split('T').first
        : entry.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasErr
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF90CAF9),
                  child: Icon(Icons.person, size: 22, color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.maskedName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasErr
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasErr ? AppColors.error : const Color(0xFF856404),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 15,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                if (!isConflict) ...[
                  _btn(
                    Icons.cloud_upload,
                    s.syncNow,
                    AppColors.primary,
                    onSync,
                  ),
                  const SizedBox(width: 8),
                ],
                _btn(Icons.visibility, s.review, AppColors.secondary, onReview),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: s.delete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) =>
      SizedBox(
        height: 30,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: Icon(icon, size: 14, color: AppColors.white),
          label: Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 11),
          ),
        ),
      );
}
