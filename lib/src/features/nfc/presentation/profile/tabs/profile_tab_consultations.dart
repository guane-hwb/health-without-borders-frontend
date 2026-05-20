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
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
                ),
                child: ProfileCard(
                  child: const Text(
                    'Sin consultas registradas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                _ConsultationCard(
                  item: items[i],
                  onTap: () => _showDetail(context, items[i]),
                ),
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
                  elevation: 0,
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

  void _showDetail(BuildContext context, MedicalHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ConsultationDetailScreen(item: item)),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.item, required this.onTap});
  final MedicalHistoryItem item;
  final VoidCallback onTap;

  String get _formattedDate {
    try {
      final dt = DateTime.parse(item.startDateTime);
      const d = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      const m = [
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
      return '${d[dt.weekday - 1]}, ${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return item.startDateTime;
    }
  }

  String get _formattedTime {
    try {
      final dt = DateTime.parse(item.startDateTime);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:$m ${h < 12 ? 'a.m.' : 'p.m.'}';
    } catch (_) {
      return '';
    }
  }

  String get _modalityLabel =>
      const {
        '01': 'Intramural',
        '02': 'Extramural',
        '03': 'Domiciliaria',
        '04': 'Jornada',
        '05': 'Prehospitalaria',
        '06': 'Telemedicina',
        '07': 'Teleaistencia',
        '08': 'Telexperticia',
        '09': 'Telemonitoreo',
      }[item.careModality] ??
      item.careModality;

  @override
  Widget build(BuildContext context) {
    final summary =
        item.clinicalEvaluation.historyOfCurrentIllness ??
        item.clinicalEvaluation.treatmentPlanObservations ??
        '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
        ),
        child: ProfileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          '$_formattedTime${item.provider?.name != null ? ' · ${item.provider!.name}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
            if (item.diagnosis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.diagnosis.map((d) => _DiagChip(d: d)).toList(),
              ),
            ],
            if (item.practitioner != null &&
                item.practitioner!.name.isNotEmpty) ...[
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
            // Tap hint
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver detalle',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DiagChip extends StatelessWidget {
  const _DiagChip({required this.d});
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

// ═════════════════════════════════════════════════════════════════════════════
// Full detail screen for a single consultation (read-only)
// ═════════════════════════════════════════════════════════════════════════════

class _ConsultationDetailScreen extends StatelessWidget {
  const _ConsultationDetailScreen({required this.item});
  final MedicalHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final eval = item.clinicalEvaluation;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text(
          'Detalle de consulta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _Section(
            title: 'Contexto de atención',
            rows: [
              _kv('Fecha inicio', _fmtDt(item.startDateTime)),
              if (item.endDateTime != null)
                _kv('Fecha fin', _fmtDt(item.endDateTime!)),
              _kv('Modalidad', _modLabel(item.careModality)),
              _kv('Grupo servicio', _sgLabel(item.serviceGroup)),
              _kv('Entorno', _ceLabel(item.careEnvironment)),
              if (item.entryRoute != null) _kv('Vía ingreso', item.entryRoute!),
              if (item.externalCause != null)
                _kv('Causa externa', item.externalCause!),
            ],
          ),
          const SizedBox(height: 12),
          if (item.provider != null) ...[
            _Section(
              title: 'Prestador',
              rows: [
                _kv('Nombre', item.provider!.name),
                _kv('REPS', item.provider!.repsCode),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.practitioner != null) ...[
            _Section(
              title: 'Profesional',
              rows: [
                _kv('Nombre', item.practitioner!.name),
                _kv(
                  'Doc.',
                  '${item.practitioner!.documentType} ${item.practitioner!.documentNumber}',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _Section(
            title: 'Evaluación clínica',
            rows: [
              if (eval.historyOfCurrentIllness != null)
                _kv('Enfermedad actual', eval.historyOfCurrentIllness!),
              if (eval.generalPhysicalExamination != null)
                _kv('Examen físico', eval.generalPhysicalExamination!),
              if (eval.systemsExamination != null)
                _kv('Revisión por sistemas', eval.systemsExamination!),
              if (eval.treatmentPlanObservations != null)
                _kv('Plan de tratamiento', eval.treatmentPlanObservations!),
            ],
          ),
          const SizedBox(height: 12),
          if (item.diagnosis.isNotEmpty) ...[
            _Section(
              title: 'Diagnósticos',
              rows: [
                _kv('Tipo', _dtLabel(item.diagnosisType)),
                for (final d in item.diagnosis) _kv(d.icd10Code, d.description),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.dischargeDisposition != null) ...[
            _Section(
              title: 'Egreso',
              rows: [_kv('Condición', _ddLabel(item.dischargeDisposition!))],
            ),
            const SizedBox(height: 12),
          ],
          if (item.riskFactors.isNotEmpty) ...[
            _Section(
              title: 'Factores de riesgo',
              rows: item.riskFactors.map((r) => _kv(r.type, r.name)).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (item.incapacity != null) ...[
            _Section(
              title: 'Incapacidad',
              rows: [
                _kv('Alcance', item.incapacity!.scope),
                _kv('Días', '${item.incapacity!.days}'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.payer != null) ...[
            _Section(
              title: 'Pagador',
              rows: [
                _kv('Código', item.payer!.code ?? '—'),
                _kv('Nombre', item.payer!.name ?? '—'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);
  static String _fmtDt(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  static String _modLabel(String c) =>
      const {
        '01': 'Intramural',
        '02': 'Extramural móvil',
        '03': 'Domiciliaria',
        '04': 'Jornada',
        '05': 'Prehospitalaria',
        '06': 'Telemedicina interactiva',
        '07': 'No interactiva',
        '08': 'Telexperticia',
        '09': 'Telemonitoreo',
      }[c] ??
      c;
  static String _sgLabel(String c) =>
      const {
        '01': 'Consulta externa',
        '02': 'Apoyo diagnóstico',
        '03': 'Internación',
        '04': 'Quirúrgico',
        '05': 'Atención inmediata',
      }[c] ??
      c;
  static String _ceLabel(String c) =>
      const {
        '01': 'Hogar',
        '02': 'Comunitario',
        '03': 'Escolar',
        '04': 'Laboral',
        '05': 'Institucional',
      }[c] ??
      c;
  static String _dtLabel(String c) =>
      const {
        '01': 'Impresión diagnóstica',
        '02': 'Confirmado nuevo',
        '03': 'Confirmado repetido',
      }[c] ??
      c;
  static String _ddLabel(String c) =>
      const {
        '01': 'Alta voluntaria',
        '02': 'Paciente fallecido',
        '03': 'Remitido',
        '04': 'Alta médica',
      }[c] ??
      c;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<MapEntry<String, String>> rows;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (kv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      kv.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      kv.value.isEmpty ? '—' : kv.value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}