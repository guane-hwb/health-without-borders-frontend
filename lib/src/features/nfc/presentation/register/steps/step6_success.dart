// lib/src/features/nfc/presentation/register/steps/step6_success.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../../../../../core/i18n/app_strings.dart';

/// A device a registration writes at the end. With two guardians each one
/// has its number; with one, it has none.
enum RegisterDevice { patient, guardian, guardian1, guardian2 }

/// Why a device was left unwritten.
enum DeviceWriteFailure {
  sessionExpired,
  noKey,
  invalidKey,
  notCompleted,
  needsNtag216,
}

/// A device left unwritten at the end of a registration, and why.
class UnwrittenDevice {
  const UnwrittenDevice(this.device, this.failure);

  final RegisterDevice device;
  final DeviceWriteFailure failure;
}

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
    this.unwritten = const <UnwrittenDevice>[],
    this.onGoHome,
  });

  final PatientFullRecord patient;
  final VoidCallback onAddConsultation;
  final VoidCallback onAddVaccine;

  /// Writes the devices: from the hub, all of them; from the final screen
  /// with [unwritten] devices, those again.
  final VoidCallback onFinish;
  final String? lastConsultationTime;
  final String? lastVaccineTime;
  final bool canAddConsultation;

  /// When true every device has been written: show the sealed confirmation
  /// and a single "go home" action instead of the hub actions. Never together
  /// with [unwritten] devices.
  final bool sealed;

  /// When not empty the write ended with these devices unwritten: show a
  /// warning with a row for each and why, "write now" ([onFinish]) and
  /// "write later from the profile" ([onGoHome]). They stay pending to write.
  final List<UnwrittenDevice> unwritten;

  /// Called by the "go home" button on the final screen.
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final hasConsultations = patient.medicalHistory.isNotEmpty;
    final hasVaccines = patient.vaccinationRecord.isNotEmpty;
    final bool notAllWritten = unwritten.isNotEmpty;
    final Color warning = Colors.orange.shade800;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        // ── Status + patient info ──
        // The green check only once every device is written: on the hub,
        // before writing, or with a device left unwritten it reads as done.
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: sealed
                  ? AppColors.success
                  : (notAllWritten ? warning : AppColors.primary),
              shape: BoxShape.circle,
            ),
            child: Icon(
              sealed
                  ? Icons.check
                  : (notAllWritten
                        ? Icons.warning_amber_rounded
                        : Icons.phone_android),
              size: 44,
              color: AppColors.white,
            ),
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

        // ── NFC status: sealed, unwritten (final) or pending (hub) ──
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
        else if (notAllWritten) ...<Widget>[
          for (final UnwrittenDevice device in unwritten)
            _ActivityRow(
              icon: Icons.nfc,
              iconColor: warning,
              bgColor: warning.withValues(alpha: 0.1),
              title: _notWrittenTitle(s, device.device),
              subtitle: _failureReason(s, device.failure),
            ),
        ] else
          _ActivityRow(
            icon: Icons.nfc,
            iconColor: AppColors.textSecondary,
            bgColor: AppColors.textSecondary.withValues(alpha: 0.1),
            title: isEs
                ? 'Pendiente de grabar en el dispositivo NFC'
                : 'Pending write to the NFC device',
            subtitle: s.writeDevicesHint,
          ),
        const SizedBox(height: 10),

        // ── Datos guardados localmente ──
        _ActivityRow(
          icon: Icons.save_outlined,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withValues(alpha: 0.1),
          title: s.patientSavedOnPhone,
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
        else if (notAllWritten) ...[
          // ── Grabar ahora (only what is missing) ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.contactless_outlined,
                color: AppColors.white,
                size: 20,
              ),
              label: Text(
                s.writeNow,
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
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onGoHome,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.home_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                s.writeLaterFromProfile,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          // ── Grabar dispositivos y terminar: the main action, first ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.contactless_outlined,
                color: AppColors.white,
                size: 22,
              ),
              label: Text(
                s.writeDevicesAndFinish,
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
          const SizedBox(height: 14),
          if (canAddConsultation) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onAddConsultation,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                label: Text(
                  hasConsultations
                      ? (isEs
                            ? 'Añadir otra consulta'
                            : 'Add another consultation')
                      : s.addConsultation,
                  style: const TextStyle(
                    color: AppColors.primary,
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
            child: OutlinedButton.icon(
              onPressed: onAddVaccine,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.vaccines_outlined,
                color: AppColors.secondary,
                size: 22,
              ),
              label: Text(
                hasVaccines
                    ? (isEs ? 'Añadir otra vacuna' : 'Add another vaccine')
                    : s.addVaccineButton,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _notWrittenTitle(AppStrings s, RegisterDevice device) =>
      switch (device) {
        RegisterDevice.patient => s.patientDeviceNotWritten,
        RegisterDevice.guardian => s.guardianDeviceNotWritten,
        RegisterDevice.guardian1 => s.guardianDeviceNNotWritten(1),
        RegisterDevice.guardian2 => s.guardianDeviceNNotWritten(2),
      };

  static String _failureReason(AppStrings s, DeviceWriteFailure failure) =>
      switch (failure) {
        DeviceWriteFailure.sessionExpired => s.writeFailedSessionExpired,
        DeviceWriteFailure.noKey => s.writeFailedNoKey,
        DeviceWriteFailure.invalidKey => s.writeFailedInvalidKey,
        DeviceWriteFailure.notCompleted => s.writeFailedNotCompleted,
        DeviceWriteFailure.needsNtag216 => s.writeFailedNeedsNtag216,
      };

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
