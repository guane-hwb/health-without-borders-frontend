// lib/src/features/nfc/presentation/profile/tabs/profile_tab_consultations.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
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
    final s = AppStrings.of(context);
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
                  '${s.consultationsTabTitle.toUpperCase()} · ${items.length}',
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medical_services_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.noConsultationsRegistered,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                label: Text(
                  s.addConsultationButton,
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

  void _showDetail(BuildContext context, MedicalHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConsultationDetailScreen(item: item),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.item, required this.onTap});
  final MedicalHistoryItem item;
  final VoidCallback onTap;

  String _formattedDate(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    try {
      final dt = DateTime.parse(item.startDateTime);
      final d = [
        s.dayLun,
        s.dayMar,
        s.dayMie,
        s.dayJue,
        s.dayVie,
        s.daySab,
        s.dayDom,
      ];
      final m = [
        s.monEne,
        s.monFeb,
        s.monMar,
        s.monAbr,
        s.monMay,
        s.monJun,
        s.monJul,
        s.monAgo,
        s.monSep,
        s.monOct,
        s.monNov,
        s.monDic,
      ];

      if (isEs) {
        return '${d[dt.weekday - 1]}, ${dt.day} de ${m[dt.month - 1]} de ${dt.year}';
      } else {
        return '${d[dt.weekday - 1]}, ${m[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {
      return item.startDateTime;
    }
  }

  String _formattedTime(BuildContext context) {
    final s = AppStrings.of(context);
    try {
      final dt = DateTime.parse(item.startDateTime);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h < 12 ? s.timeAm : s.timePm;
      return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:$m $period';
    } catch (_) {
      return '';
    }
  }

  String _modalityLabel(BuildContext context) {
    final s = AppStrings.of(context);
    return {
          '01': s.modIntramural,
          '02': s.modExtramuralMobil,
          '03': s.modDomiciliaria,
          '04': s.modJornada,
          '05': s.modPrehospitalaria,
          '06': s.modTelemedicinaInteractiva,
          '07': s.modNoInteractiva,
          '08': s.modTelexperticia,
          '09': s.modTelemonitoreo,
        }[item.careModality] ??
        item.careModality;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                          _formattedDate(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_formattedTime(context).isNotEmpty)
                          Text(
                            '${_formattedTime(context)}${item.provider?.name != null ? ' · ${item.provider!.name}' : ''}',
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
                      _modalityLabel(context),
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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    s.viewDetailHint,
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

class _ConsultationDetailScreen extends StatelessWidget {
  const _ConsultationDetailScreen({required this.item});
  final MedicalHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final eval = item.clinicalEvaluation;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          s.consultationDetailTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _Section(
            title: s.careContextSection,
            rows: [
              _kv(s.startDateLabel, _fmtDt(item.startDateTime, context)),
              if (item.endDateTime != null)
                _kv(s.endDateLabel, _fmtDt(item.endDateTime!, context)),
              _kv(s.zone, _modLabel(context, item.careModality)),
              _kv(s.serviceGroupLabel, _sgLabel(context, item.serviceGroup)),
              _kv(s.environmentLabel, _ceLabel(context, item.careEnvironment)),
              if (item.entryRoute != null)
                _kv(s.entryRouteLabel, item.entryRoute!),
              if (item.externalCause != null)
                _kv(s.externalCauseLabel, item.externalCause!),
            ],
          ),
          const SizedBox(height: 12),
          if (item.provider != null) ...[
            _Section(
              title: s.healthcareProvider,
              rows: [
                _kv(s.name, item.provider!.name),
                _kv(s.repsCode, item.provider!.repsCode),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.practitioner != null) ...[
            _Section(
              title: s.practitioner,
              rows: [
                _kv(s.name, item.practitioner!.name),
                _kv(
                  s.docLabelShort,
                  '${item.practitioner!.documentType} ${item.practitioner!.documentNumber}',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _Section(
            title: s.clinicalEvaluation,
            rows: [
              if (eval.historyOfCurrentIllness != null)
                _kv(s.historyCurrentIllness, eval.historyOfCurrentIllness!),
              if (eval.generalPhysicalExamination != null)
                _kv(s.generalExam, eval.generalPhysicalExamination!),
              if (eval.systemsExamination != null)
                _kv(s.systemsExam, eval.systemsExamination!),
              if (eval.treatmentPlanObservations != null)
                _kv(s.treatmentPlan, eval.treatmentPlanObservations!),
            ],
          ),
          const SizedBox(height: 12),
          if (item.diagnosis.isNotEmpty) ...[
            _Section(
              title: s.diagnosisTitle,
              rows: [
                _kv(s.diagnosisType, _dtLabel(context, item.diagnosisType)),
                for (final d in item.diagnosis) _kv(d.icd10Code, d.description),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.dischargeDisposition != null) ...[
            _Section(
              title: s.dischargeSection,
              rows: [
                _kv(s.condition, _ddLabel(context, item.dischargeDisposition!)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.riskFactors.isNotEmpty) ...[
            _Section(
              title: s.riskFactorsSection,
              rows: item.riskFactors.map((r) => _kv(r.type, r.name)).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (item.incapacity != null) ...[
            _Section(
              title: s.incapacitySection,
              rows: [
                _kv(s.incapacityScope, item.incapacity!.scope),
                _kv(s.incapacityDays, '${item.incapacity!.days}'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.payer != null) ...[
            _Section(
              title: s.payerSection,
              rows: [
                _kv(s.codeLabel, item.payer!.code ?? '—'),
                _kv(s.name, item.payer!.name ?? '—'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static MapEntry<String, String> _kv(String k, String v) => MapEntry(k, v);
  static String _fmtDt(String dt, BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    try {
      final d = DateTime.parse(dt);
      final timeStr = '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
      if (isEs) {
        return '${d.day}/${d.month}/${d.year} $timeStr';
      } else {
        return '${d.month}/${d.day}/${d.year} $timeStr';
      }
    } catch (_) {
      return dt;
    }
  }

  static String _modLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.modIntramural,
          '02': s.modExtramuralMobil,
          '03': s.modDomiciliaria,
          '04': s.modJornada,
          '05': s.modPrehospitalaria,
          '06': s.modTelemedicinaInteractiva,
          '07': s.modNoInteractiva,
          '08': s.modTelexperticia,
          '09': s.modTelemonitoreo,
        }[c] ??
        c;
  }

  static String _sgLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.sgConsultaExterna,
          '02': s.sgApoyoDiagnostico,
          '03': s.sgInternacion,
          '04': s.sgQuirurgico,
          '05': s.sgAtencionInmediata,
        }[c] ??
        c;
  }

  static String _ceLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.ceHogar,
          '02': s.ceComunitario,
          '03': s.ceEscolar,
          '04': s.ceLaboral,
          '05': s.ceInstitucional,
        }[c] ??
        c;
  }

  static String _dtLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.dtImpresion,
          '02': s.dtConfirmadoNuevo,
          '03': s.dtConfirmadoRepetido,
        }[c] ??
        c;
  }

  static String _ddLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    return {
          '01': s.ddAltaVoluntaria,
          '02': s.ddFallecido,
          '03': s.ddRemitido,
          '04': s.ddAltaMedica,
        }[c] ??
        c;
  }
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
