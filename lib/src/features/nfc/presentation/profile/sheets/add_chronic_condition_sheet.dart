import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';
import '../shared/voice_text_area.dart';

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
          VoiceTextArea(
            label: s.condition.toUpperCase(),
            controller: _ctrl,
            hint: s.chronicConditionHint,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
