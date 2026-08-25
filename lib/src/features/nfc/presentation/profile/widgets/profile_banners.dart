// lib/src/features/nfc/presentation/profile/widgets/profile_banners.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDE7E7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEs
                  ? 'Acceso de emergencia · sin autorización del guardián · registrado'
                  : 'Emergency access · without guardian authorisation · logged',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.isDynamicDisconnect = false});

  final bool isDynamicDisconnect;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final String label = isDynamicDisconnect
        ? (isEs
              ? 'Sin conexión a Internet · Los cambios se guardarán localmente'
              : 'No internet connection · Changes will be saved locally')
        : (isEs
              ? 'Vista sin conexión · datos leídos del chip'
              : 'Offline view · data read from the chip');

    return Container(
      width: double.infinity,
      color: const Color(0xFFE7F0F7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 20, color: Color(0xFF2A5A7A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E4258),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NfcStaleBanner extends StatelessWidget {
  const NfcStaleBanner({
    super.key,
    required this.isUpdating,
    required this.onUpdate,
  });

  final bool isUpdating;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF4E5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sync_problem, size: 20, color: Color(0xFFB26A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEs ? 'Respaldo NFC desactualizado' : 'NFC backup out of date',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A4F00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isUpdating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onUpdate,
              child: Text(
                isEs ? 'Actualizar' : 'Update',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
