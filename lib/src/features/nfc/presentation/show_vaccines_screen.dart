import 'package:flutter/material.dart';
import '../../../core/i18n/app_strings.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'edit_vaccine_sheet.dart';
import 'shared_read_nfc_header.dart';

class ShowVaccinesScreen extends StatelessWidget {
  const ShowVaccinesScreen({super.key, required this.patient});
  final PatientFullRecord patient;
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
                  title: s.vaccines,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 44),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Text(
                          s.vaccines,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...patient.vaccinationRecord.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _VaccCard(v: v, s: s),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 18,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: () => _openAdd(context),
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.add, color: AppColors.white),
              ),
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

  void _openAdd(BuildContext ctx) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const EditVaccineSheet(),
    );
  }
}

class _VaccCard extends StatelessWidget {
  const _VaccCard({required this.v, required this.s});
  final VaccinationRecordItem v;
  final AppStrings s;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24000000),
          blurRadius: 10,
          offset: Offset(1, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vaccines, size: 20, color: AppColors.white),
              const SizedBox(width: 8),
              Text(
                '${s.vaccine}: ${v.vaccineName}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.dose}: ${v.dose}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.date}: ${v.date}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${s.administeredBy}: ${v.administratedBy}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.administeredAt}: ${v.administratedAt}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
