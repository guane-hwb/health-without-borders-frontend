// lib/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../shared/sheet_scaffold.dart';
import 'edit_vital_signs_helpers.dart' as helpers;

class EditVitalSignsSheet extends StatefulWidget {
  const EditVitalSignsSheet({
    super.key,
    this.weight,
    this.height,
    this.bloodType,
    this.previousWeight,
    this.previousHeight,
    required this.onConfirm,
  });

  final double? weight;
  final double? height;
  final String? bloodType;
  final double? previousWeight;
  final double? previousHeight;
  final void Function({double? weight, double? height, String? bloodType})
  onConfirm;

  @override
  State<EditVitalSignsSheet> createState() => _EditVitalSignsSheetState();
}

class _EditVitalSignsSheetState extends State<EditVitalSignsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  String? _selectedBloodType;
  String? _errorMessage;

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
    _weightCtrl = TextEditingController(
      text: helpers.weightInitText(widget.weight),
    );
    _heightCtrl = TextEditingController(
      text: helpers.heightInitText(widget.height),
    );
    _selectedBloodType = widget.bloodType;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
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

    widget.onConfirm(weight: w, height: h, bloodType: _selectedBloodType);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return SheetScaffold(
      title: s.editMeasurements,
      onConfirm: _handleConfirm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Weight
          _FieldLabel(label: s.weightKg),
          const SizedBox(height: 6),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              helpers.previousWeightText(s.previous, widget.previousWeight!),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Height
          _FieldLabel(label: s.heightCm),
          const SizedBox(height: 6),
          TextField(
            controller: _heightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              helpers.previousHeightText(s.previous, widget.previousHeight!),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Blood Type Editable
          _FieldLabel(label: s.bloodType),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodTypeOptions.entries.map((e) {
              final selected = e.key == _selectedBloodType;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBloodType = selected ? null : e.key;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.white,
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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
