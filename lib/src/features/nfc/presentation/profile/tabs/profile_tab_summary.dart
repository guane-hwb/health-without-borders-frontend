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
    required this.onEditVitalSigns,
    required this.onEditAddress,
    required this.onEditGuardian,
  });

  final PatientFullRecord draft;
  final VoidCallback onEditVitalSigns;
  final VoidCallback onEditAddress;
  final VoidCallback onEditGuardian;

  @override
  Widget build(BuildContext context) {
    final p = draft.patientInfo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 60),
      children: [
        // ── Vital signs (editable) ─────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.monitor_heart_outlined,
          title: 'SIGNOS · ACTUALIZABLES',
          actionLabel: 'Editar',
          onAction: onEditVitalSigns,
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
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.straighten,
                    label: 'TALLA',
                    value: p.height != null
                        ? '${p.height!.toStringAsFixed(0)} cm'
                        : '—',
                  ),
                  _VitalDivider(),
                  _VitalCell(
                    icon: Icons.bloodtype_outlined,
                    label: 'SANGRE',
                    value: p.bloodType ?? '—',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Solo peso y talla son editables — cambian en el tiempo',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Identity (read-only) ──────────────────────────────────
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
                left: _IdCell(
                  label: 'F. NACIMIENTO',
                  value: _formatDob(p.dob),
                ),
                right: _IdCell(
                  label: 'SEXO BIOLÓGICO',
                  value: _sexLabel(p.biologicalSex),
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: 'IDENTIDAD GÉNERO',
                  value: _genderLabel(p.genderIdentity) ??
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
                  value: _disabilityLabel(p.disabilityCategory) ??
                      'Ninguna',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Residence (editable) ──────────────────────────────────
        ProfileSectionHeader(
          icon: Icons.location_on_outlined,
          title: 'RESIDENCIA',
          actionLabel: 'Editar',
          onAction: onEditAddress,
        ),
        const SizedBox(height: 8),
        ProfileCard(
          child: Column(
            children: [
              _IdRow(
                left: _IdCell(
                  label: 'DIRECCIÓN',
                  value: p.address.street?.isNotEmpty == true
                      ? p.address.street!
                      : '—',
                ),
                right: _IdCell(
                  label: 'ZONA',
                  value: p.address.zone == 'R' ? 'Rural' : 'Urbana',
                ),
              ),
              const SizedBox(height: 14),
              _IdRow(
                left: _IdCell(
                  label: 'MUNICIPIO',
                  value: p.address.city.isNotEmpty
                      ? '${p.address.city}'
                          '${p.address.cityCode != null ? ' (${p.address.cityCode})' : ''}'
                      : '—',
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

        // ── Guardian (editable) ───────────────────────────────────
        if (draft.guardianInfo != null) ...[
          ProfileSectionHeader(
            icon: Icons.family_restroom,
            title: 'GUARDIÁN',
            actionLabel: 'Editar',
            onAction: onEditGuardian,
          ),
          const SizedBox(height: 8),
          ProfileCard(
            child: _GuardianCard(guardian: draft.guardianInfo!),
          ),
        ],
      ],
    );
  }

  static String _docTypeLabel(String c) {
    switch (c) {
      case 'RC':
        return 'Registro civil';
      case 'TI':
        return 'Tarjeta identidad';
      case 'CC':
        return 'Cédula';
      case 'CE':
        return 'Céd. extranjería';
      case 'PA':
        return 'Pasaporte';
      case 'PE':
        return 'Permiso esp.';
      case 'PT':
        return 'PPT';
      case 'MS':
        return 'Menor s/ID';
      case 'AS':
        return 'Adulto s/ID';
      default:
        return c;
    }
  }

  static String _sexLabel(String c) {
    switch (c) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return 'Indeterminado';
    }
  }

  static String? _genderLabel(String? c) {
    if (c == null) return null;
    switch (c) {
      case '01':
        return 'Masculino';
      case '02':
        return 'Femenino';
      case '03':
        return 'No binario';
      case '04':
        return 'Otro';
      default:
        return null;
    }
  }

  static String? _ethnicityLabel(String? c) {
    if (c == null) return null;
    switch (c) {
      case '01':
        return 'Indígena';
      case '02':
        return 'ROM';
      case '03':
        return 'Raizal';
      case '04':
        return 'Palenquero';
      case '05':
        return 'Negro/Afro';
      case '06':
        return 'Otro';
      default:
        return null;
    }
  }

  static String? _disabilityLabel(String? c) {
    if (c == null || c == '00') return 'Ninguna';
    switch (c) {
      case '01':
        return 'Física';
      case '02':
        return 'Auditiva';
      case '03':
        return 'Visual';
      case '04':
        return 'Sordoceguera';
      case '05':
        return 'Mental';
      case '06':
        return 'Intelectual';
      case '07':
        return 'Múltiple';
      default:
        return c;
    }
  }

  static String _formatDob(String dob) {
    if (dob.isEmpty || !dob.contains('-')) return dob;
    final p = dob.split('-');
    if (p.length != 3) return dob;
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final m = int.tryParse(p[1]);
    if (m == null || m < 1 || m > 12) return dob;
    return '${int.parse(p[2])} de ${months[m - 1]} de ${p[0]}';
  }
}

// ── Vital cell ──────────────────────────────────────────────────────────────

class _VitalCell extends StatelessWidget {
  const _VitalCell({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _VitalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}

// ── Identity / address row helpers ──────────────────────────────────────────

class _IdRow extends StatelessWidget {
  const _IdRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ]);
}

class _IdCell extends StatelessWidget {
  const _IdCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary),
        ),
      ]);
}

// ── Guardian sub-card ───────────────────────────────────────────────────────

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.guardian});
  final GuardianInfo guardian;

  String get _initials {
    final parts = guardian.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guardian.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${_relationshipLabel(guardian.relationship)} · ${guardian.phone ?? '—'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.nfc, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                guardian.deviceUid != null && guardian.deviceUid!.isNotEmpty
                    ? 'NFC: ${guardian.deviceUid!}'
                    : 'NFC: no asignada',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: guardian.deviceUid != null &&
                        guardian.deviceUid!.isNotEmpty
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.disabled.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                guardian.deviceUid != null &&
                        guardian.deviceUid!.isNotEmpty
                    ? 'Registrada'
                    : 'No registrada',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: guardian.deviceUid != null &&
                          guardian.deviceUid!.isNotEmpty
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
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
