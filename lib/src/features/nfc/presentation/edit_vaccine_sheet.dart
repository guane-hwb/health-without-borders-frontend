import 'package:flutter/material.dart';

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

  final String? initialVaccine;
  final String? initialVaccineCode;
  final String? initialDose;
  final String? initialDate;
  final String? initialAdministeredBy;
  final String? initialAdministeredAt;

  @override
  State<EditVaccineSheet> createState() => _EditVaccineSheetState();
}

class _EditVaccineSheetState extends State<EditVaccineSheet> {
  late final TextEditingController _vaccineNameCtrl;
  late final TextEditingController _vaccineCodeCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _byCtrl;
  late final TextEditingController _atCtrl;

  @override
  void initState() {
    super.initState();
    _vaccineNameCtrl =
        TextEditingController(text: widget.initialVaccine ?? '');
    _vaccineCodeCtrl =
        TextEditingController(text: widget.initialVaccineCode ?? '');
    _doseCtrl = TextEditingController(text: widget.initialDose ?? '');
    _dateCtrl = TextEditingController(text: widget.initialDate ?? '');
    _byCtrl =
        TextEditingController(text: widget.initialAdministeredBy ?? '');
    _atCtrl =
        TextEditingController(text: widget.initialAdministeredAt ?? '');
  }

  @override
  void dispose() {
    _vaccineNameCtrl.dispose();
    _vaccineCodeCtrl.dispose();
    _doseCtrl.dispose();
    _dateCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Vaccine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            _field('Vaccine Name', _vaccineNameCtrl,
                hint: 'e.g., Influenza Trivalente'),
            const SizedBox(height: 10),
            _field('CVX Code', _vaccineCodeCtrl, hint: 'e.g., 140'),
            const SizedBox(height: 10),
            _field('Dose', _doseCtrl, hint: 'e.g., 1'),
            const SizedBox(height: 10),
            _field('Date (YYYY-MM-DD)', _dateCtrl, hint: 'e.g., 2026-04-22'),
            const SizedBox(height: 10),
            _field('Administered By', _byCtrl,
                hint: 'e.g., Enf. Ana Ruiz'),
            const SizedBox(height: 10),
            _field('Administered At', _atCtrl,
                hint: 'e.g., Punto de salud frontera'),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Return the vaccine data via Navigator.pop()
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon:
                    const Icon(Icons.save, size: 16, color: AppColors.white),
                label: const Text('Save',
                    style:
                        TextStyle(color: AppColors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
}