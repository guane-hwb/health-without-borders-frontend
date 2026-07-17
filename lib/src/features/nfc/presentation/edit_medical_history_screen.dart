import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditMedicalHistoryScreen extends StatefulWidget {
  const EditMedicalHistoryScreen({super.key, required this.patient});
  final PatientFullRecord patient;
  @override
  State<EditMedicalHistoryScreen> createState() => _EditMedicalHistoryScreenState();
}

class _EditMedicalHistoryScreenState extends State<EditMedicalHistoryScreen> {
  late final TextEditingController _currentIllnessCtrl, _personalHistoryCtrl,
      _familyHistoryNotesCtrl, _generalExamCtrl,
      _systemsExamCtrl, _treatmentPlanCtrl;
  late final List<FamilyHistoryItem> _familyHistoryItems;
  late final List<ChronicConditionItem> _chronicConditionItems;
  late final List<MedicationStatementItem> _medicationItems;

  static const _relLabels = {'01': 'Padres', '02': 'Hermanos', '03': 'Tíos', '04': 'Abuelos'};

  @override
  void initState() {
    super.initState();
    final bg = widget.patient.backgroundHistory;
    final eval = widget.patient.medicalHistory.isNotEmpty ? widget.patient.medicalHistory.last.clinicalEvaluation : null;
    _currentIllnessCtrl = TextEditingController(text: eval?.historyOfCurrentIllness ?? '');
    _personalHistoryCtrl = TextEditingController(text: bg?.personalHistory ?? '');
    _familyHistoryNotesCtrl = TextEditingController(text: bg?.familyHistoryNotes ?? '');
    _generalExamCtrl = TextEditingController(text: eval?.generalPhysicalExamination ?? '');
    _systemsExamCtrl = TextEditingController(text: eval?.systemsExamination ?? '');
    _treatmentPlanCtrl = TextEditingController(text: eval?.treatmentPlanObservations ?? '');
    _familyHistoryItems = List.from(bg?.familyHistory ?? []);
    _chronicConditionItems = List.from(bg?.chronicConditions ?? []);
    _medicationItems = List.from(bg?.medications ?? []);
  }

  @override
  void dispose() { _currentIllnessCtrl.dispose(); _personalHistoryCtrl.dispose(); _familyHistoryNotesCtrl.dispose(); _generalExamCtrl.dispose(); _systemsExamCtrl.dispose(); _treatmentPlanCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(child: Stack(children: [
        Column(children: [
          SharedReadNfcHeader(title: s.editUpdate, onBack: () => Navigator.of(context).pop()),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sec(s.clinicalEvaluation),
              const SizedBox(height: 12),
              _ta(s.historyCurrentIllness, _currentIllnessCtrl),
              const SizedBox(height: 14),
              _ta(s.treatmentPlan, _treatmentPlanCtrl),
              const SizedBox(height: 20),
              _sec(s.backgroundHistory),
              const SizedBox(height: 12),
              // Chronic conditions (list)
              Row(children: [
                Text(s.chronicConditions, style: const TextStyle(fontSize: 13)),
                const Spacer(),
                SizedBox(height: 30, child: ElevatedButton.icon(onPressed: _addChronicCondition,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                  label: Text(s.add, style: const TextStyle(color: AppColors.white, fontSize: 12)))),
              ]),
              const SizedBox(height: 8),
              if (_chronicConditionItems.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text('Sin condiciones crónicas registradas.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)))
              else ..._chronicConditionItems.asMap().entries.map((e) => _ccCard(e.key, e.value)),
              const SizedBox(height: 14),
              // Medications (list)
              Row(children: [
                const Text('Medicamentos', style: TextStyle(fontSize: 13)),
                const Spacer(),
                SizedBox(height: 30, child: ElevatedButton.icon(onPressed: _addMedication,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                  label: Text(s.add, style: const TextStyle(color: AppColors.white, fontSize: 12)))),
              ]),
              const SizedBox(height: 8),
              if (_medicationItems.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text('Sin medicamentos registrados.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)))
              else ..._medicationItems.asMap().entries.map((e) => _medCard(e.key, e.value)),
              const SizedBox(height: 14),
              _ta(s.personalHistory, _personalHistoryCtrl),
              const SizedBox(height: 20),
              Row(children: [
                _sec(s.familyHistory), const Spacer(),
                SizedBox(height: 30, child: ElevatedButton.icon(onPressed: _addItem,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                  label: Text(s.add, style: const TextStyle(color: AppColors.white, fontSize: 12)))),
              ]),
              const SizedBox(height: 8),
              if (_familyHistoryItems.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(s.noFamilyHistory, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))
              else ..._familyHistoryItems.asMap().entries.map((e) => _fhCard(e.key, e.value, s)),
              const SizedBox(height: 14),
              _ta(s.familyHistoryNotes, _familyHistoryNotesCtrl),
              const SizedBox(height: 20),
              Row(children: [_sec(s.physicalExam), const SizedBox(width: 8), const Icon(Icons.medical_services_outlined, size: 20, color: AppColors.secondary)]),
              const SizedBox(height: 12),
              _ta(s.generalExam, _generalExamCtrl),
              const SizedBox(height: 14),
              _ta(s.systemsExam, _systemsExamCtrl),
              const SizedBox(height: 30),
              Row(children: [
                Expanded(child: SizedBox(height: 40, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF666666), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.white),
                  label: Text(s.back, style: const TextStyle(color: AppColors.white, fontSize: 13))))),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 40, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A396), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.save, size: 18, color: AppColors.white),
                  label: Text(s.save, style: const TextStyle(color: AppColors.white, fontSize: 13))))),
              ]),
            ]),
          )),
        ]),
        const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
      ])),
    );
  }

  Widget _sec(String t) => Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary));
  Widget _ta(String label, TextEditingController c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4),
    TextField(controller: c, maxLines: 3, style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(hintText: label, hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
        isDense: true, contentPadding: const EdgeInsets.all(12), filled: true, fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  ]);

  Widget _fhCard(int idx, FamilyHistoryItem item, AppStrings s) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.family_restroom, size: 20, color: AppColors.secondary), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.conditionDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text('${s.relationship}: ${_relLabels[item.relationship] ?? item.relationship}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (item.conditionCie10Code != null) Text('CIE-10: ${item.conditionCie10Code}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () => setState(() => _familyHistoryItems.removeAt(idx))),
    ]));

  void _addItem() {
    final condCtrl = TextEditingController();
    String rel = '01';
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.addFamilyHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 14),
          Text(s.condition, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4),
          TextField(controller: condCtrl, decoration: InputDecoration(hintText: 'e.g., Diabetes', isDense: true, contentPadding: const EdgeInsets.all(12))),
          const SizedBox(height: 14),
          Text(s.relationship, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: rel,
              items: _relLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) { if (v != null) ss(() => rel = v); }))),
          const SizedBox(height: 18),
          SizedBox(width: 120, height: 36, child: ElevatedButton.icon(onPressed: () {
            if (condCtrl.text.trim().isEmpty) return;
            setState(() => _familyHistoryItems.add(FamilyHistoryItem(conditionDescription: condCtrl.text.trim(), relationship: rel)));
            Navigator.of(ctx).pop();
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.add, size: 16, color: AppColors.white),
            label: Text(s.add, style: const TextStyle(color: AppColors.white, fontSize: 13)))),
        ]),
      )));
  }

  Widget _ccCard(int idx, ChronicConditionItem item) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.favorite_border, size: 20, color: AppColors.secondary), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.chronicDescription, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (item.chronicCie10Code != null) Text('CIE-10: ${item.chronicCie10Code}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () => setState(() => _chronicConditionItems.removeAt(idx))),
    ]));

  Widget _medCard(int idx, MedicationStatementItem item) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.medication_outlined, size: 20, color: AppColors.secondary), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.medicationName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text('${_medStatusLabel(item.status)}${item.dosage != null ? ' · ${item.dosage}' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () => setState(() => _medicationItems.removeAt(idx))),
    ]));

  static String _medStatusLabel(String c) => const {'active':'Activo','completed':'Completado','stopped':'Suspendido','unknown':'Desconocido'}[c] ?? c;

  void _addChronicCondition() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Agregar condición crónica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 14),
          const Text('Condición', style: TextStyle(fontSize: 13)), const SizedBox(height: 4),
          TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'ej: Diabetes mellitus tipo 2', isDense: true, contentPadding: EdgeInsets.all(12))),
          const SizedBox(height: 18),
          SizedBox(width: 120, height: 36, child: ElevatedButton.icon(onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            setState(() => _chronicConditionItems.add(ChronicConditionItem(chronicDescription: ctrl.text.trim())));
            Navigator.of(ctx).pop();
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.add, size: 16, color: AppColors.white),
            label: const Text('Agregar', style: TextStyle(color: AppColors.white, fontSize: 13)))),
        ]),
      ));
  }

  void _addMedication() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Agregar medicamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 14),
          const Text('Medicamento', style: TextStyle(fontSize: 13)), const SizedBox(height: 4),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'ej: Metformina 850mg', isDense: true, contentPadding: EdgeInsets.all(12))),
          const SizedBox(height: 14),
          const Text('Posología', style: TextStyle(fontSize: 13)), const SizedBox(height: 4),
          TextField(controller: dosageCtrl, decoration: const InputDecoration(hintText: 'ej: 1 tableta cada 12 horas', isDense: true, contentPadding: EdgeInsets.all(12))),
          const SizedBox(height: 18),
          SizedBox(width: 120, height: 36, child: ElevatedButton.icon(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            setState(() => _medicationItems.add(MedicationStatementItem(
              medicationName: nameCtrl.text.trim(),
              dosage: dosageCtrl.text.trim().isEmpty ? null : dosageCtrl.text.trim(),
            )));
            Navigator.of(ctx).pop();
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.add, size: 16, color: AppColors.white),
            label: const Text('Agregar', style: TextStyle(color: AppColors.white, fontSize: 13)))),
        ]),
      ));
  }
}