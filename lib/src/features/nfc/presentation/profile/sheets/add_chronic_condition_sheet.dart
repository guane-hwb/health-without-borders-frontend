import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class AddChronicConditionSheet extends StatefulWidget {
  const AddChronicConditionSheet({super.key, required this.onAdd});
  final ValueChanged<ChronicConditionItem> onAdd;

  @override
  State<AddChronicConditionSheet> createState() =>
      _AddChronicConditionSheetState();
}

class _AddChronicConditionSheetState extends State<AddChronicConditionSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canConfirm = _ctrl.text.trim().isNotEmpty;

    return SheetScaffold(
      title: s.addChronicConditionTitle,
      confirmLabel: s.confirm,
      confirmIcon: Icons.add,
      canConfirm: canConfirm,
      onConfirm: () {
        widget.onAdd(
          ChronicConditionItem(chronicDescription: _ctrl.text.trim()),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
