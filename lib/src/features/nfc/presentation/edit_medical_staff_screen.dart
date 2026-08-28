// lib/src/features/nfc/presentation/edit_medical_staff_screen.dart

import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/form_widgets.dart';
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
  late final TextEditingController _practNameCtrl,
      _practDocNumberCtrl,
      _providerNameCtrl,
      _providerRepsCodeCtrl,
      _dateCtrl;
  late String _practDocType,
      _diagnosisType,
      _careModality,
      _dischargeDisposition;
  static const _docTypes = {
    'CC': 'Cédula de Ciudadanía',
    'CE': 'Cédula de Extranjería',
    'PA': 'Pasaporte',
  };
  static const _diagTypes = {
    '01': 'Impresión diagnóstica',
    '02': 'Confirmado nuevo',
    '03': 'Confirmado repetido',
  };
  static const _careModalities = {
    '01': 'Intramural',
    '02': 'Extramural - Móvil',
    '05': 'Extramural - Prehospitalaria',
  };
  static const _dischargeOpts = {
    '04': 'Alta médica',
    '01': 'Alta voluntaria',
    '03': 'Remitido',
  };

  @override
  void initState() {
    super.initState();
    final v = widget.patient.medicalHistory.isNotEmpty
        ? widget.patient.medicalHistory.last
        : null;
    _practNameCtrl = TextEditingController(
      text: v?.practitioner?.name ?? v?.physician ?? '',
    );
    _practDocNumberCtrl = TextEditingController(
      text: v?.practitioner?.documentNumber ?? '',
    );
    _practDocType = _docTypes.containsKey(v?.practitioner?.documentType)
        ? v!.practitioner!.documentType
        : 'CC';
    _providerNameCtrl = TextEditingController(
      text: v?.provider?.name ?? v?.location ?? '',
    );
    _providerRepsCodeCtrl = TextEditingController(
      text: v?.provider?.repsCode ?? '',
    );
    _dateCtrl = TextEditingController(text: v?.startDateTime ?? '');
    _diagnosisType = _diagTypes.containsKey(v?.diagnosisType)
        ? v!.diagnosisType
        : '01';
    _careModality = _careModalities.containsKey(v?.careModality)
        ? v!.careModality
        : '01';
    _dischargeDisposition = _dischargeOpts.containsKey(v?.dischargeDisposition)
        ? v!.dischargeDisposition!
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
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.editUpdate,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSectionHeader(
                          icon: Icons.person_outline,
                          title: s.practitioner,
                        ),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: s.name,
                          controller: _practNameCtrl,
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _dd(s.documentType, _practDocType, _docTypes, (v) {
                          if (v != null) setState(() => _practDocType = v);
                        }),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: s.documentNumber,
                          controller: _practDocNumberCtrl,
                          prefixIcon: Icons.badge,
                        ),
                        const SizedBox(height: 20),
                        FormSectionHeader(
                          icon: Icons.apartment_outlined,
                          title: s.healthcareProvider,
                        ),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: s.providerName,
                          controller: _providerNameCtrl,
                          prefixIcon: Icons.apartment,
                        ),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: s.repsCode,
                          controller: _providerRepsCodeCtrl,
                          prefixIcon: Icons.qr_code,
                        ),
                        const SizedBox(height: 20),
                        FormSectionHeader(
                          icon: Icons.event_available_outlined,
                          title: s.encounter,
                        ),
                        const SizedBox(height: 12),
                        LabeledTextField(
                          label: s.dateTime,
                          controller: _dateCtrl,
                          prefixIcon: Icons.calendar_today,
                        ),
                        const SizedBox(height: 12),
                        _dd(s.diagnosisType, _diagnosisType, _diagTypes, (v) {
                          if (v != null) setState(() => _diagnosisType = v);
                        }),
                        const SizedBox(height: 12),
                        _dd(s.careModality, _careModality, _careModalities, (
                          v,
                        ) {
                          if (v != null) setState(() => _careModality = v);
                        }),
                        const SizedBox(height: 12),
                        _dd(
                          s.dischargeDisposition,
                          _dischargeDisposition,
                          _dischargeOpts,
                          (v) {
                            if (v != null) {
                              setState(() => _dischargeDisposition = v);
                            }
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
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
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    s.back,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
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
                                  icon: const Icon(
                                    Icons.save,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    s.save,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _dd(
    String label,
    String val,
    Map<String, String> opts,
    ValueChanged<String?> cb,
  ) => Column(
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
            value: val,
            items: opts.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: cb,
          ),
        ),
      ),
    ],
  );
}
