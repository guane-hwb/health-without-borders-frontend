import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';

class EditVaccineSheet extends StatefulWidget {
  const EditVaccineSheet({
    super.key,
    this.initialVaccine,
    this.initialDose,
    this.initialDate,
    this.initialAdministeredBy,
    this.initialAdministeredAt,
  });

  final String? initialVaccine;
  final String? initialDose;
  final String? initialDate;
  final String? initialAdministeredBy;
  final String? initialAdministeredAt;

  @override
  State<EditVaccineSheet> createState() => _EditVaccineSheetState();
}

class _EditVaccineSheetState extends State<EditVaccineSheet> {
  late final TextEditingController _vaccineCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _byCtrl;
  late final TextEditingController _atCtrl;

  @override
  void initState() {
    super.initState();
    _vaccineCtrl = TextEditingController(text: widget.initialVaccine);
    _doseCtrl = TextEditingController(text: widget.initialDose);
    _dateCtrl = TextEditingController(text: widget.initialDate);
    _byCtrl = TextEditingController(text: widget.initialAdministeredBy);
    _atCtrl = TextEditingController(text: widget.initialAdministeredAt);
  }

  @override
  void dispose() {
    _vaccineCtrl.dispose();
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
              'Edit vaccine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 18),
            _buildField('Vaccine *', _vaccineCtrl, hasDropdown: true),
            const SizedBox(height: 14),
            _buildField('Dose *', _doseCtrl),
            const SizedBox(height: 14),
            _buildField('Date *', _dateCtrl, prefixIcon: Icons.calendar_today),
            const SizedBox(height: 14),
            _buildField('Administrated By *', _byCtrl),
            const SizedBox(height: 14),
            _buildField('Adminitrated At *', _atCtrl),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save, size: 18, color: AppColors.white),
                      label: const Text(
                        'Save',
                        style: TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A396),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    IconData? prefixIcon,
    bool hasDropdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
            suffixIcon: hasDropdown
                ? const Icon(Icons.arrow_drop_down, color: AppColors.secondary)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      ],
    );
  }
}
