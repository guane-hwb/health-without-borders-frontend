import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';

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
          Widget deviceCheck(ReassignTarget t, String label) {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(label),
              value: selected.contains(t),
              onChanged: (v) => setLocal(() {
                if (v ?? false) {
                  selected.add(t);
                } else {
                  selected.remove(t);
                }
              }),
            );
          }

          Widget reasonSegments() {
            return SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: 'lost',
                  label: Text(isEs ? 'Perdida' : 'Lost'),
                ),
                ButtonSegment<String>(
                  value: 'damaged',
                  label: Text(isEs ? 'Dañada' : 'Damaged'),
                ),
              ],
              selected: <String>{reason},
              onSelectionChanged: (Set<String> s) =>
                  setLocal(() => reason = s.first),
            );
          }

          return AlertDialog(
            title: Text(isEs ? 'Reasignar manilla' : 'Reassign bracelet'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEs
                        ? '¿Qué dispositivo se va a reemplazar?'
                        : 'Which device is being replaced?',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  deviceCheck(
                    ReassignTarget.patient,
                    isEs ? 'Manilla del paciente' : 'Patient bracelet',
                  ),
                  if (hasG1)
                    deviceCheck(
                      ReassignTarget.guardian1,
                      hasG2
                          ? (isEs
                                ? 'Tarjeta del guardián 1'
                                : 'Guardian card 1')
                          : (isEs ? 'Tarjeta del guardián' : 'Guardian card'),
                    ),
                  if (hasG2)
                    deviceCheck(
                      ReassignTarget.guardian2,
                      isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2',
                    ),
                  const SizedBox(height: 12),
                  Text(
                    isEs ? 'Motivo' : 'Reason',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  reasonSegments(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(AppStrings.of(ctx).cancel),
              ),
              ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final ordered = <ReassignTarget>[
                          ReassignTarget.patient,
                          ReassignTarget.guardian1,
                          ReassignTarget.guardian2,
                        ].where(selected.contains).toList();
                        Navigator.of(dialogCtx).pop(
                          ReassignSelection(targets: ordered, reason: reason),
                        );
                      },
                child: Text(isEs ? 'Continuar' : 'Continue'),
              ),
            ],
          );
        },
      );
    },
  );
}
