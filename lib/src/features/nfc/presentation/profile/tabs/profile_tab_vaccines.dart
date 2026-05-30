// lib/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
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
    final s = AppStrings.of(context);
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
                  '${s.vaccineSchemeTitle.toUpperCase()} · ${items.length} ${items.length == 1 ? s.vaccineLabelSingle.toUpperCase() : s.vaccineLabelPlural.toUpperCase()}',
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
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB0B8C4),
                    width: 1.5,
                  ),
                ),
                child: ProfileCard(
                  child: Text(
                    s.noVaccinesRegistered,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _VaccineCard(item: items[i]),
                if (i < items.length - 1) const SizedBox(height: 10),
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
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 22, color: AppColors.white),
              label: Text(
                s.addVaccineButton,
                style: const TextStyle(
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
    if (item.date.length < 10) return item.date;
    final datePart = item.date.substring(0, 10);
    final p = datePart.split('-');
    if (p.length != 3) return datePart;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
      ),
      child: ProfileCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
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
                    '${s.doseLabel} ${item.dose} · $_formattedDate · CVX ${item.vaccineCode}',
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
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}
