// lib/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
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
  late final String _initialValue;

  @override
  void initState() {
    super.initState();
    _initialValue = widget.currentValue ?? '';
    _ctrl = TextEditingController(text: _initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges => _ctrl.text.trim() != _initialValue.trim();

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final s = AppStrings.of(context);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          s.unsyncedChangesTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          s.exitWithoutSyncMsg,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.exit, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _handleClose() async {
    if (await _onWillPop() && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _submitSave() {
    final text = _ctrl.text.trim();
    widget.onConfirm(text.isEmpty ? null : text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _handleClose();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _handleClose,
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const Divider(
                  height: 24,
                  thickness: 1,
                  color: AppColors.divider,
                ),

                VoiceTextArea(
                  label: widget.title,
                  controller: _ctrl,
                  hint: s.editChronicPersonalHint,
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    label: Text(
                      s.confirmChanges,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
