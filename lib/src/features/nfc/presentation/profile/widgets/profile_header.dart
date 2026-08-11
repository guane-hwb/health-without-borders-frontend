// lib/src/features/nfc/presentation/profile/widgets/profile_header.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../patient_profile_helpers.dart' as helpers;

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.patient,
    required this.hasUnsyncedChanges,
    required this.onBack,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.onSync,
  });

  final PatientFullRecord patient;
  final bool hasUnsyncedChanges;
  final VoidCallback onBack;
  final String? lastSyncedAt;
  final bool isSyncing;
  final VoidCallback? onSync;

  int? get _age => helpers.computeAge(patient.patientInfo.dob, DateTime.now());

  String _initials(String fullName) => helpers.computeInitials(fullName);

  String _sexLabel(BuildContext context) => helpers.sexLabel(
    AppStrings.of(context),
    patient.patientInfo.biologicalSex,
  );

  String _docTypeLabel(BuildContext context) => helpers.docTypeLabel(
    AppStrings.of(context),
    patient.patientInfo.identification.documentType,
  );

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final docNumber = patient.patientInfo.identification.documentNumber;
    final s = AppStrings.of(context);
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              const Spacer(),
              if (onSync != null)
                IconButton(
                  onPressed: isSyncing ? null : onSync,
                  tooltip: isSyncing ? s.syncingBtn : s.syncBtn,
                  icon: isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.white,
                        ),
                ),
              const LanguageToggle(),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Avatar(initials: _initials(patient.patientInfo.fullName)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientInfo.fullName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (age != null)
                            PillChip(
                              label:
                                  '$age ${s.yearsOldSuffix} · ${_sexLabel(context)}',
                              filled: true,
                            ),
                          if (docNumber.isNotEmpty)
                            PillChip(
                              label: '${_docTypeLabel(context)} $docNumber',
                              filled: false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (hasUnsyncedChanges) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFB300),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFB300,
                          ).withValues(alpha: 0.55),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.unsyncedChanges,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials});
  final String initials;

  static const List<Color> _palette = [
    Color(0xFFE6A817),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF9333EA),
    Color(0xFF0891B2),
    Color(0xFFEA580C),
    Color(0xFF0F766E),
  ];

  static Color _avatarColor(String initials) =>
      _palette[helpers.avatarColorIndex(initials)];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _avatarColor(initials),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.of(context);
    final isEs = loc.locale == 'es';
    return GestureDetector(
      onTap: () => loc.setLocale(isEs ? 'en' : 'es'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            LangDot(label: 'ES', selected: isEs),
            const SizedBox(width: 2),
            LangDot(label: 'EN', selected: !isEs),
          ],
        ),
      ),
    );
  }
}

class LangDot extends StatelessWidget {
  const LangDot({super.key, required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.white : Colors.white.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
