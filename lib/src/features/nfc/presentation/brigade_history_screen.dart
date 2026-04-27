import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

enum _SyncStatus { pending, synchronizing, synchronized }
class BrigadeHistoryScreen extends StatefulWidget {
  const BrigadeHistoryScreen({super.key});
  @override State<BrigadeHistoryScreen> createState() => _BrigadeHistoryScreenState();
}
class _BrigadeHistoryScreenState extends State<BrigadeHistoryScreen> {
  _SyncStatus _status = _SyncStatus.pending;
  final List<PatientFullRecord> _patients = [];
  @override void initState() { super.initState(); _simulateSync(); }
  void _simulateSync() {
    Future<void>.delayed(const Duration(seconds: 2), () { if (!mounted) return; setState(() => _status = _SyncStatus.synchronizing);
      Future<void>.delayed(const Duration(seconds: 3), () { if (!mounted) return; setState(() => _status = _SyncStatus.synchronized); }); });
  }
  @override Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(child: Stack(children: [
        Column(children: [
          SharedReadNfcHeader(title: s.brigadeHistory, onBack: () => Navigator.of(context).pop()),
          if (_status == _SyncStatus.pending) Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), color: const Color(0xFFFFCE34),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning, size: 20, color: AppColors.white), const SizedBox(width: 8),
              Text(s.brigadeOffline, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600))])),
          const SizedBox(height: 12),
          Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 4))]),
            child: Column(children: [
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _headerColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(children: [const Icon(Icons.format_list_bulleted, size: 20, color: AppColors.white), const SizedBox(width: 8),
                  Text(s.brigadeHistory, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600))])),
              Expanded(child: _patients.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_outline, size: 48, color: AppColors.disabled), const SizedBox(height: 12),
                    Text(s.patientsAppearHere, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))])))
                : ListView.separated(padding: EdgeInsets.zero, itemCount: _patients.length, separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _patients[i];
                      return _PatientRow(name: p.patientInfo.fullName, date: p.patientInfo.dob, status: _status, s: s);
                    })),
            ]))),
          const SizedBox(height: 30),
        ]),
        const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
      ])));
  }
  Color get _headerColor => switch (_status) { _SyncStatus.pending => const Color(0xFFD4A017), _SyncStatus.synchronizing => AppColors.secondary, _SyncStatus.synchronized => const Color(0xFF2E7D32) };
}
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.name, required this.date, required this.status, required this.s});
  final String name, date; final _SyncStatus status; final AppStrings s;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      const Icon(Icons.person, size: 24, color: AppColors.textSecondary), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(text: '${s.patient}:  ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          children: [TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w400))])),
        Text('(${s.dateOfBirth}: $date)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ])),
      Column(children: [
        Icon(_icon, size: 22, color: _color),
        const SizedBox(height: 2),
        Text(_label, style: TextStyle(fontSize: 11, color: _color)),
      ]),
    ]));
  IconData get _icon => switch (status) { _SyncStatus.pending => Icons.cloud_upload_outlined, _SyncStatus.synchronizing => Icons.sync, _SyncStatus.synchronized => Icons.cloud_done };
  Color get _color => switch (status) { _SyncStatus.pending => const Color(0xFFD4A017), _SyncStatus.synchronizing => AppColors.primary, _SyncStatus.synchronized => const Color(0xFF2E7D32) };
  String get _label => switch (status) { _SyncStatus.pending => s.pending, _SyncStatus.synchronizing => s.synchronizing, _SyncStatus.synchronized => s.synchronized };
}