// lib/src/features/nfc/presentation/register/steps/step6_success.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';

class Step6Success extends StatelessWidget {
  const Step6Success({super.key, required this.patient, required this.onAddConsultation, required this.onAddVaccine, required this.onFinish});
  final PatientFullRecord patient; final VoidCallback onAddConsultation; final VoidCallback onAddVaccine; final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 30), children: [
      Center(child: Container(width: 92, height: 92, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 50, color: AppColors.white))),
      const SizedBox(height: 18),
      const Center(child: Text('Registro completo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
      const SizedBox(height: 4),
      Center(child: Text('${patient.patientInfo.fullName} · ${patient.patientInfo.identification.documentNumber}',
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      const SizedBox(height: 26),
      // Status rows
      _StatusRow(icon: Icons.check_circle, color: AppColors.success, label: 'Datos', value: 'Guardados localmente'),
      const SizedBox(height: 10),
      _StatusRow(icon: Icons.nfc, color: AppColors.primary, label: 'Manilla', value: 'Escrita y sellada'),
      const SizedBox(height: 10),
      _StatusRow(icon: Icons.cloud_upload_outlined, color: const Color(0xFFB8800F), label: 'Sync', value: 'En cola — se enviará al detectar internet'),
      const SizedBox(height: 30),
      // Buttons
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: onAddConsultation,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        icon: const Icon(Icons.medical_services_outlined, color: AppColors.white, size: 22), label: const Text('Añadir consulta', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: onAddVaccine,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        icon: const Icon(Icons.vaccines_outlined, color: AppColors.white, size: 22), label: const Text('Añadir vacuna', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 46, child: OutlinedButton(onPressed: onFinish,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Volver al inicio', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
    ]);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon; final Color color; final String label; final String value;
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 22, color: color), const SizedBox(width: 12),
    Text('$label:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(width: 6),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
  ]);
}
