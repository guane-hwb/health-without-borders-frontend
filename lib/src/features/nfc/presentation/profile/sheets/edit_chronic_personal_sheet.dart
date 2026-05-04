// lib/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../shared/sheet_scaffold.dart';

class EditChronicPersonalSheet extends StatefulWidget {
  const EditChronicPersonalSheet({
    super.key,
    required this.title,
    required this.currentValue,
    required this.onConfirm,
  });

  final String title;
  final String? currentValue;
  final ValueChanged<String?> onConfirm;

  @override
  State<EditChronicPersonalSheet> createState() =>
      _EditChronicPersonalSheetState();
}

class _EditChronicPersonalSheetState extends State<EditChronicPersonalSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: widget.title,
      subtitle: 'Texto libre — el sistema codifica automáticamente',
      onConfirm: () {
        final text = _ctrl.text.trim();
        widget.onConfirm(text.isEmpty ? null : text);
        Navigator.of(context).pop();
      },
      child: TextField(
        controller: _ctrl,
        maxLines: 8,
        style: const TextStyle(fontSize: 14, height: 1.4),
        decoration: InputDecoration(
          hintText: 'Describa la información en texto libre...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }
}
