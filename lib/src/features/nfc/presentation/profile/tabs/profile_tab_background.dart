// lib/src/features/nfc/presentation/profile/tabs/profile_tab_background.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/profile_card.dart';
import '../shared/profile_section_header.dart';

class ProfileTabBackground extends StatelessWidget {
  const ProfileTabBackground({
    super.key,
    required this.draft,
    required this.onEditChronic,
    required this.onEditPersonal,
    required this.onAddFamilyHistory,
    required this.onRemoveFamilyHistory,
  });

  final PatientFullRecord draft;
  final VoidCallback onEditChronic;
  final VoidCallback onEditPersonal;
  final VoidCallback onAddFamilyHistory;
  final void Function(int index) onRemoveFamilyHistory;

  @override
  Widget build(BuildContext context) {
    final bg = draft.backgroundHistory ?? BackgroundHistory();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        // ── Chronic conditions ─────────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.favorite_border,
          title: 'CONDICIONES CRÓNICAS',
          actionLabel: 'Editar',
          onAction: onEditChronic,
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Text(
            (bg.chronicConditions == null ||
                    bg.chronicConditions!.isEmpty)
                ? 'Sin condiciones crónicas registradas.'
                : bg.chronicConditions!,
            style: TextStyle(
              fontSize: 13,
              color: bg.chronicConditions == null ||
                      bg.chronicConditions!.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Personal history ──────────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.history_edu_outlined,
          title: 'HISTORIAL PERSONAL',
          actionLabel: 'Editar',
          onAction: onEditPersonal,
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Text(
            (bg.personalHistory == null || bg.personalHistory!.isEmpty)
                ? 'Sin historial personal registrado.'
                : bg.personalHistory!,
            style: TextStyle(
              fontSize: 13,
              color: bg.personalHistory == null ||
                      bg.personalHistory!.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Family history ───────────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.diversity_3_outlined,
          title: 'ANTECEDENTES FAMILIARES',
          actionLabel: 'Agregar',
          actionIcon: Icons.add,
          onAction: onAddFamilyHistory,
        ),
        const SizedBox(height: 8),
        if (bg.familyHistory.isEmpty)
          ProfileCard(
            child: const Text(
              'Sin antecedentes familiares registrados.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < bg.familyHistory.length; i++) ...[
            _FamilyHistoryCard(
              item: bg.familyHistory[i],
              onRemove: () => onRemoveFamilyHistory(i),
            ),
            if (i < bg.familyHistory.length - 1)
              const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _FamilyHistoryCard extends StatelessWidget {
  const _FamilyHistoryCard({required this.item, required this.onRemove});
  final FamilyHistoryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.diversity_3,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.conditionDescription,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_relationshipLabel(item.relationship)}'
                  '${item.conditionCie10Code != null ? ' · CIE-10 ${item.conditionCie10Code}' : ''}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  static String _relationshipLabel(String r) {
    switch (r) {
      case '01':
        return 'Padres';
      case '02':
        return 'Hermanos';
      case '03':
        return 'Tíos';
      case '04':
        return 'Abuelos';
      default:
        return r;
    }
  }
}
