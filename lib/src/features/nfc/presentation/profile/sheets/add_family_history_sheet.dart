// lib/src/features/nfc/presentation/profile/sheets/add_family_history_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class AddFamilyHistorySheet extends StatefulWidget {
  const AddFamilyHistorySheet({super.key, required this.onAdd});

  final ValueChanged<FamilyHistoryItem> onAdd;

  @override
  State<AddFamilyHistorySheet> createState() => _AddFamilyHistorySheetState();
}

class _AddFamilyHistorySheetState extends State<AddFamilyHistorySheet> {
  final _ctrl = TextEditingController();
  String _relationship = '01';

  static const List<String> _relationshipKeys = ['01', '02', '03', '04'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Maps each relationship code to its localized label via [AppStrings].
  String _label(AppStrings s, String code) => switch (code) {
    '01' => s.relParents,
    '02' => s.relSiblings,
    '03' => s.relUncles,
    '04' => s.relGrandparents,
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canConfirm = _ctrl.text.trim().isNotEmpty;

    return SheetScaffold(
      title: s.addFamilyHistory,
      confirmLabel: s.confirm,
      confirmIcon: Icons.add,
      canConfirm: canConfirm,
      onConfirm: () {
        widget.onAdd(
          FamilyHistoryItem(
            conditionDescription: _ctrl.text.trim(),
            relationship: _relationship,
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.relationship,
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
            children: _relationshipKeys.map((code) {
              final sel = _relationship == code;
              return GestureDetector(
                onTap: () => setState(() => _relationship = code),
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
                    _label(s, code),
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
            s.condition,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.chronicConditionHint,
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
