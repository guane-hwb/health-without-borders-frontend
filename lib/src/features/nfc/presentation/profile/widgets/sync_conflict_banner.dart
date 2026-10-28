// lib/src/features/nfc/presentation/profile/widgets/sync_conflict_banner.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/di/app_scope.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../../../../core/storage/local_database.dart';
import '../../../../../core/sync/sync_conflicts.dart';
import '../../../../../core/sync/sync_engine.dart';
import '../../../../../design/tokens/app_colors.dart';

/// What the server did not take from this patient's syncs. It is the same
/// notice the sync queue lists: dismissing it here removes it there too.
class SyncConflictBanner extends StatefulWidget {
  const SyncConflictBanner({
    super.key,
    required this.patientId,
    required this.serverCopyShown,
  });

  final String patientId;

  /// The profile shows the record as the server has it.
  final bool serverCopyShown;

  @override
  State<SyncConflictBanner> createState() => _SyncConflictBannerState();
}

class _SyncConflictBannerState extends State<SyncConflictBanner> {
  SyncNotice? _notice;
  StreamSubscription<RecordSyncResult>? _savedRecordsSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_savedRecordsSub != null) return;
    // The engine stores the notice before it announces the record.
    _savedRecordsSub = AppScope.of(context).syncEngine.savedRecords
        .where(
          (RecordSyncResult r) =>
              r.patientId == widget.patientId && r.hasConflicts,
        )
        .listen((_) => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    _savedRecordsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final List<SyncNotice> notices = await scope.localDatabase.getSyncNotices(
      ownerUserId: scope.authRepository.currentUser?.id,
    );
    if (!mounted) return;
    setState(() {
      _notice = notices
          .where((SyncNotice n) => n.patientId == widget.patientId)
          .firstOrNull;
    });
  }

  Future<void> _dismiss() async {
    final LocalDatabase db = AppScope.of(context).localDatabase;
    setState(() => _notice = null);
    await db.dismissSyncNotice(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final SyncNotice? notice = _notice;
    if (notice == null) return const SizedBox.shrink();
    final bool isEs = AppStrings.of(context).isEs;
    const TextStyle style = TextStyle(fontSize: 13, color: Color(0xFF7A4F00));

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4E5),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 20, color: Color(0xFFB26A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isEs
                      ? 'El servidor no aplicó todos los cambios'
                      : 'The server did not apply every change',
                  style: style.copyWith(fontWeight: FontWeight.w700),
                ),
                for (final String line in SyncConflictCode.describe(
                  notice.codes,
                  isEs: isEs,
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line, style: style),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    SyncConflictCode.nextStep(
                      serverCopyShown: widget.serverCopyShown,
                      isEs: isEs,
                    ),
                    style: style.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _dismiss,
                    child: Text(
                      isEs ? 'Entendido' : 'Got it',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
