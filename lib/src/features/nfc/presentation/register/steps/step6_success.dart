// lib/src/features/nfc/presentation/register/steps/step6_success.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../../../../../core/i18n/app_strings.dart';

class Step6Success extends StatelessWidget {
  const Step6Success({
    super.key,
    required this.patient,
    required this.onAddConsultation,
    required this.onAddVaccine,
    required this.onFinish,
    this.lastConsultationTime,
    this.lastVaccineTime,
    this.canAddConsultation = true,
    this.sealed = false,
    this.onGoHome,
  });

  final PatientFullRecord patient;
  final VoidCallback onAddConsultation;
  final VoidCallback onAddVaccine;
  final VoidCallback onFinish;
  final String? lastConsultationTime;
  final String? lastVaccineTime;
  final bool canAddConsultation;

  /// When true the chips have already been written: show the sealed
  /// confirmation and a single "go home" action instead of the hub actions.
  final bool sealed;

  /// Called by the "go home" button on the final (sealed) screen.
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

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

        // ── NFC status: sealed (final) vs pending (hub) ──
        if (sealed)
          _ActivityRow(
            icon: Icons.nfc,
            iconColor: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.1),
            title: isEs
                ? 'Datos de emergencia sellados en el dispositivo NFC'
                : 'Emergency data sealed on the NFC device',
            subtitle: isEs
                ? 'Cifrado AES-256-GCM · Solo legible por la app'
                : 'AES-256-GCM Encryption · Read-only by the app',
          )
        else
          _ActivityRow(
            icon: Icons.nfc,
            iconColor: AppColors.textSecondary,
            bgColor: AppColors.textSecondary.withValues(alpha: 0.1),
            title: isEs
                ? 'Pendiente de grabar en el dispositivo NFC'
                : 'Pending write to the NFC device',
            subtitle: isEs
                ? 'Toca "Finalizar" y acerca los dispositivos para sellar'
                : 'Tap "Finish" and bring the devices to seal the data',
          ),
        const SizedBox(height: 10),

        // ── Datos guardados localmente ──
        _ActivityRow(
          icon: Icons.save_outlined,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withValues(alpha: 0.1),
          title: s.patientSavedSynced.split(' y ')[0],
          subtitle: isEs
              ? 'Listo para sincronizar cuando haya conexión'
              : 'Ready to synchronize when connection is available',
        ),

        // ── Last consultation saved ──
        if (hasConsultations) ...[
          const SizedBox(height: 10),
          _ActivityRow(
            icon: Icons.medical_services_outlined,
            iconColor: AppColors.secondary,
            bgColor: AppColors.secondary.withValues(alpha: 0.1),
            title: isEs
                ? 'Última consulta guardada'
                : 'Last consultation saved',
            subtitle: lastConsultationTime ?? _formatNow(isEs),
          ),
        ],

        // ── Last vaccine saved ──
        if (hasVaccines) ...[
          const SizedBox(height: 10),
          _ActivityRow(
            icon: Icons.vaccines_outlined,
            iconColor: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            title: isEs ? 'Última vacuna guardada' : 'Last vaccine saved',
            subtitle: lastVaccineTime ?? _formatNow(isEs),
          ),
        ],

        const SizedBox(height: 28),

        // ── Action buttons ──
        if (sealed)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onGoHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.home_outlined,
                color: AppColors.white,
                size: 20,
              ),
              label: Text(
                isEs ? 'Ir al inicio' : 'Go to home',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else ...[
          if (canAddConsultation) ...[
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
                hasConsultations
                    ? (isEs
                          ? 'Añadir otra consulta'
                          : 'Add another consultation')
                    : s.addConsultation,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
              hasVaccines
                  ? (isEs ? 'Añadir otra vacuna' : 'Add another vaccine')
                  : s.addVaccineButton,
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
            label: Text(
              isEs ? 'Finalizar' : 'Finish',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            isEs
                ? 'Al finalizar, el registro se envía a la cola de sincronización.'
                : 'Upon completion, the record is sent to the synchronization queue.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        ],
      ],
    );
  }

  static String _formatNow(bool isEs) {
    final n = DateTime.now();
    final h = n.hour;
    final m = n.minute.toString().padLeft(2, '0');

    if (isEs) {
      final period = h < 12 ? 'a.m.' : 'p.m.';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return 'Hoy, $h12:$m $period';
    } else {
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return 'Today, $h12:$m $period';
    }
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
