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
  late final TextEditingController _chronicConditionsCtrl;
  late final TextEditingController _familyHistoryNotesCtrl;
  late final TextEditingController _generalExamCtrl;
  late final TextEditingController _systemsExamCtrl;
  late final TextEditingController _treatmentPlanCtrl;

  // Family history as structured items
  late final List<FamilyHistoryItem> _familyHistoryItems;

  static const Map<String, String> _relationshipLabels = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };

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
    _chronicConditionsCtrl = TextEditingController(
      text: bg?.chronicConditions ?? '',
    );
    _familyHistoryNotesCtrl = TextEditingController(
      text: bg?.familyHistoryNotes ?? '',
    );
    _generalExamCtrl = TextEditingController(
      text: latestEval?.generalPhysicalExamination ?? '',
    );
    _systemsExamCtrl = TextEditingController(
      text: latestEval?.systemsExamination ?? '',
    );
    _treatmentPlanCtrl = TextEditingController(
      text: latestEval?.treatmentPlanObservations ?? '',
    );

    _familyHistoryItems = List<FamilyHistoryItem>.from(
      bg?.familyHistory ?? <FamilyHistoryItem>[],
    );
  }

  @override
  void dispose() {
    _currentIllnessCtrl.dispose();
    _personalHistoryCtrl.dispose();
    _chronicConditionsCtrl.dispose();
    _familyHistoryNotesCtrl.dispose();
    _generalExamCtrl.dispose();
    _systemsExamCtrl.dispose();
    _treatmentPlanCtrl.dispose();
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
                        _sectionTitle('Clinical Evaluation'),
                        const SizedBox(height: 12),
                        _textArea('History of current illness',
                            _currentIllnessCtrl),
                        const SizedBox(height: 14),
                        _textArea('Treatment plan / observations',
                            _treatmentPlanCtrl),
                        const SizedBox(height: 20),
                        _sectionTitle('Background History'),
                        const SizedBox(height: 12),
                        _textArea('Chronic conditions', _chronicConditionsCtrl),
                        const SizedBox(height: 14),
                        _textArea('Personal history', _personalHistoryCtrl),
                        const SizedBox(height: 20),

                        // --- Structured family history ---
                        Row(
                          children: [
                            _sectionTitle('Family History'),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              child: ElevatedButton.icon(
                                onPressed: _addFamilyHistoryItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                icon: const Icon(Icons.add,
                                    size: 16, color: AppColors.white),
                                label: const Text('Add',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_familyHistoryItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No family history entries yet.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ..._familyHistoryItems.asMap().entries.map(
                                (entry) => _familyHistoryCard(
                                    entry.key, entry.value),
                              ),
                        const SizedBox(height: 14),
                        _textArea(
                            'Family history notes (free text)',
                            _familyHistoryNotesCtrl),

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
                        _textArea('General physical examination',
                            _generalExamCtrl),
                        const SizedBox(height: 14),
                        _textArea('Systems examination', _systemsExamCtrl),
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

  Widget _familyHistoryCard(int index, FamilyHistoryItem item) {
    final relLabel =
        _relationshipLabels[item.relationship] ?? item.relationship;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom,
              size: 20, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.conditionDescription,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Parentesco: $relLabel',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (item.conditionCie10Code != null)
                  Text(
                    'CIE-10: ${item.conditionCie10Code}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.error),
            onPressed: () {
              setState(() => _familyHistoryItems.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  void _addFamilyHistoryItem() {
    final condCtrl = TextEditingController();
    String relationship = '01';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Family History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Condition', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: condCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g., Diabetes, Hipertensión',
                      hintStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Relationship', style: TextStyle(fontSize: 13)),
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
                        value: relationship,
                        items: _relationshipLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => relationship = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 120,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (condCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _familyHistoryItems.add(FamilyHistoryItem(
                            conditionDescription: condCtrl.text.trim(),
                            relationship: relationship,
                          ));
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add,
                          size: 16, color: AppColors.white),
                      label: const Text('Add',
                          style: TextStyle(
                              color: AppColors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              onPressed: () {
                // TODO: Return updated data via Navigator.pop(result)
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
              label: const Text('Save',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}