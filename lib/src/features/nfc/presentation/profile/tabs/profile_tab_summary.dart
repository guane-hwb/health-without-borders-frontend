// lib/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
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
  final VoidCallback onEditGuardian;
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
    final dg = draft.guardianInfo;
    final og = original.guardianInfo;
    return dg.name != og.name ||
        dg.phone != og.phone ||
        dg.relationship != og.relationship ||
        dg.deviceUid != og.deviceUid;
  }
  @visibleForTesting
  bool get guardianChanged => _guardianChanged;

  @override
  Widget build(BuildContext context) {
    final p = draft.patientInfo;
    final bg = draft.backgroundHistory;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        // ══ ALERGIAS (clickable) ══════════════════════════════════
        _ClickableSection(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.error,
          title: 'ALERGIAS',
          badge: draft.allergies.length,
          hasChanges: _allergiesChanged,
          onTap: onOpenAllergies,
          child: draft.allergies.isEmpty
              ? const Text(
                  'Sin alergias registradas.',
                  style: TextStyle(
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
                                '(${_catLabel(a.category)})',
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

        // ══ ANTECEDENTES (clickable) ═════════════════════════════
        _ClickableSection(
          icon: Icons.history_edu_outlined,
          title: 'ANTECEDENTES',
          hasChanges: _backgroundChanged,
          onTap: onOpenBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniRow(
                label: 'Crónicos',
                value: bg == null || bg.chronicConditions.isEmpty
                    ? '—'
                    : '${bg.chronicConditions.length} registros',
              ),
              _MiniRow(label: 'Personal', value: bg?.personalHistory ?? '—'),
              _MiniRow(
                label: 'Medicam.',
                value: bg == null || bg.medications.isEmpty
                    ? '—'
                    : '${bg.medications.length} registros',
              ),
              _MiniRow(
                label: 'Familiares',
                value: bg == null || bg.familyHistory.isEmpty
                    ? '—'
                    : '${bg.familyHistory.length} registros',
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ MEDICIONES ══════════════════════════════════════════
        ProfileSectionHeader(
          icon: Icons.monitor_heart_outlined,
          title: 'MEDICIONES',
          actionLabel: canEdit ? 'Editar' : null,
          onAction: canEdit ? onEditVitalSigns : null,
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
                    label: 'PESO',
                    value: p.weight != null
                        ? '${p.weight!.toStringAsFixed(1)} kg'
                        : '—',
                    changed: _weightChanged,
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.straighten,
                    label: 'ALTURA',
                    value: p.height != null
                        ? '${p.height!.toStringAsFixed(0)} cm'
                        : '—',
                    changed: _heightChanged,
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.bloodtype_outlined,
                    label: 'SANGRE',
                    value: p.bloodType ?? '—',
                    changed: false,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ IDENTIDAD (read-only) ═══════════════════════════════
        const ProfileSectionHeader(
          icon: Icons.person_outline,
          title: 'IDENTIDAD',
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Column(
            children: [
              _IdRow(
                left: _IdCell(
                  label: 'TIPO DOC.',
                  value: _docTypeLabel(p.identification.documentType),
                ),
                right: _IdCell(
                  label: 'NÚMERO',
                  value: p.identification.documentNumber.isEmpty
                      ? '—'
                      : p.identification.documentNumber,
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(label: 'F. NACIMIENTO', value: _formatDob(p.dob)),
                right: _IdCell(
                  label: 'SEXO BIOLÓGICO',
                  value: _sexLabel(p.biologicalSex),
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: 'IDENTIDAD GÉNERO',
                  value:
                      _genderLabel(p.genderIdentity) ??
                      _sexLabel(p.biologicalSex),
                ),
                right: _IdCell(
                  label: 'ETNIA',
                  value: _ethnicityLabel(p.ethnicity) ?? 'Ninguno',
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: 'NACIONALIDAD',
                  value: p.nationalityName ?? p.nationalityCode,
                ),
                right: _IdCell(
                  label: 'DISCAPACIDAD',
                  value: _disabilityLabel(p.disabilityCategory) ?? 'Ninguna',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ RESIDENCIA (editable) ═══════════════════════════════
        ProfileSectionHeader(
          icon: Icons.location_on_outlined,
          title: 'RESIDENCIA',
          actionLabel: canEdit ? 'Editar' : null,
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
                        label: 'DIRECCIÓN',
                        value: p.address.street?.isNotEmpty == true
                            ? p.address.street!
                            : '—',
                      ),
                      right: _IdCell(
                        label: 'ZONA',
                        value: p.address.zone == '02' ? 'Rural' : 'Urbana',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: 'MUNICIPIO',
                  value: p.address.city.isNotEmpty ? p.address.city : '—',
                ),
                right: _IdCell(
                  label: 'DEPARTAMENTO',
                  value: p.address.state.isNotEmpty ? p.address.state : '—',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ══ GUARDIÁN (editable) ═════════════════════════════════
        if (draft.guardianInfo.name.isNotEmpty) ...[
          ProfileSectionHeader(
            icon: Icons.family_restroom,
            title: 'GUARDIÁN',
            actionLabel: canEdit ? 'Editar' : null,
            onAction: canEdit ? onEditGuardian : null,
          ),
          const SizedBox(height: 8),
          ProfileCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_guardianChanged) _OrangeDot(),
                Expanded(
                  child: _GuardianContent(guardian: draft.guardianInfo),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _catLabel(String c) =>
      const {
        '01': 'Medicamento',
        '02': 'Alimento',
        '03': 'Ambiente',
        '04': 'Piel',
        '05': 'Picadura',
        '06': 'Otra',
      }[c] ??
      c;
  static String _docTypeLabel(String c) =>
      const {
        'RC': 'Registro civil',
        'TI': 'Tarjeta identidad',
        'CC': 'Cédula',
        'CE': 'Céd. extranjería',
        'PA': 'Pasaporte',
        'PE': 'Permiso esp.',
        'PT': 'PPT',
        'MS': 'Menor s/ID',
        'AS': 'Adulto s/ID',
      }[c] ??
      c;
  static String _sexLabel(String c) =>
      const {'M': 'Masculino', 'F': 'Femenino', 'I': 'Indeterminado'}[c] ?? c;
  static String? _genderLabel(String? c) => c == null
      ? null
      : const {
          '01': 'Masculino',
          '02': 'Femenino',
          '03': 'Transgénero',
          '04': 'No binario',
        }[c];
  static String? _ethnicityLabel(String? c) => c == null
      ? null
      : const {
          '01': 'Indígena',
          '02': 'ROM',
          '03': 'Raizal',
          '04': 'Palenquero',
          '05': 'Negro/Afro',
          '06': 'Ninguno',
        }[c];
  static String? _disabilityLabel(String? c) => (c == null || c == '00')
      ? 'Ninguna'
      : const {
          '01': 'Física',
          '02': 'Auditiva',
          '03': 'Visual',
          '04': 'Sordoceguera',
          '05': 'Mental',
          '06': 'Intelectual',
          '07': 'Múltiple',
        }[c];
  static String _formatDob(String dob) {
    if (dob.isEmpty || !dob.contains('-')) return dob;
    final p = dob.split('-');
    if (p.length != 3) return dob;
    const m = [
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
    final mi = int.tryParse(p[1]);
    if (mi == null || mi < 1 || mi > 12) return dob;
    return '${int.parse(p[2])} de ${m[mi - 1]} de ${p[0]}';
  }
}

// ── Clickable section card (Alergias, Antecedentes) ──────────────────────

class _ClickableSection extends StatelessWidget {
  const _ClickableSection({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
    this.badge = 0,
    this.hasChanges = false,
    this.iconColor = AppColors.primary,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final int badge;
  final bool hasChanges;
  final VoidCallback onTap;
  final Widget child;

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
            width: 80,
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

// ── Orange change indicator dot ──────────────────────────────────────────

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

// ── Vital cell ──────────────────────────────────────────────────────────

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
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (changed) ...[const SizedBox(width: 4), _OrangeDot()],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
        margin: const EdgeInsets.symmetric(horizontal: 30),
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
      const SizedBox(width: 12),
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
                    '${_relLabel(guardian.relationship)} · ${guardian.phone.isEmpty ? '—' : guardian.phone}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _relLabel(String r) =>
      const {
        '01': 'Padres',
        '02': 'Hermanos',
        '03': 'Tíos',
        '04': 'Abuelos',
      }[r] ??
      r;
}
