// lib/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class AddAllergySheet extends StatefulWidget {
  const AddAllergySheet({super.key, required this.onAdd});
  final ValueChanged<AllergyInfo> onAdd;

  @override
  State<AddAllergySheet> createState() => _AddAllergySheetState();
}

class _AddAllergySheetState extends State<AddAllergySheet> {
  final _allergenCtrl = TextEditingController();
  final _reactionCtrl = TextEditingController();
  String _category = '01';

  // Category codes — labels resolved from AppStrings at build time
  static const List<String> _categoryCodes = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
  ];

  /// Returns the translated label for an allergy category code.
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
  void dispose() {
    _allergenCtrl.dispose();
    _reactionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canConfirm = _allergenCtrl.text.trim().isNotEmpty;

    return SheetScaffold(
      title: s.addAllergyBtn,
      confirmLabel: s.add,
      confirmIcon: Icons.add,
      canConfirm: canConfirm,
      onConfirm: () {
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
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category ──────────────────────────────────────────────────────
          Text(
            s.allergyCategoryLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
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
                      color: sel ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Allergen ──────────────────────────────────────────────────────
          const SizedBox(height: 14),
          Text(
            s.allergenLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _allergenCtrl,
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: s.allergenHint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ),

          // ── Reaction ──────────────────────────────────────────────────────
          const SizedBox(height: 14),
          Text(
            s.reactionOptionalLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _reactionCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: s.reactionHint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
