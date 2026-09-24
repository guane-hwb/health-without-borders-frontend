// lib/src/features/nfc/presentation/profile/sheets/edit_address_sheet.dart

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

class EditAddressSheet extends StatefulWidget {
  const EditAddressSheet({
    super.key,
    required this.address,
    required this.onConfirm,
  });

  final Address address;
  final ValueChanged<Address> onConfirm;

  @override
  State<EditAddressSheet> createState() => _EditAddressSheetState();
}

class _EditAddressSheetState extends State<EditAddressSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late String _zone;

  late final String _initialStreet;
  late final String _initialCity;
  late final String _initialState;
  late final String _initialZone;

  @override
  void initState() {
    super.initState();
    _initialStreet = widget.address.street ?? '';
    _initialCity = widget.address.city;
    _initialState = widget.address.state;
    _initialZone = widget.address.zone ?? '01';

    _streetCtrl = TextEditingController(text: _initialStreet);
    _cityCtrl = TextEditingController(text: _initialCity);
    _stateCtrl = TextEditingController(text: _initialState);
    _zone = _initialZone;
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final streetChanged = _streetCtrl.text.trim() != _initialStreet;
    final cityChanged = _cityCtrl.text.trim() != _initialCity;
    final stateChanged = _stateCtrl.text.trim() != _initialState;
    final zoneChanged = _zone != _initialZone;

    return streetChanged || cityChanged || stateChanged || zoneChanged;
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
      Address(
        street: _streetCtrl.text.trim().isEmpty
            ? null
            : _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        cityCode: widget.address.cityCode,
        state: _stateCtrl.text.trim(),
        zipCode: widget.address.zipCode,
        country: widget.address.country,
        countryName: widget.address.countryName,
        zone: _zone,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.editResidence,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (s.addressZoneSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.addressZoneSubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
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
                    label: s.address,
                    controller: _streetCtrl,
                    hint: s.streetHint,
                    prefixIcon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: '${s.municipality} *',
                    controller: _cityCtrl,
                    hint: s.cityHint,
                    prefixIcon: Icons.location_city,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El municipio es obligatorio'
                            : 'Municipality is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: '${s.department} *',
                    controller: _stateCtrl,
                    hint: s.stateHint,
                    prefixIcon: Icons.map_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El departamento es obligatorio'
                            : 'Department is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _LabelText(text: s.zone),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _ZoneChip(
                        label: s.zoneUrban,
                        selected: _zone == '01',
                        onTap: () => setState(() => _zone = '01'),
                      ),
                      const SizedBox(width: 10),
                      _ZoneChip(
                        label: s.zoneRural,
                        selected: _zone == '02',
                        onTap: () => setState(() => _zone = '02'),
                      ),
                    ],
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
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
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
          style: _kInputStyle,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.primary),
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

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
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
