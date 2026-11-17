// lib/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import 'edit_vital_signs_helpers.dart' as helpers;

class EditVitalSignsSheet extends StatefulWidget {
  const EditVitalSignsSheet({
    super.key,
    this.weight,
    this.height,
    this.bloodType,
    this.isBloodTypeCertified = false,
    this.previousWeight,
    this.previousHeight,
    required this.onConfirm,
  });

  final double? weight;
  final double? height;
  final String? bloodType;
  final bool isBloodTypeCertified;
  final double? previousWeight;
  final double? previousHeight;
  final void Function({
    double? weight,
    double? height,
    String? bloodType,
    bool isBloodTypeCertified,
  })
  onConfirm;

  @override
  State<EditVitalSignsSheet> createState() => _EditVitalSignsSheetState();
}

class _EditVitalSignsSheetState extends State<EditVitalSignsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  String? _selectedBloodType;
  String? _errorMessage;

  late final String _initialWeightText;
  late final String _initialHeightText;
  late final String? _initialBloodType;

  late bool _isCertified;
  late final bool _isLocked;

  static const _bloodTypeOptions = {
    'O+': 'O+',
    'O-': 'O-',
    'A+': 'A+',
    'A-': 'A-',
    'B+': 'B+',
    'B-': 'B-',
    'AB+': 'AB+',
    'AB-': 'AB-',
  };

  @override
  void initState() {
    super.initState();
    _initialWeightText = helpers.weightInitText(widget.weight);
    _initialHeightText = helpers.heightInitText(widget.height);
    _initialBloodType = widget.bloodType;

    _weightCtrl = TextEditingController(text: _initialWeightText);
    _heightCtrl = TextEditingController(text: _initialHeightText);
    _selectedBloodType = _initialBloodType;

    _isCertified = widget.isBloodTypeCertified;
    _isLocked =
        widget.isBloodTypeCertified &&
        (widget.bloodType?.trim().isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final weightChanged = _weightCtrl.text.trim() != _initialWeightText;
    final heightChanged = _heightCtrl.text.trim() != _initialHeightText;
    final bloodTypeChanged = _selectedBloodType != _initialBloodType;
    final certChanged = _isCertified != widget.isBloodTypeCertified;

    return weightChanged || heightChanged || bloodTypeChanged || certChanged;
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

  void _handleConfirm() {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final wText = _weightCtrl.text;
    final hText = _heightCtrl.text;

    double? w;
    if (wText.trim().isNotEmpty) {
      w = helpers.parseWeight(wText);
      if (w == null || !helpers.isWeightInRange(w)) {
        setState(() {
          _errorMessage = helpers.weightErrorMessage(isEs: isEs);
        });
        return;
      }
    }

    double? h;
    if (hText.trim().isNotEmpty) {
      h = helpers.parseHeight(hText);
      if (h == null || !helpers.isHeightInRange(h)) {
        setState(() {
          _errorMessage = helpers.heightErrorMessage(isEs: isEs);
        });
        return;
      }
    }

    widget.onConfirm(
      weight: w,
      height: h,
      bloodType: _selectedBloodType,
      isBloodTypeCertified: _selectedBloodType != null ? _isCertified : false,
    );
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
                // Drag handle superior
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
                      s.editMeasurements,
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

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _FieldLabel(label: s.weightKg),
                const SizedBox(height: 6),
                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: const TextStyle(
                      color: AppColors.disabled,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB0B8C4),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (helpers.showPreviousWeight(widget.previousWeight)) ...[
                  const SizedBox(height: 4),
                  Text(
                    helpers.previousWeightText(
                      s.previous,
                      widget.previousWeight!,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                _FieldLabel(label: s.heightCm),
                const SizedBox(height: 6),
                TextField(
                  controller: _heightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                      color: AppColors.disabled,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB0B8C4),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (helpers.showPreviousHeight(widget.previousHeight)) ...[
                  const SizedBox(height: 4),
                  Text(
                    helpers.previousHeightText(
                      s.previous,
                      widget.previousHeight!,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    _FieldLabel(label: s.bloodType),
                    if (_isLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.isEs ? 'Certificado' : 'Certified',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                IgnorePointer(
                  ignoring: _isLocked,
                  child: Opacity(
                    opacity: _isLocked ? 0.55 : 1.0,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bloodTypeOptions.entries.map((e) {
                        final selected = e.key == _selectedBloodType;
                        return GestureDetector(
                          onTap: _isLocked
                              ? null
                              : () {
                                  setState(() {
                                    _selectedBloodType = selected
                                        ? null
                                        : e.key;
                                    if (_selectedBloodType == null) {
                                      _isCertified = false;
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFB0B8C4),
                                width: selected ? 2 : 1.5,
                              ),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (_isLocked) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.isEs
                        ? 'Verificado con certificado/examen. No se puede modificar.'
                        : 'Verified with certificate/lab test. Cannot be edited.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else if (_selectedBloodType != null) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    value: _isCertified,
                    onChanged: (v) => setState(() => _isCertified = v ?? false),
                    title: Text(
                      s.isEs
                          ? 'El cuidador mostró certificado/examen (bloquear edición)'
                          : 'Caregiver showed certificate/test (lock editing)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleConfirm,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
