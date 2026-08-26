// lib/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/hwb_text_field.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

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
  late TextEditingController _uidCtrl;
  late String _relationship;
  bool _scanning = false;

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
    _uidCtrl = TextEditingController(text: widget.guardian.deviceUid ?? '');
    _relationship = widget.guardian.relationship;
    _uidCtrl.addListener(_onUidChanged);
  }

  void _onUidChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _uidCtrl.removeListener(_onUidChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanGuardianNfc() async {
    setState(() => _scanning = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() {
          _uidCtrl.text = uid;
          _scanning = false;
        });
      }
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).guardianNfcUnavailable),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).guardianNfcError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

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
            deviceUid: _uidCtrl.text.trim().isEmpty
                ? null
                : _uidCtrl.text.trim(),
            consent: widget.guardian.consent,
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(s.guardianFullName),
          HwbTextField(
            label: '',
            controller: _nameCtrl,
            hint: s.guardianFullNameHint,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _label(s.guardianRelationship),
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
          _label(s.guardianPhoneLabel),
          HwbTextField(
            label: '',
            controller: _phoneCtrl,
            hint: s.guardianPhoneHint,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _label(s.guardianNfcDevice),
          Row(
            children: [
              Expanded(
                child: HwbTextField(
                  label: '',
                  controller: _uidCtrl,
                  hint: s.guardianNfcUidHint,
                  icon: _uidCtrl.text.trim().isNotEmpty
                      ? Icons.check_circle_outline
                      : Icons.family_restroom,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _scanning ? null : _scanGuardianNfc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.nfc, size: 22, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
