import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/storage/local_database.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/read_nfc_guardian_screen.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';

/// "Review Before Upload" screen — integration guide section 3.3.
///
/// Lists all local records pending sync with:
///   - Masked patient name ("Sofía G.")
///   - Record creation date
///   - Sync status (pending / error)
///   - "Sync Now" and "Review" buttons per record
class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});
  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  List<LocalPatientEntry> _entries = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntries());
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await AppScope.of(context).localDatabase.getUnsyncedRecords();
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  Future<void> _syncAll() async {
    setState(() => _isSyncing = true);
    await AppScope.of(context).syncEngine.syncAll();
    await _loadEntries();
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _syncOne(String patientId) async {
    final success = await AppScope.of(context).syncEngine.syncOne(patientId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Synced successfully' : 'Sync failed — will retry'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
      _loadEntries();
    }
  }

  void _reviewRecord(LocalPatientEntry entry) {
    final record = entry.toPatientRecord();
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record data not available for review.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReadNfcGuardianScreen(patient: record)),
    );
  }

  Future<void> _deleteRecord(LocalPatientEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('This will permanently delete the local record for ${entry.maskedName}. '
            'If it hasn\'t been synced, the data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AppScope.of(context).localDatabase.deleteRecord(entry.patientId);
      if (mounted) _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            const SharedReadNfcHeader(title: 'Sync Queue'),
            // Back button + Sync All
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(children: [
                SizedBox(height: 33, child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A396),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  icon: const Icon(Icons.arrow_back_ios, size: 15, color: AppColors.white),
                  label: const Text('Back', style: TextStyle(color: AppColors.white, fontSize: 14)),
                )),
                const Spacer(),
                if (_entries.isNotEmpty)
                  SizedBox(height: 33, child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncAll,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.disabled,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14)),
                    icon: _isSyncing
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.cloud_upload, size: 18, color: AppColors.white),
                    label: const Text('Sync All', style: TextStyle(color: AppColors.white, fontSize: 14)),
                  )),
              ]),
            ),
            const SizedBox(height: 14),

            // Content
            Expanded(child: _buildContent()),
          ]),
          const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_done, size: 80, color: AppColors.success.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        const Text('All records synced', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text('No pending records to upload.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 60),
      itemCount: _entries.length,
      itemBuilder: (_, i) => _SyncQueueCard(
        entry: _entries[i],
        onSync: () => _syncOne(_entries[i].patientId),
        onReview: () => _reviewRecord(_entries[i]),
        onDelete: () => _deleteRecord(_entries[i]),
      ),
    );
  }
}

class _SyncQueueCard extends StatelessWidget {
  const _SyncQueueCard({
    required this.entry,
    required this.onSync,
    required this.onReview,
    required this.onDelete,
  });

  final LocalPatientEntry entry;
  final VoidCallback onSync;
  final VoidCallback onReview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasError = entry.syncError != null && entry.syncError!.isNotEmpty;
    final dateStr = entry.createdAt.contains('T')
        ? entry.createdAt.split('T').first
        : entry.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasError ? Border.all(color: AppColors.error.withValues(alpha: 0.4)) : null,
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(children: [
              const CircleAvatar(
                radius: 18, backgroundColor: Color(0xFF90CAF9),
                child: Icon(Icons.person, size: 22, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.maskedName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text('Created: $dateStr',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              )),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasError ? const Color(0xFFFEE2E2) : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasError ? 'Error' : 'Pending',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: hasError ? AppColors.error : const Color(0xFF856404),
                  ),
                ),
              ),
            ]),
          ),

          // Error message
          if (hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(entry.syncError!,
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(children: [
              _actionButton(Icons.cloud_upload, 'Sync Now', AppColors.primary, onSync),
              const SizedBox(width: 8),
              _actionButton(Icons.visibility, 'Review', AppColors.secondary, onReview),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(height: 30, child: ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      icon: Icon(icon, size: 14, color: AppColors.white),
      label: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 11)),
    ));
  }
}