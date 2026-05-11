// lib/src/features/nfc/presentation/register/steps/step2_patient_data.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../register_nfc_screen.dart';

class Step3PatientData extends StatefulWidget {
  const Step3PatientData({super.key, required this.draft, required this.onBack, required this.onContinue});
  final RegisterDraft draft; final VoidCallback onBack; final VoidCallback onContinue;
  @override State<Step3PatientData> createState() => _Step2State();
}

class _Step2State extends State<Step3PatientData> {
  late final _docNum = TextEditingController(text: widget.draft.documentNumber);
  late final _firstName = TextEditingController(text: widget.draft.firstName);
  late final _secondName = TextEditingController(text: widget.draft.secondName ?? '');
  late final _firstLastName = TextEditingController(text: widget.draft.firstLastName);
  late final _secondLastName = TextEditingController(text: widget.draft.secondLastName ?? '');
  late final _street = TextEditingController(text: widget.draft.street ?? '');
  late final _city = TextEditingController(text: widget.draft.addressCity);
  late final _stateCtrl = TextEditingController(text: widget.draft.addressState);
  late final _ethnicComm = TextEditingController(text: widget.draft.ethnicCommunity ?? '');
  String? _err;

  static const _docTypes = {'TI':'Tarjeta de Identidad','CC':'Cédula de Ciudadanía','RC':'Registro Civil','CE':'Cédula de Extranjería','PA':'Pasaporte','PE':'Permiso Especial','PT':'PPT','SC':'Salvoconducto','MS':'Menor s/ID','AS':'Adulto s/ID','CN':'Cert. nacido vivo','DE':'Doc. extranjero'};
  static const _sex = {'F':'Femenino','M':'Masculino','I':'Indeterminado'};
  static const _gender = {'01':'Masculino','02':'Femenino','03':'Transgénero','04':'No binario','99':'No reporta'};
  static const _nat = {'COL':'Colombiana','VEN':'Venezolana','ECU':'Ecuatoriana','PER':'Peruana','HTI':'Haitiana','CUB':'Cubana'};
  static const _eth = {'06':'Ninguno','01':'Indígena','02':'ROM/Gitano','03':'Raizal','04':'Palenquero','05':'Afrocolombiano'};
  static const _dis = {'00':'Ninguna','01':'Física','02':'Intelectual','03':'Auditiva','04':'Visual','05':'Sordoceguera','06':'Psicosocial','07':'Múltiple'};
  static const _blood = {'O+':'O+','O-':'O-','A+':'A+','A-':'A-','B+':'B+','B-':'B-','AB+':'AB+','AB-':'AB-'};
  static const _zones = {'U':'Urbana','R':'Rural'};

  @override void dispose() { _docNum.dispose(); _firstName.dispose(); _secondName.dispose(); _firstLastName.dispose(); _secondLastName.dispose(); _street.dispose(); _city.dispose(); _stateCtrl.dispose(); _ethnicComm.dispose(); super.dispose(); }

  void _save() {
    final missing = <String>[];
    if (_docNum.text.trim().isEmpty) missing.add('Número de documento');
    if (_firstName.text.trim().isEmpty) missing.add('Primer nombre');
    if (_firstLastName.text.trim().isEmpty) missing.add('Primer apellido');
    if (widget.draft.dob == null) missing.add('Fecha de nacimiento');
    if (_city.text.trim().isEmpty) missing.add('Municipio');
    if (_stateCtrl.text.trim().isEmpty) missing.add('Departamento');
    if (missing.isNotEmpty) { setState(() => _err = 'Campos requeridos: ${missing.join(', ')}'); return; }

    final d = widget.draft;
    d.documentNumber = _docNum.text.trim();
    d.firstName = _firstName.text.trim();
    d.secondName = _secondName.text.trim().isEmpty ? null : _secondName.text.trim();
    d.firstLastName = _firstLastName.text.trim();
    d.secondLastName = _secondLastName.text.trim().isEmpty ? null : _secondLastName.text.trim();
    d.street = _street.text.trim().isEmpty ? null : _street.text.trim();
    d.addressCity = _city.text.trim();
    d.addressState = _stateCtrl.text.trim();
    d.ethnicCommunity = _ethnicComm.text.trim().isEmpty ? null : _ethnicComm.text.trim();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), children: [
        // ── Identification ──
        FormSectionHeader(icon: Icons.badge_outlined, title: 'Identificación'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 125, child: LabeledDropdown<String>(label: 'TIPO DOC.', value: d.documentType, items: _docTypes, onChanged: (v) { if (v != null) setState(() => d.documentType = v); }, requiredField: true)),
          const SizedBox(width: 10),
          Expanded(child: LabeledTextField(label: 'NÚMERO DE DOCUMENTO', controller: _docNum, hint: 'Ej. 1098765432', requiredField: true)),
        ]),
        const SizedBox(height: 14),
        LabeledTextField(label: 'PRIMER NOMBRE', controller: _firstName, requiredField: true),
        const SizedBox(height: 12),
        LabeledTextField(label: 'SEGUNDO NOMBRE', controller: _secondName),
        const SizedBox(height: 12),
        LabeledTextField(label: 'PRIMER APELLIDO', controller: _firstLastName, requiredField: true),
        const SizedBox(height: 12),
        LabeledTextField(label: 'SEGUNDO APELLIDO', controller: _secondLastName),

        const SizedBox(height: 22),
        // ── Demographics ──
        FormSectionHeader(icon: Icons.person_outline, title: 'Datos demográficos'),
        LabeledDateField(label: 'FECHA DE NACIMIENTO', value: d.dob, onChanged: (v) => setState(() => d.dob = v), requiredField: true),
        const SizedBox(height: 12),
        ChipSelector<String>(label: 'SEXO BIOLÓGICO', value: d.biologicalSex, options: _sex, onChanged: (v) => setState(() => d.biologicalSex = v), requiredField: true),
        const SizedBox(height: 12),
        LabeledDropdown<String>(label: 'IDENTIDAD DE GÉNERO', value: d.genderIdentity ?? '99', items: _gender, onChanged: (v) => setState(() => d.genderIdentity = v == '99' ? null : v)),
        const SizedBox(height: 12),
        LabeledDropdown<String>(label: 'NACIONALIDAD', value: d.nationalityCode, items: _nat, onChanged: (v) { if (v != null) setState(() { d.nationalityCode = v; d.nationalityName = _nat[v]; }); }, requiredField: true),
        const SizedBox(height: 12),
        LabeledDropdown<String>(label: 'ETNIA', value: d.ethnicity ?? '06', items: _eth, onChanged: (v) => setState(() => d.ethnicity = v == '06' ? null : v)),
        const SizedBox(height: 12),
        LabeledTextField(label: 'COMUNIDAD ÉTNICA', controller: _ethnicComm, helper: 'Opcional. Solo si pertenece a una comunidad específica.'),
        const SizedBox(height: 12),
        LabeledDropdown<String>(label: 'DISCAPACIDAD', value: d.disabilityCategory ?? '00', items: _dis, onChanged: (v) => setState(() => d.disabilityCategory = v == '00' ? null : v)),

        const SizedBox(height: 22),
        // ── Blood type ──
        FormSectionHeader(icon: Icons.bloodtype_outlined, title: 'Tipo de sangre', subtitle: 'Dato biológico permanente'),
        ChipSelector<String>(label: 'TIPO DE SANGRE', value: d.bloodType ?? 'O+', options: _blood, onChanged: (v) => setState(() => d.bloodType = v), showLabel: false),

        const SizedBox(height: 22),
        // ── Residence ──
        FormSectionHeader(icon: Icons.home_outlined, title: 'Residencia'),
        LabeledTextField(label: 'DIRECCIÓN', controller: _street, hint: 'Ej. Cra. 18 #27-43'),
        const SizedBox(height: 12),
        LabeledTextField(label: 'MUNICIPIO', controller: _city, hint: 'Ej. Riohacha', requiredField: true),
        const SizedBox(height: 12),
        LabeledTextField(label: 'DEPARTAMENTO', controller: _stateCtrl, hint: 'Ej. La Guajira', requiredField: true),
        const SizedBox(height: 12),
        ChipSelector<String>(label: 'ZONA', value: d.zone ?? 'U', options: _zones, onChanged: (v) => setState(() => d.zone = v)),

        if (_err != null) ...[const SizedBox(height: 16), Container(
          padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
          child: Row(children: [const Icon(Icons.error_outline, color: AppColors.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(_err!, style: const TextStyle(fontSize: 12, color: AppColors.error)))]),
        )],
      ])),
      _StepFooter(onBack: widget.onBack, onNext: _save),
    ]);
  }
}

class _StepFooter extends StatelessWidget {
  const _StepFooter({required this.onBack, required this.onNext});
  final VoidCallback onBack; final VoidCallback onNext;
  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      child: Row(children: [
        Expanded(child: SizedBox(height: 46, child: OutlinedButton.icon(
          onPressed: onBack, style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary), label: const Text('Atrás', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: SizedBox(height: 46, child: ElevatedButton.icon(
          onPressed: onNext, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white), label: const Text('Continuar', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ))),
      ]),
    );
  }
}
