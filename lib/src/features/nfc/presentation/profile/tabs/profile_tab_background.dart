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
    required this.onAddChronic,
    required this.onRemoveChronic,
    required this.onEditPersonal,
    required this.onAddFamilyHistory,
    required this.onRemoveFamilyHistory,
    required this.onAddMedication,
    required this.onRemoveMedication,
  });

  final PatientFullRecord draft;
  final VoidCallback onAddChronic;
  final void Function(int index) onRemoveChronic;
  final VoidCallback onEditPersonal;
  final VoidCallback onAddFamilyHistory;
  final void Function(int index) onRemoveFamilyHistory;
  final VoidCallback onAddMedication;
  final void Function(int index) onRemoveMedication;

  @override
  Widget build(BuildContext context) {
    final bg = draft.backgroundHistory ?? BackgroundHistory();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        // ── Chronic conditions (list) ──────────────────────────────
        ProfileSectionHeader(
          icon: Icons.favorite_border,
          title: 'CONDICIONES CRÓNICAS',
          actionLabel: 'Agregar',
          actionIcon: Icons.add,
          onAction: onAddChronic,
        ),
        const SizedBox(height: 8),
        if (bg.chronicConditions.isEmpty)
          ProfileCard(
            child: const Text(
              'Sin condiciones crónicas registradas.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < bg.chronicConditions.length; i++) ...[
            _ChronicConditionCard(
              item: bg.chronicConditions[i],
              onRemove: () => onRemoveChronic(i),
            ),
            if (i < bg.chronicConditions.length - 1) const SizedBox(height: 8),
          ],

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
              color: bg.personalHistory == null || bg.personalHistory!.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Medications (list) ─────────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.medication_outlined,
          title: 'MEDICAMENTOS',
          actionLabel: 'Agregar',
          actionIcon: Icons.add,
          onAction: onAddMedication,
        ),
        const SizedBox(height: 8),
        if (bg.medications.isEmpty)
          ProfileCard(
            child: const Text(
              'Sin medicamentos registrados.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < bg.medications.length; i++) ...[
            _MedicationCard(
              item: bg.medications[i],
              onRemove: () => onRemoveMedication(i),
            ),
            if (i < bg.medications.length - 1) const SizedBox(height: 8),
          ],

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
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (var i = 0; i < bg.familyHistory.length; i++) ...[
            _FamilyHistoryCard(
              item: bg.familyHistory[i],
              onRemove: () => onRemoveFamilyHistory(i),
            ),
            if (i < bg.familyHistory.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ChronicConditionCard extends StatelessWidget {
  const _ChronicConditionCard({required this.item, required this.onRemove});
  final ChronicConditionItem item;
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
            child: const Icon(
              Icons.favorite_border,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.chronicDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.chronicCie10Code != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'CIE-10: ${item.chronicCie10Code}'
                    '${item.chronicCie11Code != null ? ' · CIE-11: ${item.chronicCie11Code}' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.item, required this.onRemove});
  final MedicationStatementItem item;
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
            child: const Icon(
              Icons.medication_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicationName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(item.status) +
                      (item.dosage != null ? ' · ${item.dosage}' : ''),
                  style: const TextStyle(
                    fontSize: 11,
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
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) =>
      const {
        'active': 'Activo',
        'completed': 'Completado',
        'stopped': 'Suspendido',
        'unknown': 'Desconocido',
      }[s] ??
      s;
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
            child: const Icon(
              Icons.diversity_3,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.conditionDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_relationshipLabel(item.relationship)}'
                  '${item.conditionCie10Code != null ? ' · CIE-10 ${item.conditionCie10Code}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
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
