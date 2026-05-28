// lib/src/features/nfc/presentation/register/steps/step4_background.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/patient_record.dart';
import '../register_nfc_screen.dart';

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
                      title: 'Condiciones crónicas',
                      subtitle: 'Agregue cada condición.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addChronicCondition,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.chronicConditions.isEmpty)
                _EmptyCard(msg: 'Sin condiciones crónicas. Toque "Agregar".')
              else
                Column(
                  children: List.generate(d.chronicConditions.length, (i) {
                    final it = d.chronicConditions[i];
                    return _ItemCard(
                      icon: Icons.favorite_border,
                      title: it.chronicDescription,
                      subtitle: 'Codificación automática por IA',
                      onRemove: () =>
                          setState(() => d.chronicConditions.removeAt(i)),
                    );
                  }),
                ),
              const SizedBox(height: 22),
              FormSectionHeader(
                icon: Icons.history_edu_outlined,
                title: 'Historial personal',
                subtitle: 'Antecedentes quirúrgicos, hospitalizaciones, etc.',
              ),
              const SizedBox(height: 12),
              _StyledTextArea(
                label: 'Historial personal',
                controller: _personal,
                hint: 'Ej. Cirugía de adenoides 2021...',
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              // Medications
              Row(
                children: [
                  Expanded(
                    child: FormSectionHeader(
                      icon: Icons.medication_outlined,
                      title: 'Medicamentos',
                      subtitle: 'Medicamentos actuales del paciente.',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMedication,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.medications.isEmpty)
                _EmptyCard(
                  msg: 'Sin medicamentos registrados. Toque "Agregar".',
                )
              else
                Column(
                  children: List.generate(d.medications.length, (i) {
                    final it = d.medications[i];
                    return _ItemCard(
                      icon: Icons.medication_outlined,
                      title: it.medicationName,
                      subtitle:
                          '${_medStatusLabel(it.status)}${it.dosage != null && it.dosage!.isNotEmpty ? ' · ${it.dosage}' : ''}',
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
                      title: 'Antecedentes familiares',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addFamilyHistory,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.familyHistory.isEmpty)
                _EmptyCard(msg: 'Sin antecedentes familiares. Toque "Agregar".')
              else
                Column(
                  children: List.generate(d.familyHistory.length, (i) {
                    final it = d.familyHistory[i];
                    return _ItemCard(
                      icon: Icons.diversity_3,
                      title: it.conditionDescription,
                      subtitle: _relLabel(it.relationship),
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
                      title: 'Alergias',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addAllergy,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (d.allergies.isEmpty)
                _EmptyCard(msg: 'Sin alergias registradas. Toque "Agregar".')
              else
                Column(
                  children: List.generate(d.allergies.length, (i) {
                    final it = d.allergies[i];
                    return _ItemCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.error,
                      title: it.allergen,
                      subtitle:
                          '${_catLabel(it.category)}${it.reaction != null && it.reaction!.isNotEmpty ? ' · ${it.reaction}' : ''}',
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
                    label: const Text(
                      'Atrás',
                      style: TextStyle(
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
                    label: const Text(
                      'Continuar',
                      style: TextStyle(
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

// ── Styled text area with voice dictation ─────────────────────────────────────
class _StyledTextArea extends StatefulWidget {
  const _StyledTextArea({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 3,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  State<_StyledTextArea> createState() => _StyledTextAreaState();
}

class _StyledTextAreaState extends State<_StyledTextArea> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _baseText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microfono no disponible en este dispositivo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save the existing text to accumulate
    _baseText = widget.controller.text;
    if (_baseText.isNotEmpty && !_baseText.endsWith(' ')) {
      _baseText += ' ';
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'es_CO',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
      onResult: (result) {
        final recognized = result.recognizedWords;
        setState(() {
          widget.controller.text = _baseText + recognized;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        });
        if (result.finalResult) {
          _baseText = widget.controller.text;
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──────────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── Stack: TextField + overlaid microphone button ─────────────────
        Stack(
          children: [
            TextField(
              controller: widget.controller,
              maxLines: widget.maxLines,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 14,
                  bottom: 44,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isListening
                        ? AppColors.primary
                        : const Color(0xFFB0B8C4),
                    width: _isListening ? 2 : 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _MicButton(
                isListening: _isListening,
                onTap: _toggleListening,
              ),
            ),
          ],
        ),
        // ── "Listening..." indicator ───────────────────────────────────────
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                _PulsingDot(),
                const SizedBox(width: 6),
                const Text(
                  'Escuchando... toque el microfono para detener',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Microphone button ────────────────────────────────────────────────────────
class _MicButton extends StatelessWidget {
  const _MicButton({required this.isListening, required this.onTap});
  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isListening
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
          size: 18,
          color: isListening ? AppColors.white : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Pulsing dot while listening ──────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

String _relLabel(String c) =>
    const {
      '01': 'Padres',
      '02': 'Hermanos',
      '03': 'Tíos',
      '04': 'Abuelos',
    }[c] ??
    c;
String _catLabel(String c) =>
    const {
      '01': 'Medicamento',
      '02': 'Alimento',
      '03': 'Sust. ambiente',
      '04': 'Sust. piel',
      '05': 'Picadura',
      '06': 'Otra',
    }[c] ??
    c;
String _medStatusLabel(String c) =>
    const {
      'active': 'Activo',
      'completed': 'Completado',
      'stopped': 'Suspendido',
      'unknown': 'Desconocido',
    }[c] ??
    c;

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
    final ok = _ctrl.text.trim().isNotEmpty;
    return _Sheet(
      title: 'Agregar condición crónica',
      canConfirm: ok,
      onConfirm: () {
        Navigator.of(
          context,
        ).pop(ChronicConditionItem(chronicDescription: _ctrl.text.trim()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledTextField(
            label: 'CONDICIÓN',
            controller: _ctrl,
            hint: 'Ej. Diabetes mellitus tipo 2',
            maxLines: 3,
            requiredField: true,
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
  static const _statuses = {
    'active': 'Activo',
    'completed': 'Completado',
    'stopped': 'Suspendido',
    'unknown': 'Desconocido',
  };
  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _name.text.trim().isNotEmpty;
    return _Sheet(
      title: 'Agregar medicamento',
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
            label: 'MEDICAMENTO',
            controller: _name,
            hint: 'Ej. Metformina 850mg',
            requiredField: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ChipSelector<String>(
            label: 'ESTADO',
            value: _status,
            options: _statuses,
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'POSOLOGÍA',
            controller: _dosage,
            hint: 'Ej. 1 tableta cada 12 horas',
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            label: 'NOTAS',
            controller: _notes,
            hint: 'Observaciones adicionales',
            maxLines: 2,
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
  static const _rels = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _ctrl.text.trim().isNotEmpty;
    return _Sheet(
      title: 'Agregar antecedente familiar',
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
            label: 'PARENTESCO',
            value: _rel,
            options: _rels,
            onChanged: (v) => setState(() => _rel = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'CONDICIÓN',
            controller: _ctrl,
            hint: 'Ej. Diabetes mellitus tipo 2',
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
  static const _cats = {
    '01': 'Medicamento',
    '02': 'Alimento',
    '03': 'Sust. ambiente',
    '04': 'Sust. piel',
    '05': 'Picadura',
    '06': 'Otra',
  };
  @override
  void dispose() {
    _allergen.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _allergen.text.trim().isNotEmpty;
    return _Sheet(
      title: 'Agregar alergia',
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
            label: 'CATEGORÍA',
            value: _cat,
            options: _cats,
            onChanged: (v) => setState(() => _cat = v),
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'ALÉRGENO',
            controller: _allergen,
            hint: 'Ej. Penicilina, Maní...',
            requiredField: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            label: 'REACCIÓN',
            controller: _reaction,
            hint: 'Ej. Erupción cutánea',
            maxLines: 2,
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
                      label: const Text(
                        'Agregar',
                        style: TextStyle(
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
