import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'shared_read_nfc_header.dart';

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final TextEditingController _nameCtrl =
      TextEditingController(text: 'Sofia Rojas');
  final TextEditingController _dobCtrl =
      TextEditingController(text: '2018-03-22');
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  String _gender = 'Female';
  String _country = 'Colombia';
  String _bloodType = 'A+';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SharedReadNfcHeader(title: 'Edit/update'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Patient Information'),
                        const SizedBox(height: 12),
                        _textField('Name', _nameCtrl, icon: Icons.person),
                        const SizedBox(height: 12),
                        _textField('Date of Birth', _dobCtrl,
                            icon: Icons.calendar_today),
                        const SizedBox(height: 12),
                        _dropdownField('Gender', _gender, ['Female', 'Male'],
                            (String? v) {
                          if (v != null) setState(() => _gender = v);
                        }),
                        const SizedBox(height: 12),
                        _dropdownField(
                            'Country', _country, ['Colombia', 'Venezuela', 'Other'],
                            (String? v) {
                          if (v != null) setState(() => _country = v);
                        }),
                        const SizedBox(height: 20),
                        _sectionTitle('Physical information'),
                        const SizedBox(height: 12),
                        _textField('Weight', _weightCtrl,
                            icon: Icons.monitor_weight),
                        const SizedBox(height: 12),
                        _textField('Height', _heightCtrl,
                            icon: Icons.open_in_full),
                        const SizedBox(height: 12),
                        _dropdownField('Blood Type', _bloodType,
                            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                            (String? v) {
                          if (v != null) setState(() => _bloodType = v);
                        }),
                        const SizedBox(height: 20),
                        _sectionTitle('Vaccine'),
                        const SizedBox(height: 8),
                        _tableHeader(
                            const ['Vaccine', 'Does', 'Date', 'Administrated By']),
                        const SizedBox(height: 8),
                        _addButton('Add Vaccine'),
                        const SizedBox(height: 20),
                        _sectionTitle('Allergen'),
                        const SizedBox(height: 8),
                        _tableHeader(
                            const ['Allergen', 'Reaction', 'Severity', 'Notes']),
                        const SizedBox(height: 8),
                        _addButton('Add Allergen'),
                        const SizedBox(height: 24),
                        _bottomButtons(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon:
                icon != null ? Icon(icon, size: 18, color: AppColors.secondary) : null,
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

  Widget _dropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items
                  .map((String e) =>
                      DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(List<String> columns) {
    return Row(
      children: columns
          .map((String c) => Expanded(
                child: Text(c, style: const TextStyle(fontSize: 11)),
              ))
          .toList(),
    );
  }

  Widget _addButton(String label) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(Icons.add, size: 16, color: AppColors.white),
        label: Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _bottomButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF666666),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios,
                  size: 14, color: AppColors.white),
              label: const Text(
                'Back to Read NFC',
                style: TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save, size: 18, color: AppColors.white),
              label: const Text(
                'Save',
                style: TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
