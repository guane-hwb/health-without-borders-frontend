// lib/src/features/nfc/presentation/register/steps/step4_background.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/patient_record.dart';
import '../register_nfc_screen.dart';

class Step4Background extends StatefulWidget {
  const Step4Background({super.key, required this.draft, required this.onBack, required this.onContinue});
  final RegisterDraft draft; final VoidCallback onBack; final VoidCallback onContinue;
  @override State<Step4Background> createState() => _Step4State();
}

class _Step4State extends State<Step4Background> {
  late final _chronic = TextEditingController(text: widget.draft.chronicConditions ?? '');
  late final _personal = TextEditingController(text: widget.draft.personalHistory ?? '');

  @override void dispose() { _chronic.dispose(); _personal.dispose(); super.dispose(); }

  void _save() {
    final d = widget.draft;
    d.chronicConditions = _chronic.text.trim().isEmpty ? null : _chronic.text.trim();
    d.personalHistory = _personal.text.trim().isEmpty ? null : _personal.text.trim();
    widget.onContinue();
  }

  Future<void> _addFamilyHistory() async {
    final item = await showModalBottomSheet<FamilyHistoryItem>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddFamilyHistorySheet());
    if (item != null) setState(() => widget.draft.familyHistory.add(item));
  }

  Future<void> _addAllergy() async {
    final item = await showModalBottomSheet<AllergyInfo>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddAllergySheet());
    if (item != null) setState(() => widget.draft.allergies.add(item));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), children: [
        FormSectionHeader(icon: Icons.favorite_border, title: 'Condiciones crónicas', subtitle: 'Texto libre. El backend codifica automáticamente.'),
        LabeledTextField(label: 'CONDICIONES CRÓNICAS', controller: _chronic, hint: 'Ej. Asma leve diagnosticada en 2022...', maxLines: 3),
        const SizedBox(height: 22),
        FormSectionHeader(icon: Icons.history_edu_outlined, title: 'Historial personal', subtitle: 'Antecedentes quirúrgicos, hospitalizaciones, etc.'),
        LabeledTextField(label: 'HISTORIAL PERSONAL', controller: _personal, hint: 'Ej. Cirugía de adenoides 2021...', maxLines: 3),
        const SizedBox(height: 22),
        // Family history
        Row(children: [
          Expanded(child: FormSectionHeader(icon: Icons.diversity_3_outlined, title: 'Antecedentes familiares')),
          TextButton.icon(onPressed: _addFamilyHistory, icon: const Icon(Icons.add, size: 16), label: const Text('Agregar'), style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
        ]),
        if (d.familyHistory.isEmpty) _EmptyCard(msg: 'Sin antecedentes familiares. Toque "Agregar".')
        else Column(children: List.generate(d.familyHistory.length, (i) {
          final it = d.familyHistory[i];
          return _ItemCard(icon: Icons.diversity_3, title: it.conditionDescription, subtitle: _relLabel(it.relationship), onRemove: () => setState(() => d.familyHistory.removeAt(i)));
        })),
        const SizedBox(height: 22),
        // Allergies
        Row(children: [
          Expanded(child: FormSectionHeader(icon: Icons.warning_amber_rounded, title: 'Alergias')),
          TextButton.icon(onPressed: _addAllergy, icon: const Icon(Icons.add, size: 16), label: const Text('Agregar'), style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
        ]),
        if (d.allergies.isEmpty) _EmptyCard(msg: 'Sin alergias registradas. Toque "Agregar".')
        else Column(children: List.generate(d.allergies.length, (i) {
          final it = d.allergies[i];
          return _ItemCard(icon: Icons.warning_amber_rounded, iconColor: AppColors.error, title: it.allergen,
            subtitle: '${_catLabel(it.category)}${it.reaction != null && it.reaction!.isNotEmpty ? ' · ${it.reaction}' : ''}',
            onRemove: () => setState(() => d.allergies.removeAt(i)));
        })),
      ])),
      Container(
        decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: Row(children: [
          Expanded(child: SizedBox(height: 46, child: OutlinedButton.icon(onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary), label: const Text('Atrás', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: SizedBox(height: 46, child: ElevatedButton.icon(onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white), label: const Text('Continuar', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600))))),
        ]),
      ),
    ]);
  }
}

String _relLabel(String c) => const {'01':'Padres','02':'Hermanos','03':'Tíos','04':'Abuelos'}[c] ?? c;
String _catLabel(String c) => const {'01':'Medicamento','02':'Alimento','03':'Sust. ambiente','04':'Sust. piel','05':'Picadura','06':'Otra'}[c] ?? c;

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.msg});
  final String msg;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE3E5EA))),
    child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)));
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.icon, required this.title, required this.subtitle, required this.onRemove, this.iconColor = AppColors.primary});
  final IconData icon; final Color iconColor; final String title; final String subtitle; final VoidCallback onRemove;
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE3E5EA))),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 18, color: iconColor)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error)),
    ]));
}

// ── Sheets ───────────────────────────────────────────────────────────────────

class _AddFamilyHistorySheet extends StatefulWidget {
  const _AddFamilyHistorySheet();
  @override State<_AddFamilyHistorySheet> createState() => _AddFHState();
}
class _AddFHState extends State<_AddFamilyHistorySheet> {
  final _ctrl = TextEditingController(); String _rel = '01';
  static const _rels = {'01':'Padres','02':'Hermanos','03':'Tíos','04':'Abuelos'};
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final ok = _ctrl.text.trim().isNotEmpty;
    return _Sheet(title: 'Agregar antecedente familiar', subtitle: 'El backend asigna el código CIE automáticamente.', canConfirm: ok, onConfirm: () {
      Navigator.of(context).pop(FamilyHistoryItem(conditionDescription: _ctrl.text.trim(), relationship: _rel));
    }, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ChipSelector<String>(label: 'PARENTESCO', value: _rel, options: _rels, onChanged: (v) => setState(() => _rel = v)),
      const SizedBox(height: 14),
      LabeledTextField(label: 'CONDICIÓN', controller: _ctrl, hint: 'Ej. Diabetes mellitus tipo 2', maxLines: 3, onChanged: (_) => setState(() {})),
    ]));
  }
}

class _AddAllergySheet extends StatefulWidget {
  const _AddAllergySheet();
  @override State<_AddAllergySheet> createState() => _AddAlState();
}
class _AddAlState extends State<_AddAllergySheet> {
  final _allergen = TextEditingController(); final _reaction = TextEditingController(); String _cat = '01';
  static const _cats = {'01':'Medicamento','02':'Alimento','03':'Sust. ambiente','04':'Sust. piel','05':'Picadura','06':'Otra'};
  @override void dispose() { _allergen.dispose(); _reaction.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final ok = _allergen.text.trim().isNotEmpty;
    return _Sheet(title: 'Agregar alergia', canConfirm: ok, onConfirm: () {
      Navigator.of(context).pop(AllergyInfo(category: _cat, allergen: _allergen.text.trim(), reaction: _reaction.text.trim().isEmpty ? null : _reaction.text.trim()));
    }, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ChipSelector<String>(label: 'CATEGORÍA', value: _cat, options: _cats, onChanged: (v) => setState(() => _cat = v)),
      const SizedBox(height: 14),
      LabeledTextField(label: 'ALÉRGENO', controller: _allergen, hint: 'Ej. Penicilina, Maní...', requiredField: true, onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      LabeledTextField(label: 'REACCIÓN', controller: _reaction, hint: 'Ej. Erupción cutánea', maxLines: 2),
    ]));
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, this.subtitle, required this.child, required this.onConfirm, this.canConfirm = true});
  final String title; final String? subtitle; final Widget child; final VoidCallback onConfirm; final bool canConfirm;
  @override Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(expand: false, initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 8), Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: AppColors.disabled, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ])),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary)),
            ])),
            const SizedBox(height: 4),
            Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), child: child)),
            SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: SizedBox(width: double.infinity, height: 46, child: ElevatedButton.icon(
                onPressed: canConfirm ? onConfirm : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.disabled, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                icon: const Icon(Icons.check, size: 18, color: AppColors.white), label: const Text('Agregar', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              )),
            )),
          ]),
        ),
      ),
    );
  }
}
