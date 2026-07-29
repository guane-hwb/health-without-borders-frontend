// lib/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';
import '../shared/profile_card.dart';
import '../shared/profile_section_header.dart';

class ProfileTabSummary extends StatelessWidget {
  const ProfileTabSummary({
    super.key,
    required this.draft,
    required this.original,
    required this.canEdit,
    required this.onEditVitalSigns,
    required this.onEditAddress,
    required this.onEditGuardian,
    required this.onOpenAllergies,
    required this.onOpenBackground,
  });

  final PatientFullRecord draft;
  final PatientFullRecord original;
  final bool canEdit;
  final VoidCallback onEditVitalSigns;
  final VoidCallback onEditAddress;
  final void Function(int guardianIndex) onEditGuardian;
  final VoidCallback onOpenAllergies;
  final VoidCallback onOpenBackground;

  bool get _allergiesChanged =>
      draft.allergies.length != original.allergies.length;
  @visibleForTesting
  bool get allergiesChanged => _allergiesChanged;

  bool get _backgroundChanged {
    final db = draft.backgroundHistory;
    final ob = original.backgroundHistory;
    if (db == null && ob == null) return false;
    if (db == null || ob == null) return true;
    return db.chronicConditions.length != ob.chronicConditions.length ||
        db.personalHistory != ob.personalHistory ||
        db.familyHistory.length != ob.familyHistory.length ||
        db.medications.length != ob.medications.length;
  }

  @visibleForTesting
  bool get backgroundChanged => _backgroundChanged;

  bool get _weightChanged =>
      draft.patientInfo.weight != original.patientInfo.weight;
  @visibleForTesting
  bool get weightChanged => _weightChanged;

  bool get _heightChanged =>
      draft.patientInfo.height != original.patientInfo.height;
  @visibleForTesting
  bool get heightChanged => _heightChanged;

  bool get _addressChanged {
    final da = draft.patientInfo.address;
    final oa = original.patientInfo.address;
    return da.street != oa.street ||
        da.city != oa.city ||
        da.state != oa.state ||
        da.zone != oa.zone;
  }

  @visibleForTesting
  bool get addressChanged => _addressChanged;

  bool get _guardianChanged {
    final dg1 = draft.guardianInfo;
    final og1 = original.guardianInfo;

    final g1Changed =
        dg1.name != og1.name ||
        dg1.phone != og1.phone ||
        dg1.relationship != og1.relationship ||
        dg1.deviceUid != og1.deviceUid;

    final dg2 = draft.guardian2Info;
    final og2 = original.guardian2Info;

    if (dg2 == null && og2 == null) return g1Changed;
    if (dg2 == null || og2 == null) return true;

    final g2Changed =
        dg2.name != og2.name ||
        dg2.phone != og2.phone ||
        dg2.relationship != og2.relationship ||
        dg2.deviceUid != og2.deviceUid;

    return g1Changed || g2Changed;
  }

  @visibleForTesting
  bool get guardianChanged => _guardianChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final p = draft.patientInfo;
    final bg = draft.backgroundHistory;
    final isEs = s.welcome == 'Bienvenido';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        // ══ ALLERGIES (clickable only if canEdit is true) ══════════════════════════════════
        _ClickableSection(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.error,
          title: s.allergiesSheetTitle.toUpperCase(),
          badge: draft.allergies.length,
          hasChanges: _allergiesChanged,
          onTap: canEdit ? onOpenAllergies : null,
          showArrow: canEdit,
          child: draft.allergies.isEmpty
              ? Text(
                  s.noAllergiesRegistered,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  children: draft.allergies
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppColors.error.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                a.allergen,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${_catLabel(context, a.category)})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),

        const SizedBox(height: 14),

        // ══ BACKGROUND (clickable only if canEdit is true) ═════════════════════════
        _ClickableSection(
          icon: Icons.history_edu_outlined,
          title: s.backgroundSheetTitle.toUpperCase(),
          hasChanges: _backgroundChanged,
          onTap: canEdit ? onOpenBackground : null,
          showArrow: canEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniRow(
                label: s.chronic,
                value: bg == null || bg.chronicConditions.isEmpty
                    ? '—'
                    : '${bg.chronicConditions.length} ${s.recordsLabel}',
              ),
              _MiniRow(
                label: s.personalTitle,
                value: bg?.personalHistory ?? '—',
              ),
              _MiniRow(
                label: s.medications,
                value: bg == null || bg.medications.isEmpty
                    ? '—'
                    : '${bg.medications.length} ${s.recordsLabel}',
              ),
              _MiniRow(
                label: s.family,
                value: bg == null || bg.familyHistory.isEmpty
                    ? '—'
                    : '${bg.familyHistory.length} ${s.recordsLabel}',
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ MEASUREMENTS ══════════════════════════════════════════
        ProfileSectionHeader(
          icon: Icons.monitor_heart_outlined,
          title: s.editMeasurements.toUpperCase(),
          actionLabel: canEdit ? s.editUpdate.split('/')[0].trim() : null,
          onAction: canEdit ? onEditVitalSigns : null,
          key: const ValueKey('measurements_header'),
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _VitalCell(
                    icon: Icons.scale_outlined,
                    label: s.weightKg.split(' ')[0],
                    value: p.weight != null
                        ? '${p.weight!.toStringAsFixed(1)} kg'
                        : '—',
                    changed: _weightChanged,
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.straighten,
                    label: s.heightCm.split(' ')[0],
                    value: p.height != null
                        ? '${p.height!.toStringAsFixed(0)} cm'
                        : '—',
                    changed: _heightChanged,
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.bloodtype_outlined,
                    label: s.bloodType.toUpperCase(),
                    value: p.bloodType ?? '—',
                    changed: false,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ IDENTITY (read-only) ═══════════════════════════════
        ProfileSectionHeader(
          icon: Icons.person_outline,
          title: s.identification.toUpperCase(),
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Column(
            children: [
              _IdRow(
                left: _IdCell(
                  label: s.documentTypeLabel,
                  value: _docTypeLabel(context, p.identification.documentType),
                ),
                right: _IdCell(
                  label: s.documentNumberLabel.split(' ')[0],
                  value: p.identification.documentNumber.isEmpty
                      ? '—'
                      : p.identification.documentNumber,
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: s.dobLabel,
                  value: _formatDob(p.dob, isEs),
                ),
                right: _IdCell(
                  label: s.gender.toUpperCase(),
                  value: _sexLabel(context, p.biologicalSex),
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: s.gender.toUpperCase(),
                  value:
                      _genderLabel(context, p.genderIdentity) ??
                      _sexLabel(context, p.biologicalSex),
                ),
                right: _IdCell(
                  label: s.nationality.toUpperCase(),
                  value: p.nationalityName ?? p.nationalityCode,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ RESIDENCE (editable) ═══════════════════════════════
        ProfileSectionHeader(
          icon: Icons.location_on_outlined,
          title: s.address.toUpperCase(),
          actionLabel: canEdit ? s.editUpdate.split('/')[0].trim() : null,
          onAction: canEdit ? onEditAddress : null,
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Column(
            children: [
              Row(
                children: [
                  if (_addressChanged) _OrangeDot(),
                  Expanded(
                    child: _IdRow(
                      left: _IdCell(
                        label: s.street.toUpperCase(),
                        value: p.address.street?.isNotEmpty == true
                            ? p.address.street!
                            : '—',
                      ),
                      right: _IdCell(
                        label: s.zone.toUpperCase(),
                        value: p.address.zone == '02'
                            ? s.zoneRural
                            : s.zoneUrban,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: s.municipality.toUpperCase(),
                  value: p.address.city.isNotEmpty ? p.address.city : '—',
                ),
                right: _IdCell(
                  label: s.department.toUpperCase(),
                  value: p.address.state.isNotEmpty ? p.address.state : '—',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ GUARDIANS (editable) ═══════════════════════════════
        if (draft.guardianInfo.name.isNotEmpty ||
            (draft.guardian2Info != null &&
                draft.guardian2Info!.name.isNotEmpty)) ...[
          ProfileSectionHeader(
            icon: Icons.family_restroom,
            title: isEs ? 'GUARDIANES' : 'GUARDIANS',
            actionLabel: null,
            onAction: null,
          ),
          const SizedBox(height: 8),

          if (draft.guardianInfo.name.isNotEmpty) ...[
            ProfileCard(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_guardianChanged) _OrangeDot(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEs ? 'Guardián Principal' : 'Primary Guardian',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _GuardianContent(guardian: draft.guardianInfo),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (canEdit)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () => onEditGuardian(1),
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (draft.guardian2Info != null &&
              draft.guardian2Info!.name.isNotEmpty) ...[
            const SizedBox(height: 10),
            ProfileCard(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_guardianChanged) _OrangeDot(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEs
                                  ? 'Guardián Secundario'
                                  : 'Secondary Guardian',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _GuardianContent(guardian: draft.guardian2Info!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (canEdit)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () => onEditGuardian(2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _catLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.allergyShortMedication,
          '02': s.allergyShortFood,
          '03': s.allergyShortEnvironment,
          '04': s.allergyShortSkin,
          '05': s.allergyShortInsect,
          '06': s.allergyShortOther,
        }[c] ??
        (c.isNotEmpty ? c : (s.welcome == 'Bienvenido' ? 'Otra' : 'Other'));
  }

  String _docTypeLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';
    return {
          'RC': s.docTypeRC,
          'TI': s.docTypeTI,
          'CC': s.docTypeCC,
          'CE': s.docTypeCE,
          'PA': s.docTypePA,
          'PE': s.docTypePE,
          'PT': s.docTypePT,
          'MS': s.docTypeMS,
          'AS': s.docTypeAS,
          'SC': isEs ? 'Salvoconducto' : 'Safe-conduct',
          'CN': isEs ? 'Cert. Nacido Vivo' : 'Live Birth Cert.',
          'DE': isEs ? 'Doc. Extranjero' : 'Foreign ID',
        }[c] ??
        (c.isNotEmpty ? c : '—');
  }

  String _sexLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {'M': s.sexMale, 'F': s.sexFemale, 'I': s.sexIndeterminate}[c] ??
        (s.welcome == 'Bienvenido' ? 'Indeterminado' : 'Indeterminate');
  }

  String? _genderLabel(BuildContext context, String? c) {
    if (c == null || c.isEmpty) return null;
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';
    return {
          '01': s.sexMale,
          '02': s.sexFemale,
          '03': isEs ? 'Transgénero' : 'Transgender',
          '04': isEs ? 'No binario' : 'Non-binary',
          '99': isEs ? 'No reporta' : 'Not reported',
        }[c] ??
        c;
  }

  String _formatDob(String dob, bool isEs) {
    final date = tryParsePatientDate(dob);
    if (date == null) return dob.isNotEmpty ? dob : '—';

    if (isEs) {
      const mEs = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${date.day} de ${mEs[date.month - 1]} de ${date.year}';
    } else {
      const mEn = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${mEn[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _ClickableSection extends StatelessWidget {
  const _ClickableSection({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
    this.badge = 0,
    this.hasChanges = false,
    this.iconColor = AppColors.primary,
    this.showArrow = true,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final int badge;
  final bool hasChanges;
  final VoidCallback? onTap;
  final Widget child;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ProfileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: 0.6,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
                if (hasChanges) ...[const SizedBox(width: 6), _OrangeDot()],
                const Spacer(),
                if (showArrow)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.disabled,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFF9800),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _VitalCell extends StatelessWidget {
  const _VitalCell({
    required this.icon,
    required this.label,
    required this.value,
    this.changed = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ),
              if (changed) ...[const SizedBox(width: 4), _OrangeDot()],
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: AppColors.divider,
  );
}

class _IdRow extends StatelessWidget {
  const _IdRow({required this.left, required this.right});
  final Widget left;
  final Widget right;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 8),
      Expanded(child: right),
    ],
  );
}

class _IdCell extends StatelessWidget {
  const _IdCell({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    ],
  );
}

class _GuardianContent extends StatelessWidget {
  const _GuardianContent({required this.guardian});
  final GuardianInfo guardian;
  String get _initials {
    final p = guardian.name.trim().split(RegExp(r'\s+'));
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : (p.isNotEmpty ? p[0][0].toUpperCase() : '?');
  }

  @override
  Widget build(BuildContext context) {
    final isUidValid =
        guardian.deviceUid != null && guardian.deviceUid!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guardian.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_relLabel(context, guardian.relationship)} · ${guardian.phone.isEmpty ? '—' : guardian.phone}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isUidValid) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.nfc_outlined,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'UID: ${guardian.deviceUid}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _relLabel(BuildContext context, String r) {
    final s = AppStrings.of(context);
    return {
          '01': s.relParents,
          '02': s.relSiblings,
          '03': s.relUncles,
          '04': s.relGrandparents,
        }[r] ??
        r;
  }
}
