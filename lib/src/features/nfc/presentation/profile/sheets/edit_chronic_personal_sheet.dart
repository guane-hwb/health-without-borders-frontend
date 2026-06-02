// lib/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../shared/sheet_scaffold.dart';
import '../shared/voice_text_area.dart';

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
    final s = AppStrings.of(context);

    return SheetScaffold(
      title: widget.title,
      subtitle: s.editChronicPersonalSubtitle,
      onConfirm: () {
        final text = _ctrl.text.trim();
        widget.onConfirm(text.isEmpty ? null : text);
        Navigator.of(context).pop();
      },
      child: VoiceTextArea(
        label: widget.title,
        controller: _ctrl,
        hint: s.editChronicPersonalHint,
        maxLines: 8,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
