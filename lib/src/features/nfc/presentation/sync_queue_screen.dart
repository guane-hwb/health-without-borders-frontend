import 'package:flutter/material.dart'; // ← ¡Esta es la línea clave que se había perdido!

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/local_database.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'read_nfc_guardian_screen.dart';
import 'shared_read_nfc_header.dart';

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
    final e = await AppScope.of(context).localDatabase.getUnsyncedRecords();

    if (mounted) {
      setState(() {
        _entries = e;
        _loading = false;
      });
    }
  }

  Future<void> _syncAll() async {
    setState(() => _syncing = true);
    await AppScope.of(context).syncEngine.syncAll();
    await _load();
    if (mounted) {
      setState(() => _syncing = false);
    }
  }

  Future<void> _syncOne(String id) async {
    final ok = await AppScope.of(context).syncEngine.syncOne(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? AppStrings.of(context).syncedSuccessfully
                : AppStrings.of(context).syncFailedRetry,
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
      _load();
    }
  }

  void _review(LocalPatientEntry e) {
    final r = e.toPatientRecord();
    if (r == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReadNfcGuardianScreen(patient: r)),
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
                SharedReadNfcHeader(
                  title: s.syncTitle,
                  onBack: () => Navigator.of(context).pop(),
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
    final hasErr = entry.syncError?.isNotEmpty == true;
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
                    hasErr ? s.error : s.pending,
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
          if (hasErr)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(
                entry.syncError!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                _btn(Icons.cloud_upload, s.syncNow, AppColors.primary, onSync),
                const SizedBox(width: 8),
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
