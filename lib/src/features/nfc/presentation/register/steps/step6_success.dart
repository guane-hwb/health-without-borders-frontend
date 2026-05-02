// lib/src/features/nfc/presentation/register/steps/step6_success.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';

class Step6Success extends StatelessWidget {
  const Step6Success({
    super.key,
    required this.patient,
    required this.onAddConsultation,
    required this.onAddVaccine,
    required this.onFinish,
    this.lastConsultationTime,
    this.lastVaccineTime,
  });

  final PatientFullRecord patient;
  final VoidCallback onAddConsultation;
  final VoidCallback onAddVaccine;
  final VoidCallback onFinish;
  final String? lastConsultationTime;
  final String? lastVaccineTime;

  @override
  Widget build(BuildContext context) {
    final hasConsultations = patient.medicalHistory.isNotEmpty;
    final hasVaccines = patient.vaccinationRecord.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        // ── Green check + patient info ──
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 44, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            patient.patientInfo.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '${patient.patientInfo.identification.documentType} '
            '${patient.patientInfo.identification.documentNumber}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 22),

        // ── NFC wristband sealed ──
        _ActivityRow(
          icon: Icons.nfc,
          iconColor: AppColors.primary,
          bgColor: AppColors.primary.withValues(alpha: 0.1),
          title: 'Datos de emergencia sellados en la manilla',
          subtitle: 'Cifrado AES-256-GCM · Solo legible por la app',
        ),
        const SizedBox(height: 10),

        // ── Datos guardados localmente ──
        _ActivityRow(
          icon: Icons.save_outlined,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withValues(alpha: 0.1),
          title: 'Registro guardado localmente',
          subtitle: 'Listo para sincronizar cuando haya conexión',
        ),

        // ── Last consultation saved ──
        if (hasConsultations) ...[
          const SizedBox(height: 10),
          _ActivityRow(
            icon: Icons.medical_services_outlined,
            iconColor: AppColors.secondary,
            bgColor: AppColors.secondary.withValues(alpha: 0.1),
            title: 'Última consulta guardada',
            subtitle: lastConsultationTime ?? _formatNow(),
          ),
        ],

        // ── Last vaccine saved ──
        if (hasVaccines) ...[
          const SizedBox(height: 10),
          _ActivityRow(
            icon: Icons.vaccines_outlined,
            iconColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            title: 'Última vacuna guardada',
            subtitle: lastVaccineTime ?? _formatNow(),
          ),
        ],

        const SizedBox(height: 28),

        // ── Action buttons ──
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onAddConsultation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.white,
              size: 22,
            ),
            label: Text(
              hasConsultations ? 'Añadir otra consulta' : 'Añadir consulta',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onAddVaccine,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.vaccines_outlined,
              color: AppColors.white,
              size: 22,
            ),
            label: Text(
              hasVaccines ? 'Añadir otra vacuna' : 'Añadir vacuna',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Finalizar ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.white,
              size: 20,
            ),
            label: const Text(
              'Finalizar',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Al finalizar, el registro se envía a la cola de sincronización.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatNow() {
    final n = DateTime.now();
    final h = n.hour;
    final m = n.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'a.m.' : 'p.m.';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return 'Hoy, $h12:$m $period';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
