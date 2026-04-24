import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key, required this.patient});

  final PatientFullRecord patient;

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  // Immutable fields — displayed read-only
  late final String _fullName;
  late final String _dob;
  late final String _biologicalSex;
  late final String _bloodType;
  late final String _documentInfo;

  // Editable fields
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;

  late String _nationalityCode;

  static const Map<String, String> _sexLabels = {
    'M': 'Masculino',
    'F': 'Femenino',
    'I': 'Indeterminado',
  };

  static const Map<String, String> _nationalityCodes = {
    'COL': 'Colombia',
    'VEN': 'Venezuela',
    'ECU': 'Ecuador',
    'PER': 'Perú',
  };

  @override
  void initState() {
    super.initState();
    final info = widget.patient.patientInfo;

    // Immutable — backend protects these
    _fullName = info.fullName;
    _dob = info.dob;
    _biologicalSex = _sexLabels[info.biologicalSex] ?? info.biologicalSex;
    _bloodType = info.bloodType ?? 'N/A';
    _documentInfo =
        '${info.identification.documentType} ${info.identification.documentNumber}';

    // Editable
    _weightCtrl = TextEditingController(
      text: info.weight != null ? info.weight.toString() : '',
    );
    _heightCtrl = TextEditingController(
      text: info.height != null ? info.height.toString() : '',
    );
    _streetCtrl = TextEditingController(text: info.address.street ?? '');
    _cityCtrl = TextEditingController(text: info.address.city);
    _stateCtrl = TextEditingController(text: info.address.state);
    _nationalityCode = _nationalityCodes.containsKey(info.nationalityCode)
        ? info.nationalityCode
        : 'COL';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
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
                        _sectionTitle('Patient Information (read-only)'),
                        const SizedBox(height: 4),
                        const Text(
                          'Name, DOB, sex, blood type and document are protected by the backend.',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        _readOnlyField('Name', _fullName, Icons.person),
                        const SizedBox(height: 10),
                        _readOnlyField(
                            'Document', _documentInfo, Icons.badge),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: _readOnlyField(
                                    'DOB', _dob, Icons.calendar_today)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _readOnlyField(
                                    'Sex', _biologicalSex, Icons.wc)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _readOnlyField(
                            'Blood Type', _bloodType, Icons.bloodtype),
                        const SizedBox(height: 20),
                        _sectionTitle('Editable Information'),
                        const SizedBox(height: 12),
                        _dropdownField(
                          'Nationality',
                          _nationalityCode,
                          _nationalityCodes,
                          (String? v) {
                            if (v != null) {
                              setState(() => _nationalityCode = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _textField('Weight (Kg)', _weightCtrl,
                            icon: Icons.monitor_weight,
                            keyboard: TextInputType.number),
                        const SizedBox(height: 12),
                        _textField('Height (cm)', _heightCtrl,
                            icon: Icons.open_in_full,
                            keyboard: TextInputType.number),
                        const SizedBox(height: 20),
                        _sectionTitle('Address'),
                        const SizedBox(height: 12),
                        _textField('Street', _streetCtrl,
                            icon: Icons.location_on),
                        const SizedBox(height: 12),
                        _textField('City', _cityCtrl,
                            icon: Icons.location_city),
                        const SizedBox(height: 12),
                        _textField('State / Department', _stateCtrl,
                            icon: Icons.map),
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

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.disabled),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              const Icon(Icons.lock_outline,
                  size: 14, color: AppColors.disabled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboard,
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
    Map<String, String> options,
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
              items: options.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ))
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
                'Back',
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
              onPressed: () {
                // TODO: Build updated PatientFullRecord and pop with result
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon:
                  const Icon(Icons.save, size: 18, color: AppColors.white),
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