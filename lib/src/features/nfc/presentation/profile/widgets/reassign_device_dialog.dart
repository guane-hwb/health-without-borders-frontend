import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';

enum ReassignTarget { patient, guardian1, guardian2 }

class ReassignSelection {
  const ReassignSelection({required this.targets, required this.reason});
  final List<ReassignTarget> targets;
  final String reason;
}

Future<ReassignSelection?> showReassignDeviceDialog(
  BuildContext context, {
  required bool isEs,
  required bool hasG1,
  required bool hasG2,
}) {
  final selected = <ReassignTarget>{ReassignTarget.patient};
  String reason = 'lost';

  return showDialog<ReassignSelection>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget buildTargetCard({
            required ReassignTarget target,
            required String title,
            required IconData icon,
          }) {
            final isSelected = selected.contains(target);
            return GestureDetector(
              onTap: () => setLocal(() {
                if (isSelected) {
                  if (selected.length > 1) selected.remove(target);
                } else {
                  selected.add(target);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildReasonChip({
            required String value,
            required String label,
          }) {
            final isSelected = reason == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setLocal(() => reason = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nfc, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isEs ? 'Reasignar dispositivo' : 'Reassign device',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEs
                            ? '¿Qué dispositivo deseas reemplazar?'
                            : 'Which device do you want to replace?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildTargetCard(
                        target: ReassignTarget.patient,
                        title: isEs
                            ? 'Dispositivo del paciente'
                            : 'Patient device',
                        icon: Icons.watch_outlined,
                      ),
                      if (hasG1)
                        buildTargetCard(
                          target: ReassignTarget.guardian1,
                          title: hasG2
                              ? (isEs ? 'Dispositivo guardián 1' : 'Guardian 1')
                              : (isEs ? 'Dispositivo guardián' : 'Guardian'),
                          icon: Icons.contact_emergency_outlined,
                        ),
                      if (hasG2)
                        buildTargetCard(
                          target: ReassignTarget.guardian2,
                          title: isEs ? 'Dispositivo guardián 2' : 'Guardian 2',
                          icon: Icons.contact_emergency_outlined,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        isEs
                            ? 'Motivo del reemplazo'
                            : 'Reason for replacement',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          buildReasonChip(
                            value: 'lost',
                            label: isEs ? 'Pérdida' : 'Lost',
                          ),
                          const SizedBox(width: 10),
                          buildReasonChip(
                            value: 'damaged',
                            label: isEs ? 'Dañada' : 'Damaged',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                isEs ? 'Cancelar' : 'Cancel',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: selected.isEmpty
                                  ? null
                                  : () {
                                      final ordered = <ReassignTarget>[
                                        ReassignTarget.patient,
                                        ReassignTarget.guardian1,
                                        ReassignTarget.guardian2,
                                      ].where(selected.contains).toList();
                                      Navigator.of(dialogCtx).pop(
                                        ReassignSelection(
                                          targets: ordered,
                                          reason: reason,
                                        ),
                                      );
                                    },
                              child: Text(
                                isEs ? 'Continuar' : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
