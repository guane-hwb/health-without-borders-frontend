// lib/src/features/nfc/presentation/profile/sheets/background_manage_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';

class BackgroundManageSheet extends StatelessWidget {
  const BackgroundManageSheet({
    super.key,
    required this.draft,
    required this.onAddChronic,
    required this.onRemoveChronic,
    required this.onEditPersonal,
    required this.onAddFamily,
    required this.onRemoveFamily,
    required this.onAddMedication,
    required this.onRemoveMedication,
  });
  final PatientFullRecord draft;
  final VoidCallback onAddChronic;
  final void Function(int) onRemoveChronic;
  final VoidCallback onEditPersonal;
  final VoidCallback onAddFamily;
  final void Function(int) onRemoveFamily;
  final VoidCallback onAddMedication;
  final void Function(int) onRemoveMedication;

  @override
  Widget build(BuildContext context) {
    final bg = draft.backgroundHistory;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_edu_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.of(context).backgroundSheetTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).chronicConditions,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddChronic,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.chronicConditions.isEmpty)
                    Text(
                      AppStrings.of(context).noChronicConditions,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.chronicConditions.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.chronicConditions[i].chronicDescription,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (bg
                                          .chronicConditions[i]
                                          .chronicCie10Code !=
                                      null)
                                    Text(
                                      '${AppStrings.of(context).cie10Label}${bg.chronicConditions[i].chronicCie10Code}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveChronic(i),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                  _BgSection(
                    title: AppStrings.of(context).personalHistoryTitle,
                    value: bg?.personalHistory,
                    onEdit: onEditPersonal,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).medications,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddMedication,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.medications.isEmpty)
                    Text(
                      AppStrings.of(context).noMedications,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.medications.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.medications[i].medicationName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _medStatusLabel(
                                          context,
                                          bg.medications[i].status,
                                        ) +
                                        (bg.medications[i].dosage != null
                                            ? ' · ${bg.medications[i].dosage}'
                                            : ''),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveMedication(i),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).familyHistory,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddFamily,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.familyHistory.isEmpty)
                    Text(
                      AppStrings.of(context).noFamilyHistoryEntries,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.familyHistory.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.familyHistory[i].conditionDescription,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _relLabel(
                                      context,
                                      bg.familyHistory[i].relationship,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveFamily(i),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relLabel(BuildContext context, String r) {
    final s = AppStrings.of(context);
    switch (r) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return r;
    }
  }

  String _medStatusLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    switch (c) {
      case 'active':
        return s.medStatusActive;
      case 'completed':
        return s.medStatusCompleted;
      case 'stopped':
        return s.medStatusStopped;
      case 'unknown':
        return s.medStatusUnknown;
      default:
        return c;
    }
  }
}

class _BgSection extends StatelessWidget {
  const _BgSection({
    required this.title,
    required this.value,
    required this.onEdit,
  });
  final String title;
  final String? value;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE3E5EA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null && value!.isNotEmpty ? value! : '—',
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null && value!.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
