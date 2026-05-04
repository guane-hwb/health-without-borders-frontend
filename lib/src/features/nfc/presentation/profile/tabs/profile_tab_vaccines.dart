// lib/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/profile_card.dart';

class ProfileTabVaccines extends StatelessWidget {
  const ProfileTabVaccines({
    super.key,
    required this.draft,
    required this.onAdd,
  });

  final PatientFullRecord draft;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final items = [...draft.vaccinationRecord]
      ..sort((a, b) => a.date.compareTo(b.date));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.vaccines_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'ESQUEMA · ${items.length} VACUNA${items.length == 1 ? '' : 'S'}',
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
                  'Sin vacunas registradas.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _VaccineCard(item: items[i]),
                if (i < items.length - 1) const SizedBox(height: 8),
              ],
          ],
        ),
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
                'Registrar vacuna',
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

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.item});
  final VaccinationRecordItem item;

  String get _formattedDate {
    if (!item.date.contains('-')) return item.date;
    final p = item.date.split('-');
    if (p.length != 3) return item.date;
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
    final m = int.tryParse(p[1]);
    if (m == null || m < 1 || m > 12) return item.date;
    return '${int.parse(p[2])} ${months[m - 1]}. de ${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.vaccines,
              size: 18,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.vaccineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Dosis ${item.dose} · $_formattedDate · CVX ${item.vaccineCode}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.administratedAt.isNotEmpty)
                  Text(
                    item.administratedAt,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (item.status == 'completed')
            const Icon(Icons.check_circle, size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}
