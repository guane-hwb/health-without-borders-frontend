import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class AddMedicationSheet extends StatefulWidget {
  const AddMedicationSheet({super.key, required this.onAdd});
  final ValueChanged<MedicationStatementItem> onAdd;

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _status = 'active';

  static const List<String> _statusKeys = [
    'active',
    'completed',
    'stopped',
    'unknown',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Maps each status code to its localized label via [AppStrings].
  String _statusLabel(AppStrings s, String code) => switch (code) {
    'active' => s.medStatusActive,
    'completed' => s.medStatusCompleted,
    'stopped' => s.medStatusStopped,
    'unknown' => s.medStatusUnknown,
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canConfirm = _nameCtrl.text.trim().isNotEmpty;

    return SheetScaffold(
      title: s.addMedicationTitle,
      subtitle: s.addMedicationSubtitle,
      confirmLabel: s.confirm,
      confirmIcon: Icons.add,
      canConfirm: canConfirm,
      onConfirm: () {
        widget.onAdd(
          MedicationStatementItem(
            medicationName: _nameCtrl.text.trim(),
            status: _status,
            dosage: _dosageCtrl.text.trim().isEmpty
                ? null
                : _dosageCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.medicationLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.medicationHint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            s.statusLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _statusKeys.map((code) {
              final sel = _status == code;
              return GestureDetector(
                onTap: () => setState(() => _status = code),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    _statusLabel(s, code),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            s.dosageLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _dosageCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: s.dosageHint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            s.notesLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: s.notesHint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
