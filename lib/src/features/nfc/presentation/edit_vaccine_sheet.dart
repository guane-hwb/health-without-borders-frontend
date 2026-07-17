import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';

class EditVaccineSheet extends StatefulWidget {
  const EditVaccineSheet({
    super.key,
    this.initialVaccine,
    this.initialVaccineCode,
    this.initialDose,
    this.initialDate,
    this.initialAdministeredBy,
    this.initialAdministeredAt,
  });
  final String? initialVaccine,
      initialVaccineCode,
      initialDose,
      initialDate,
      initialAdministeredBy,
      initialAdministeredAt;
  @override
  State<EditVaccineSheet> createState() => _EditVaccineSheetState();
}

class _EditVaccineSheetState extends State<EditVaccineSheet> {
  late final TextEditingController _nameCtrl,
      _codeCtrl,
      _doseCtrl,
      _dateCtrl,
      _byCtrl,
      _atCtrl;
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialVaccine ?? '');
    _codeCtrl = TextEditingController(text: widget.initialVaccineCode ?? '');
    _doseCtrl = TextEditingController(text: widget.initialDose ?? '');
    _dateCtrl = TextEditingController(text: widget.initialDate ?? '');
    _byCtrl = TextEditingController(text: widget.initialAdministeredBy ?? '');
    _atCtrl = TextEditingController(text: widget.initialAdministeredAt ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _doseCtrl.dispose();
    _dateCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.vaccine,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            _f(s.vaccineName, _nameCtrl),
            const SizedBox(height: 10),
            _f(s.cvxCode, _codeCtrl, hint: 'e.g., 140'),
            const SizedBox(height: 10),
            _f(s.dose, _doseCtrl, hint: 'e.g., 1'),
            const SizedBox(height: 10),
            _f(s.date, _dateCtrl, hint: 'YYYY-MM-DD'),
            const SizedBox(height: 10),
            _f(s.administeredBy, _byCtrl),
            const SizedBox(height: 10),
            _f(s.administeredAt, _atCtrl),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save, size: 16, color: AppColors.white),
                label: Text(
                  s.save,
                  style: const TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(String label, TextEditingController c, {String? hint}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      TextField(
        controller: c,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}
