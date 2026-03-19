import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditMedicalHistoryScreen extends StatefulWidget {
  const EditMedicalHistoryScreen({super.key, required this.patient});

  final PatientFullRecord patient;

  @override
  State<EditMedicalHistoryScreen> createState() =>
      _EditMedicalHistoryScreenState();
}

class _EditMedicalHistoryScreenState extends State<EditMedicalHistoryScreen> {
  late final TextEditingController _currentIllnessCtrl;
  late final TextEditingController _personalHistoryCtrl;
  late final TextEditingController _familyHistoryCtrl;
  late final TextEditingController _generalExamCtrl;
  late final TextEditingController _systemsExamCtrl;

  @override
  void initState() {
    super.initState();
    final bg = widget.patient.backgroundHistory;
    final latestEval = widget.patient.medicalHistory.isNotEmpty
        ? widget.patient.medicalHistory.last.clinicalEvaluation
        : null;
    _currentIllnessCtrl = TextEditingController(
      text: latestEval?.historyOfCurrentIllness ?? '',
    );
    _personalHistoryCtrl = TextEditingController(
      text: bg?.personalHistory ?? '',
    );
    _familyHistoryCtrl = TextEditingController(
      text: bg?.familyHistory ?? '',
    );
    _generalExamCtrl = TextEditingController(
      text: latestEval?.generalPhysicalExamination ?? '',
    );
    _systemsExamCtrl = TextEditingController(
      text: latestEval?.systemsExamination ?? '',
    );
  }

  @override
  void dispose() {
    _currentIllnessCtrl.dispose();
    _personalHistoryCtrl.dispose();
    _familyHistoryCtrl.dispose();
    _generalExamCtrl.dispose();
    _systemsExamCtrl.dispose();
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
                        _sectionTitle('General'),
                        const SizedBox(height: 12),
                        _textArea(
                          'History of current illness',
                          _currentIllnessCtrl,
                        ),
                        const SizedBox(height: 14),
                        _textArea('Personal History', _personalHistoryCtrl),
                        const SizedBox(height: 14),
                        _textArea('Family History', _familyHistoryCtrl),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _sectionTitle('Physical Examination'),
                            const SizedBox(width: 8),
                            const Icon(Icons.medical_services_outlined,
                                size: 20, color: AppColors.secondary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _textArea(
                          'General Physical Examination',
                          _generalExamCtrl,
                        ),
                        const SizedBox(height: 14),
                        _textArea('Systems Examination', _systemsExamCtrl),
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

  Widget _textArea(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 100,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
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
