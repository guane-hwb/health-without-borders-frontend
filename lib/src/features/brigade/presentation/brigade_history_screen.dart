import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';

enum _SyncStatus { pending, synchronizing, synchronized }

class BrigadeHistoryScreen extends StatefulWidget {
  const BrigadeHistoryScreen({super.key});

  @override
  State<BrigadeHistoryScreen> createState() => _BrigadeHistoryScreenState();
}

class _BrigadeHistoryScreenState extends State<BrigadeHistoryScreen> {
  _SyncStatus _status = _SyncStatus.pending;

  static const List<_PatientEntry> _patients = <_PatientEntry>[
    _PatientEntry(name: 'Carlos Gomez', date: '20/02/2026'),
    _PatientEntry(name: 'Camila Torres', date: '20/02/2026'),
    _PatientEntry(name: 'Ivan Giraldo', date: '20/02/2026'),
    _PatientEntry(name: 'Sara Cortez', date: '20/02/2026'),
    _PatientEntry(name: 'Juan Manuel Rios', date: '20/02/2026'),
    _PatientEntry(name: 'Martin Linarez', date: '20/02/2026'),
    _PatientEntry(name: 'Maria Rojas', date: '20/02/2026'),
    _PatientEntry(name: 'Laura Carvajal', date: '20/02/2026'),
  ];

  @override
  void initState() {
    super.initState();
    _simulateSync();
  }

  void _simulateSync() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _status = _SyncStatus.synchronizing);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _status = _SyncStatus.synchronized);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SharedReadNfcHeader(title: 'Brigade History'),
                if (_status == _SyncStatus.pending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: const Color(0xFFFFCE34),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 20, color: AppColors.white),
                        SizedBox(width: 8),
                        Text(
                          'Brigade Mode - Offline',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 33,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A396),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.arrow_back_ios,
                            size: 15, color: AppColors.white),
                        label: const Text(
                          'Back',
                          style:
                              TextStyle(color: AppColors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 10,
                          offset: Offset(1, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _headerColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.format_list_bulleted,
                                  size: 20, color: AppColors.white),
                              SizedBox(width: 8),
                              Text(
                                'Brigade History',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _patients.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, int index) {
                              return _PatientRow(
                                patient: _patients[index],
                                status: _status,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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

  Color get _headerColor {
    switch (_status) {
      case _SyncStatus.pending:
        return const Color(0xFFD4A017);
      case _SyncStatus.synchronizing:
        return AppColors.secondary;
      case _SyncStatus.synchronized:
        return const Color(0xFF2E7D32);
    }
  }
}

class _PatientEntry {
  const _PatientEntry({required this.name, required this.date});

  final String name;
  final String date;
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient, required this.status});

  final _PatientEntry patient;
  final _SyncStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Patient:  ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: patient.name,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Text(
                  '(Date: ${patient.date})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(_statusIcon, size: 22, color: _statusColor),
              const SizedBox(height: 2),
              Text(
                _statusLabel,
                style: TextStyle(fontSize: 11, color: _statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    switch (status) {
      case _SyncStatus.pending:
        return Icons.cloud_upload_outlined;
      case _SyncStatus.synchronizing:
        return Icons.sync;
      case _SyncStatus.synchronized:
        return Icons.cloud_done;
    }
  }

  Color get _statusColor {
    switch (status) {
      case _SyncStatus.pending:
        return const Color(0xFFD4A017);
      case _SyncStatus.synchronizing:
        return AppColors.primary;
      case _SyncStatus.synchronized:
        return const Color(0xFF2E7D32);
    }
  }

  String get _statusLabel {
    switch (status) {
      case _SyncStatus.pending:
        return 'Pending';
      case _SyncStatus.synchronizing:
        return 'synchronizing';
      case _SyncStatus.synchronized:
        return 'Syncronized';
    }
  }
}
