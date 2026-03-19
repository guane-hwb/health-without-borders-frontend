import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'shared_read_nfc_header.dart';

class EditGuardianScreen extends StatefulWidget {
  const EditGuardianScreen({super.key});

  @override
  State<EditGuardianScreen> createState() => _EditGuardianScreenState();
}

class _EditGuardianScreenState extends State<EditGuardianScreen> {
  final TextEditingController _nameCtrl =
      TextEditingController(text: 'Ana Torres');
  final TextEditingController _docNumberCtrl =
      TextEditingController(text: '10665987416');
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();

  String _docType = 'Citizenship card';
  String _country = 'Colombia';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _docNumberCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
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
                        const Text(
                          'Companion / Guardian Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _textField('Name', _nameCtrl, icon: Icons.person),
                        const SizedBox(height: 14),
                        _dropdownField(
                          'Document type',
                          _docType,
                          ['Citizenship card', 'Passport', 'Other'],
                          (String? v) {
                            if (v != null) setState(() => _docType = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        _textField('Document number', _docNumberCtrl,
                            icon: Icons.badge),
                        const SizedBox(height: 14),
                        _dropdownField(
                          'Country',
                          _country,
                          ['Colombia', 'Venezuela', 'Other'],
                          (String? v) {
                            if (v != null) setState(() => _country = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        _textField('Address', _addressCtrl,
                            icon: Icons.location_on),
                        const SizedBox(height: 14),
                        _textField('Contact', _contactCtrl, icon: Icons.call),
                        const SizedBox(height: 40),
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
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.secondary)
                : null,
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
