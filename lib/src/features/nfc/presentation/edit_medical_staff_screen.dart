import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditMedicalStaffScreen extends StatefulWidget {
  const EditMedicalStaffScreen({super.key, required this.patient});

  final PatientFullRecord patient;

  @override
  State<EditMedicalStaffScreen> createState() => _EditMedicalStaffScreenState();
}

class _EditMedicalStaffScreenState extends State<EditMedicalStaffScreen> {
  // Practitioner fields
  late final TextEditingController _practNameCtrl;
  late final TextEditingController _practDocNumberCtrl;
  late String _practDocType;

  // Provider fields
  late final TextEditingController _providerNameCtrl;
  late final TextEditingController _providerRepsCodeCtrl;

  // Encounter metadata
  late final TextEditingController _dateCtrl;
  late String _diagnosisType;
  late String _careModality;
  late String _dischargeDisposition;

  static const Map<String, String> _docTypes = {
    'CC': 'Cédula de Ciudadanía',
    'CE': 'Cédula de Extranjería',
    'PA': 'Pasaporte',
  };

  static const Map<String, String> _diagnosisTypes = {
    '01': 'Impresión diagnóstica',
    '02': 'Confirmado nuevo',
    '03': 'Confirmado repetido',
  };

  static const Map<String, String> _careModalities = {
    '01': 'Intramural',
    '02': 'Extramural - Móvil',
    '05': 'Extramural - Prehospitalaria',
  };

  static const Map<String, String> _dischargeOptions = {
    '04': 'Alta médica',
    '01': 'Alta voluntaria',
    '03': 'Remitido',
  };

  @override
  void initState() {
    super.initState();
    final latest = widget.patient.medicalHistory.isNotEmpty
        ? widget.patient.medicalHistory.last
        : null;
    final pract = latest?.practitioner;
    final prov = latest?.provider;

    _practNameCtrl = TextEditingController(
        text: pract?.name ?? latest?.physician ?? '');
    _practDocNumberCtrl =
        TextEditingController(text: pract?.documentNumber ?? '');
    _practDocType = _docTypes.containsKey(pract?.documentType)
        ? pract!.documentType
        : 'CC';

    _providerNameCtrl =
        TextEditingController(text: prov?.name ?? latest?.location ?? '');
    _providerRepsCodeCtrl =
        TextEditingController(text: prov?.repsCode ?? '');

    _dateCtrl = TextEditingController(
        text: latest?.startDateTime ?? '');
    _diagnosisType = _diagnosisTypes.containsKey(latest?.diagnosisType)
        ? latest!.diagnosisType
        : '01';
    _careModality = _careModalities.containsKey(latest?.careModality)
        ? latest!.careModality
        : '01';
    _dischargeDisposition =
        _dischargeOptions.containsKey(latest?.dischargeDisposition)
            ? latest!.dischargeDisposition!
            : '04';
  }

  @override
  void dispose() {
    _practNameCtrl.dispose();
    _practDocNumberCtrl.dispose();
    _providerNameCtrl.dispose();
    _providerRepsCodeCtrl.dispose();
    _dateCtrl.dispose();
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
                        _sectionTitle('Practitioner'),
                        const SizedBox(height: 12),
                        _textField('Name', _practNameCtrl,
                            icon: Icons.person),
                        const SizedBox(height: 12),
                        _mapDropdown('Document Type', _practDocType,
                            _docTypes, (v) {
                          if (v != null) setState(() => _practDocType = v);
                        }),
                        const SizedBox(height: 12),
                        _textField('Document Number', _practDocNumberCtrl,
                            icon: Icons.badge),
                        const SizedBox(height: 20),
                        _sectionTitle('Healthcare Provider'),
                        const SizedBox(height: 12),
                        _textField('Provider Name', _providerNameCtrl,
                            icon: Icons.apartment),
                        const SizedBox(height: 12),
                        _textField(
                            'REPS Code', _providerRepsCodeCtrl,
                            icon: Icons.qr_code),
                        const SizedBox(height: 20),
                        _sectionTitle('Encounter'),
                        const SizedBox(height: 12),
                        _textField('Date & Time (ISO 8601)', _dateCtrl,
                            icon: Icons.calendar_today),
                        const SizedBox(height: 12),
                        _mapDropdown('Diagnosis Type', _diagnosisType,
                            _diagnosisTypes, (v) {
                          if (v != null) {
                            setState(() => _diagnosisType = v);
                          }
                        }),
                        const SizedBox(height: 12),
                        _mapDropdown('Care Modality', _careModality,
                            _careModalities, (v) {
                          if (v != null) {
                            setState(() => _careModality = v);
                          }
                        }),
                        const SizedBox(height: 12),
                        _mapDropdown('Discharge Disposition',
                            _dischargeDisposition, _dischargeOptions,
                            (v) {
                          if (v != null) {
                            setState(() => _dischargeDisposition = v);
                          }
                        }),
                        const SizedBox(height: 30),
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

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary));

  Widget _textField(String label, TextEditingController ctrl,
      {IconData? icon}) {
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
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.secondary)
                : null,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _mapDropdown(String label, String value, Map<String, String> opts,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: opts.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
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
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.arrow_back_ios,
                  size: 14, color: AppColors.white),
              label: const Text('Back',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
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
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.save, size: 18, color: AppColors.white),
              label: const Text('Save',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}