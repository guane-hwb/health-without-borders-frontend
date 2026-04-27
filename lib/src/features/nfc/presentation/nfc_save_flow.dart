import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../core/i18n/app_strings.dart';

typedef SyncCallback = Future<void> Function();
Future<void> showNfcSaveFlow(BuildContext context, {SyncCallback? onSync}) {
  return showModalBottomSheet<void>(context: context, isDismissible: false, enableDrag: false,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _NfcSaveFlowSheet(onSync: onSync));
}
enum _SS { put, registering, success, error }
class _NfcSaveFlowSheet extends StatefulWidget {
  const _NfcSaveFlowSheet({this.onSync});
  final SyncCallback? onSync;
  @override State<_NfcSaveFlowSheet> createState() => _NfcSaveFlowSheetState();
}
class _NfcSaveFlowSheetState extends State<_NfcSaveFlowSheet> {
  _SS _state = _SS.put;
  String _err = '';
  Future<void> _start() async {
    setState(() => _state = _SS.registering);
    if (widget.onSync != null) {
      try { await widget.onSync!(); if (mounted) setState(() => _state = _SS.success); }
      catch (e) { if (mounted) setState(() { _state = _SS.error; _err = e.toString(); }); }
    } else { await Future<void>.delayed(const Duration(seconds: 3)); if (mounted) setState(() => _state = _SS.success); }
  }
  @override Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 60, height: 5, decoration: BoxDecoration(color: AppColors.disabled, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 24),
        switch (_state) {
          _SS.put => _buildPut(s),
          _SS.registering => _buildRegistering(s),
          _SS.success => _buildSuccess(s),
          _SS.error => _buildError(s),
        },
      ]));
  }
  Widget _buildPut(AppStrings s) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(s.putOnWristband, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
    const SizedBox(height: 24),
    Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 3)), child: const Icon(Icons.nfc, size: 50, color: AppColors.primary)),
    const SizedBox(height: 20),
    Text(s.placeWristband, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(s.startWriting, style: const TextStyle(color: AppColors.white, fontSize: 14)))),
  ]);
  Widget _buildRegistering(AppStrings s) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(s.syncingServer, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
    const SizedBox(height: 30),
    SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary, backgroundColor: AppColors.primary.withAlpha(40))),
    const SizedBox(height: 24),
    Text(s.pleaseWait, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    const SizedBox(height: 16),
  ]);
  Widget _buildSuccess(AppStrings s) => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.check_circle, size: 80, color: AppColors.success),
    const SizedBox(height: 16),
    Text(s.successRegistration, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
    const SizedBox(height: 10),
    Text(s.patientSavedSynced, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: () { Navigator.of(context).pop(); Navigator.of(context).popUntil((r) => r.isFirst); },
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A396), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(s.goHome, style: const TextStyle(color: AppColors.white, fontSize: 14)))),
  ]);
  Widget _buildError(AppStrings s) => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 80, color: AppColors.error),
    const SizedBox(height: 16),
    Text(s.syncFailed, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.error)),
    const SizedBox(height: 10),
    Text(_err, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), maxLines: 3, overflow: TextOverflow.ellipsis),
    const SizedBox(height: 24),
    Row(children: [
      Expanded(child: SizedBox(height: 40, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(s.cancel)))),
      const SizedBox(width: 12),
      Expanded(child: SizedBox(height: 40, child: ElevatedButton(onPressed: _start, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(s.retry, style: const TextStyle(color: AppColors.white, fontSize: 14))))),
    ]),
  ]);
}