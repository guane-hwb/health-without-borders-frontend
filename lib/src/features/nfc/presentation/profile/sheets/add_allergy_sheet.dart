// lib/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';

const _kEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
);
const _kFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.primary, width: 2),
);
const _kErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.error, width: 1.5),
);
const _kInputStyle = TextStyle(
  fontSize: 15,
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w500,
);

class AddAllergySheet extends StatefulWidget {
  const AddAllergySheet({super.key, required this.onAdd});
  final ValueChanged<AllergyInfo> onAdd;

  @override
  State<AddAllergySheet> createState() => _AddAllergySheetState();
}

class _AddAllergySheetState extends State<AddAllergySheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _allergenCtrl;
  late TextEditingController _reactionCtrl;
  late String _category;

  static const List<String> _categoryCodes = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
  ];

  String _categoryLabel(AppStrings s, String code) {
    switch (code) {
      case '01':
        return s.allergenMedication;
      case '02':
        return s.allergenFood;
      case '03':
        return s.allergenEnvironment;
      case '04':
        return s.allergenSkin;
      case '05':
        return s.allergenInsect;
      case '06':
        return s.allergenOther;
      default:
        return code;
    }
  }

  @override
  void initState() {
    super.initState();
    _allergenCtrl = TextEditingController();
    _reactionCtrl = TextEditingController();
    _category = '01';
  }

  @override
  void dispose() {
    _allergenCtrl.dispose();
    _reactionCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final allergenEntered = _allergenCtrl.text.trim().isNotEmpty;
    final reactionEntered = _reactionCtrl.text.trim().isNotEmpty;
    final categoryChanged = _category != '01';

    return allergenEntered || reactionEntered || categoryChanged;
  }

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
    if (!_formKey.currentState!.validate()) return;

    widget.onAdd(
      AllergyInfo(
        category: _category,
        allergen: _allergenCtrl.text.trim(),
        reaction: _reactionCtrl.text.trim().isEmpty
            ? null
            : _reactionCtrl.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

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
            child: Form(
              key: _formKey,
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
                      Text(
                        s.addAllergyBtn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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

                  _LabelText(text: s.allergyCategoryLabel),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _categoryCodes.map((code) {
                      final sel = _category == code;
                      return GestureDetector(
                        onTap: () => setState(() => _category = code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.error : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppColors.error : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            _categoryLabel(s, code),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: '${s.allergenLabel} *',
                    controller: _allergenCtrl,
                    hint: s.allergenHint,
                    prefixIcon: Icons.warning_amber_rounded,
                    iconColor: AppColors.error,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El alérgeno es obligatorio'
                            : 'Allergen is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: s.reactionOptionalLabel,
                    controller: _reactionCtrl,
                    hint: s.reactionHint,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 3,
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
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      label: Text(
                        s.add,
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
      ),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  const _ValidatedField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.iconColor = AppColors.primary,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final Color iconColor;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(text: label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: _kInputStyle,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            prefixIcon: maxLines == 1
                ? Icon(prefixIcon, size: 20, color: iconColor)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(prefixIcon, size: 20, color: iconColor),
                  ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: _kEnabledBorder,
            focusedBorder: _kFocusedBorder,
            errorBorder: _kErrorBorder,
            focusedErrorBorder: _kErrorBorder,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
