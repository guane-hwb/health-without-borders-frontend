// lib/src/features/nfc/presentation/register/steps/step4_background.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/patient_record.dart';
import '../register_nfc_screen.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../../profile/shared/voice_text_area.dart';

class Step4Background extends StatefulWidget {
  const Step4Background({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onContinue,
  });
  final RegisterDraft draft;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  @override
  State<Step4Background> createState() => _Step4State();
}

class _Step4State extends State<Step4Background> {
  late final _personal = TextEditingController(
    text: widget.draft.personalHistory ?? '',
  );

  @override
  void dispose() {
    _personal.dispose();
    super.dispose();
  }

  void _save() {
    final d = widget.draft;
    d.personalHistory = _personal.text.trim().isEmpty
        ? null
        : _personal.text.trim();
    widget.onContinue();
  }

  Future<void> _addChronicCondition() async {
    final item = await showModalBottomSheet<ChronicConditionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddChronicConditionSheet(),
    );
    if (item != null) setState(() => widget.draft.chronicConditions.add(item));
  }

  Future<void> _addMedication() async {
    final item = await showModalBottomSheet<MedicationStatementItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMedicationSheet(),
    );
    if (item != null) setState(() => widget.draft.medications.add(item));
  }

  Future<void> _addFamilyHistory() async {
    final item = await showModalBottomSheet<FamilyHistoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFamilyHistorySheet(),
    );
    if (item != null) setState(() => widget.draft.familyHistory.add(item));
  }

  Future<void> _addAllergy() async {
    final item = await showModalBottomSheet<AllergyInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAllergySheet(),
    );
    if (item != null) setState(() => widget.draft.allergies.add(item));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              // Chronic conditions (list-based)
              Row(
                children: [
                  Expanded(
                    child: FormSectionHeader(
                      icon: Icons.favorite_border,
                      title: s.chronicConditions,
                      subtitle: isEs
                          ? 'Agregue cada condición.'
                          : 'Add each condition.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addChronicCondition,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(s.add),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.chronicConditions.isEmpty)
                _EmptyCard(
                  msg: isEs
                      ? 'Sin condiciones crónicas. Toque "Agregar".'
                      : 'No chronic conditions. Tap "Add".',
                )
              else
                Column(
                  children: List.generate(d.chronicConditions.length, (i) {
                    final it = d.chronicConditions[i];
                    return _ItemCard(
                      icon: Icons.favorite_border,
                      title: it.chronicDescription,
                      subtitle: '',
                      onRemove: () =>
                          setState(() => d.chronicConditions.removeAt(i)),
                    );
                  }),
                ),
              const SizedBox(height: 22),
              FormSectionHeader(
                icon: Icons.history_edu_outlined,
                title: s.personalHistory,
                subtitle: isEs
                    ? 'Antecedentes quirúrgicos, hospitalizaciones, etc.'
                    : 'Surgical history, hospitalizations, etc.',
              ),
              const SizedBox(height: 12),
              VoiceTextArea(
                label: s.personalHistory,
                controller: _personal,
                hint: isEs
                    ? 'Ej. Cirugía de adenoides 2021...'
                    : 'e.g. Adenoid surgery 2021...',
                maxLines: 3,
                onChanged: (_) {},
              ),
              const SizedBox(height: 22),
              // Medications
              Row(
                children: [
                  Expanded(
                    child: FormSectionHeader(
                      icon: Icons.medication_outlined,
                      title: s.medications,
                      subtitle: isEs
                          ? 'Medicamentos actuales del paciente.'
                          : "Patient's current medications.",
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMedication,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(s.add),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.medications.isEmpty)
                _EmptyCard(
                  msg: isEs
                      ? 'Sin medicamentos registrados. Toque "Agregar".'
                      : 'No medications registered. Tap "Add".',
                )
              else
                Column(
                  children: List.generate(d.medications.length, (i) {
                    final it = d.medications[i];
                    return _ItemCard(
                      icon: Icons.medication_outlined,
                      title: it.medicationName,
                      subtitle:
                          '${_medStatusLabel(context, it.status)}${it.dosage != null && it.dosage!.isNotEmpty ? ' · ${it.dosage}' : ''}',
                      onRemove: () => setState(() => d.medications.removeAt(i)),
                    );
                  }),
                ),
              const SizedBox(height: 22),
              // Family history
              Row(
                children: [
                  Expanded(
                    child: FormSectionHeader(
                      icon: Icons.diversity_3_outlined,
                      title: s.familyHistory,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addFamilyHistory,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(s.add),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.familyHistory.isEmpty)
                _EmptyCard(
                  msg: isEs
                      ? 'Sin antecedentes familiares. Toque "Agregar".'
                      : 'No family history entries yet. Tap "Add".',
                )
              else
                Column(
                  children: List.generate(d.familyHistory.length, (i) {
                    final it = d.familyHistory[i];
                    return _ItemCard(
                      icon: Icons.diversity_3,
                      title: it.conditionDescription,
                      subtitle: _relLabel(context, it.relationship),
                      onRemove: () =>
                          setState(() => d.familyHistory.removeAt(i)),
                    );
                  }),
                ),
              const SizedBox(height: 22),
              // Allergies
              Row(
                children: [
                  Expanded(
                    child: FormSectionHeader(
                      icon: Icons.warning_amber_rounded,
                      title: s.allergiesSheetTitle,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addAllergy,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(s.add),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.allergies.isEmpty)
                _EmptyCard(
                  msg: isEs
                      ? 'Sin alergias registradas. Toque "Agregar".'
                      : 'No allergies registered. Tap "Add".',
                )
              else
                Column(
                  children: List.generate(d.allergies.length, (i) {
                    final it = d.allergies[i];
                    return _ItemCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.error,
                      title: it.allergen,
                      subtitle:
                          '${_catLabel(context, it.category)}${it.reaction != null && it.reaction!.isNotEmpty ? ' · ${it.reaction}' : ''}',
                      onRemove: () => setState(() => d.allergies.removeAt(i)),
                    );
                  }),
                ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFB0B8C4),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      s.back,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.white,
                    ),
                    label: Text(
                      s.continueBtn,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers de internacionalización dinámica basados en el context ───────────

String _relLabel(BuildContext context, String c) {
  final s = AppStrings.of(context);
  return {
        '01': s.relParents,
        '02': s.relSiblings,
        '03': s.relUncles,
        '04': s.relGrandparents,
      }[c] ??
      c;
}

String _catLabel(BuildContext context, String c) {
  final s = AppStrings.of(context);
  return {
        '01': s.allergenMedication,
        '02': s.allergenFood,
        '03': s.allergenEnvironment,
        '04': s.allergenSkin,
        '05': s.allergenInsect,
        '06': s.allergenOther,
      }[c] ??
      c;
}

String _medStatusLabel(BuildContext context, String c) {
  final s = AppStrings.of(context);
  return {
        'active': s.medStatusActive,
        'completed': s.medStatusCompleted,
        'stopped': s.medStatusStopped,
        'unknown': s.medStatusUnknown,
      }[c] ??
      c;
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.msg});
  final String msg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE3E5EA)),
    ),
    child: Text(
      msg,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.iconColor = AppColors.primary,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: AppColors.error,
          ),
        ),
      ],
    ),
  );
}

// ── Sheets ───────────────────────────────────────────────────────────────────

class _AddChronicConditionSheet extends StatefulWidget {
  const _AddChronicConditionSheet();
  @override
  State<_AddChronicConditionSheet> createState() => _AddCCState();
}

class _AddCCState extends State<_AddChronicConditionSheet> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ok = _ctrl.text.trim().isNotEmpty;
    return _Sheet(
      title: s.addChronicConditionTitle,
      canConfirm: ok,
      onConfirm: () {
        Navigator.of(
          context,
        ).pop(ChronicConditionItem(chronicDescription: _ctrl.text.trim()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VoiceTextArea(
            label: s.condition.toUpperCase(),
            controller: _ctrl,
            hint: s.chronicConditionHint,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();
  @override
  State<_AddMedicationSheet> createState() => _AddMedState();
}

class _AddMedState extends State<_AddMedicationSheet> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _notes = TextEditingController();
  String _status = 'active';

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ok = _name.text.trim().isNotEmpty;

    final statuses = {
      'active': s.medStatusActive,
      'completed': s.medStatusCompleted,
      'stopped': s.medStatusStopped,
      'unknown': s.medStatusUnknown,
    };

    return _Sheet(
      title: s.addMedicationTitle,
      canConfirm: ok,
      onConfirm: () {
        Navigator.of(context).pop(
          MedicationStatementItem(
            medicationName: _name.text.trim(),
            status: _status,
            dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledTextField(
            label: s.medicationLabel.toUpperCase().replaceAll('*', '').trim(),
            controller: _name,
            hint: s.medicationHint,
            requiredField: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ChipSelector<String>(
            label: s.statusLabel.toUpperCase(),
            value: _status,
            options: statuses,
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: s.dosageLabel.toUpperCase(),
            controller: _dosage,
            hint: s.dosageHint,
          ),
          const SizedBox(height: 12),
          VoiceTextArea(
            label: s.notesLabel.toUpperCase(),
            controller: _notes,
            hint: s.notesHint,
            maxLines: 2,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _AddFamilyHistorySheet extends StatefulWidget {
  const _AddFamilyHistorySheet();
  @override
  State<_AddFamilyHistorySheet> createState() => _AddFHState();
}

class _AddFHState extends State<_AddFamilyHistorySheet> {
  final _ctrl = TextEditingController();
  String _rel = '01';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ok = _ctrl.text.trim().isNotEmpty;

    final rels = {
      '01': s.relParents,
      '02': s.relSiblings,
      '03': s.relUncles,
      '04': s.relGrandparents,
    };

    return _Sheet(
      title: s.addFamilyHistory,
      canConfirm: ok,
      onConfirm: () {
        Navigator.of(context).pop(
          FamilyHistoryItem(
            conditionDescription: _ctrl.text.trim(),
            relationship: _rel,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipSelector<String>(
            label: s.guardianRelationship.toUpperCase(),
            value: _rel,
            options: rels,
            onChanged: (v) => setState(() => _rel = v),
          ),
          const SizedBox(height: 14),
          VoiceTextArea(
            label: s.condition.toUpperCase(),
            controller: _ctrl,
            hint: s.chronicConditionHint,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _AddAllergySheet extends StatefulWidget {
  const _AddAllergySheet();
  @override
  State<_AddAllergySheet> createState() => _AddAlState();
}

class _AddAlState extends State<_AddAllergySheet> {
  final _allergen = TextEditingController();
  final _reaction = TextEditingController();
  String _cat = '01';

  @override
  void dispose() {
    _allergen.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ok = _allergen.text.trim().isNotEmpty;

    final cats = {
      '01': s.allergenMedication,
      '02': s.allergenFood,
      '03': s.allergenEnvironment,
      '04': s.allergenSkin,
      '05': s.allergenInsect,
      '06': s.allergenOther,
    };

    return _Sheet(
      title: s.addAllergyBtn,
      canConfirm: ok,
      onConfirm: () {
        Navigator.of(context).pop(
          AllergyInfo(
            category: _cat,
            allergen: _allergen.text.trim(),
            reaction: _reaction.text.trim().isEmpty
                ? null
                : _reaction.text.trim(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipSelector<String>(
            label: s.allergyCategoryLabel.toUpperCase(),
            value: _cat,
            options: cats,
            onChanged: (v) => setState(() => _cat = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: s.allergenLabel.toUpperCase(),
            controller: _allergen,
            hint: s.allergenHint,
            requiredField: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          VoiceTextArea(
            label: s.reactionLabel.toUpperCase().replaceAll(':', '').trim(),
            controller: _reaction,
            hint: s.reactionHint,
            maxLines: 2,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.child,
    required this.onConfirm,
    this.canConfirm = true,
  });

  final String title;
  final Widget child;
  final VoidCallback onConfirm;
  final bool canConfirm;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: child,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: canConfirm ? onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.disabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.white,
                      ),
                      label: Text(
                        s.add,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
