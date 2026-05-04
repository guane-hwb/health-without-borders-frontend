// lib/src/features/nfc/presentation/profile/sheets/add_allergy_sheet.dart
import 'package:flutter/material.dart';

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

  static const Map<String, String> _categories = {
    '01': 'Medicamento',
    '02': 'Alimento',
    '03': 'Sust. ambiente',
    '04': 'Sust. piel',
    '05': 'Picadura',
    '06': 'Otra',
  };

  @override
  void dispose() {
    _allergenCtrl.dispose();
    _reactionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _allergenCtrl.text.trim().isNotEmpty;
    return SheetScaffold(
      title: 'Agregar alergia',
      confirmLabel: 'Agregar',
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
          const Text(
            'Categoría',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _categories.entries.map((e) {
              final sel = _category == e.key;
              return GestureDetector(
                onTap: () => setState(() => _category = e.key),
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
                    e.value,
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
          const SizedBox(height: 14),
          const Text(
            'Alérgeno',
            style: TextStyle(
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
              hintText: 'ej: Penicilina, Maní, Polen...',
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
          const SizedBox(height: 14),
          const Text(
            'Reacción (opcional)',
            style: TextStyle(
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
              hintText: 'ej: Erupción cutánea generalizada, Edema labial...',
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
