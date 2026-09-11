// lib/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart

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

class EditGuardianSheet extends StatefulWidget {
  const EditGuardianSheet({
    super.key,
    required this.guardian,
    required this.guardianIndex,
    required this.onConfirm,
  });

  final GuardianInfo guardian;
  final int guardianIndex;
  final ValueChanged<GuardianInfo> onConfirm;

  @override
  State<EditGuardianSheet> createState() => _EditGuardianSheetState();
}

class _EditGuardianSheetState extends State<EditGuardianSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _docNumberCtrl;
  late String _relationship;
  late String _selectedDocType;

  late final String _initialName;
  late final String _initialPhone;
  late final String _initialDocNumber;
  late final String _initialRelationship;
  late final String _initialDocType;

  static const List<String> _relationshipCodes = ['01', '02', '03', '04'];

  String _relationshipLabel(AppStrings s, String code) {
    switch (code) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return code;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialName = widget.guardian.name;
    _initialPhone = widget.guardian.phone;
    _initialDocNumber =
        widget.guardian.docNumber ?? widget.guardian.documentNumber ?? '';
    _initialRelationship = widget.guardian.relationship;
    _initialDocType =
        widget.guardian.docType ?? widget.guardian.documentType ?? 'CC';

    _nameCtrl = TextEditingController(text: _initialName);
    _phoneCtrl = TextEditingController(text: _initialPhone);
    _docNumberCtrl = TextEditingController(text: _initialDocNumber);
    _relationship = _initialRelationship;
    _selectedDocType = _initialDocType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final nameChanged = _nameCtrl.text.trim() != _initialName;
    final phoneChanged = _phoneCtrl.text.trim() != _initialPhone;
    final docNumChanged = _docNumberCtrl.text.trim() != _initialDocNumber;
    final relChanged = _relationship != _initialRelationship;
    final docTypeChanged = _selectedDocType != _initialDocType;

    return nameChanged ||
        phoneChanged ||
        docNumChanged ||
        relChanged ||
        docTypeChanged;
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

    widget.onConfirm(
      GuardianInfo(
        name: _nameCtrl.text.trim(),
        relationship: _relationship,
        phone: _phoneCtrl.text.trim(),
        docType: _selectedDocType,
        docNumber: _docNumberCtrl.text.trim().isEmpty
            ? null
            : _docNumberCtrl.text.trim(),
        deviceUid: widget.guardian.deviceUid,
        consent: widget.guardian.consent,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final docTypes = {'CC': s.docTypeCC, 'CE': s.docTypeCE};

    final dynamicTitle = widget.guardianIndex == 1
        ? (isEs ? 'Editar Guardián Principal' : 'Edit Primary Guardian')
        : (isEs ? 'Editar Guardián Secundario' : 'Edit Secondary Guardian');

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
                        dynamicTitle,
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

                  _ValidatedField(
                    label: s.guardianFullName,
                    controller: _nameCtrl,
                    hint: s.guardianFullNameHint,
                    prefixIcon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El nombre del guardián es obligatorio'
                            : 'Guardian name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _LabelText(text: s.guardianRelationship),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _relationshipCodes.map((code) {
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
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            _relationshipLabel(s, code),
                            style: TextStyle(
                              fontSize: 13,
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
                    label: s.guardianPhoneLabel,
                    controller: _phoneCtrl,
                    hint: s.guardianPhoneHint,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El teléfono es obligatorio'
                            : 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _DocTypeSelector(
                    label: s.documentTypeLabel,
                    value: _selectedDocType,
                    options: docTypes,
                    onChanged: (v) => setState(() => _selectedDocType = v),
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: s.documentNumberLabel,
                    controller: _docNumberCtrl,
                    hint: 'Ej. 1234567890',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El documento es obligatorio'
                            : 'Document number is required';
                      }
                      return null;
                    },
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
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
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
          keyboardType: keyboardType,
          style: _kInputStyle,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: AppColors.textSecondary,
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

class _DocTypeSelector extends StatefulWidget {
  const _DocTypeSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_DocTypeSelector> createState() => _DocTypeSelectorState();
}

class _DocTypeSelectorState extends State<_DocTypeSelector> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.options[widget.value] ?? '';
    const itemHeight = 48.0;
    final calculatedHeight = (widget.options.length * itemHeight).clamp(
      itemHeight,
      250.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(text: widget.label),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              controller: _menuController,
              style: MenuStyle(
                fixedSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, calculatedHeight),
                ),
                maximumSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, calculatedHeight),
                ),
                backgroundColor: WidgetStateProperty.all(AppColors.white),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: _kEnabledBorder,
                      focusedBorder: _kFocusedBorder,
                      border: _kEnabledBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedLabel,
                                  style: _kInputStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: widget.options.entries.map((e) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: itemHeight,
                  child: MenuItemButton(
                    onPressed: () {
                      widget.onChanged(e.key);
                      _menuController.close();
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: _kInputStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
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
