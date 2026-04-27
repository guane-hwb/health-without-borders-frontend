// lib/src/features/nfc/presentation/profile/tabs/profile_tab_consultations.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/profile_card.dart';

class ProfileTabConsultations extends StatelessWidget {
  const ProfileTabConsultations({
    super.key,
    required this.draft,
    required this.canAdd,
    required this.onAdd,
  });

  final PatientFullRecord draft;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final items = [...draft.medicalHistory]
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'CONSULTAS · ${items.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              ProfileCard(
                child: const Text(
                  'Sin consultas registradas.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _ConsultationCard(item: items[i]),
                if (i < items.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
        if (canAdd)
          Positioned(
            left: 14,
            right: 14,
            bottom: 30,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 22, color: AppColors.white),
                label: const Text(
                  'Agregar consulta',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.item});
  final MedicalHistoryItem item;

  String get _formattedDate {
    try {
      final dt = DateTime.parse(item.startDateTime);
      const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      const months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return item.startDateTime;
    }
  }

  String get _formattedTime {
    try {
      final dt = DateTime.parse(item.startDateTime);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h < 12 ? 'a.m.' : 'p.m.';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $period';
    } catch (_) {
      return '';
    }
  }

  String get _modalityLabel {
    switch (item.careModality) {
      case '01':
        return 'Intramural';
      case '02':
        return 'Extramural';
      case '03':
        return 'Telemedicina';
      case '04':
        return 'Telexperticia';
      case '05':
        return 'Telemonitoreo';
      default:
        return item.careModality;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summaryText();
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + modality row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_formattedTime.isNotEmpty)
                      Text(
                        '$_formattedTime'
                        '${item.provider?.name != null ? ' · ${item.provider!.name}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _modalityLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.isNotEmpty)
            Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          if (item.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.diagnosis
                  .map((d) => _DiagnosisChip(d: d))
                  .toList(),
            ),
          ],
          if (item.practitioner != null &&
              item.practitioner!.name.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  item.practitioner!.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _summaryText() {
    final eval = item.clinicalEvaluation;
    if (eval.historyOfCurrentIllness?.isNotEmpty == true) {
      return eval.historyOfCurrentIllness!;
    }
    if (eval.treatmentPlanObservations?.isNotEmpty == true) {
      return eval.treatmentPlanObservations!;
    }
    return '';
  }
}

class _DiagnosisChip extends StatelessWidget {
  const _DiagnosisChip({required this.d});
  final DiagnosisItem d;

  @override
  Widget build(BuildContext context) {
    final label = '${d.icd10Code} ${d.description}'.trim();
    final shown = label.length > 36 ? '${label.substring(0, 36)}...' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medical_information_outlined,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            shown,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
