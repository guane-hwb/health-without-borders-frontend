// lib/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

const _kEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
);
const _kFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.primary, width: 2),
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
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _docNumberCtrl;
  late String _relationship;
  late String _selectedDocType;

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
    _nameCtrl = TextEditingController(text: widget.guardian.name);
    _phoneCtrl = TextEditingController(text: widget.guardian.phone);
    _docNumberCtrl = TextEditingController(
      text: widget.guardian.docNumber ?? widget.guardian.documentNumber ?? '',
    );
    _relationship = widget.guardian.relationship;
    _selectedDocType =
        widget.guardian.docType ?? widget.guardian.documentType ?? 'CC';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final docTypes = {'CC': s.docTypeCC, 'CE': s.docTypeCE};

    final dynamicTitle = widget.guardianIndex == 1
        ? (isEs ? 'Editar Guardián Principal' : 'Edit Primary Guardian')
        : (isEs ? 'Editar Guardián Secundario' : 'Edit Secondary Guardian');

    return SheetScaffold(
      title: dynamicTitle,
      onConfirm: () {
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
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledTextField(
            label: s.guardianFullName,
            controller: _nameCtrl,
            hint: s.guardianFullNameHint,
            prefixIcon: Icons.person_outline,
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
                      color: sel ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    _relationshipLabel(s, code),
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
          LabeledTextField(
            label: s.guardianPhoneLabel,
            controller: _phoneCtrl,
            hint: s.guardianPhoneHint,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _DocTypeSelector(
            label: s.documentTypeLabel,
            value: _selectedDocType,
            options: docTypes,
            onChanged: (v) => setState(() => _selectedDocType = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: s.documentNumberLabel,
            controller: _docNumberCtrl,
            hint: 'Ej. 1234567890',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
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
    final itemHeight = 48.0;
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
