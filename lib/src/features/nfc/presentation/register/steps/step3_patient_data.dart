// lib/src/features/nfc/presentation/register/steps/step3_patient_data.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../register_nfc_screen.dart';
import '../../../../../core/i18n/app_strings.dart';

const _kEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
);
const _kFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.primary, width: 2),
);
const _kInputStyle = TextStyle(
  fontSize: 15,
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w500,
);
const _kHintStyle = TextStyle(fontSize: 14, color: AppColors.textSecondary);
const _kLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);
const _kReqStyle = TextStyle(
  color: AppColors.error,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class Step3PatientData extends StatefulWidget {
  const Step3PatientData({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onContinue,
  });

  final RegisterDraft draft;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<Step3PatientData> createState() => _Step3State();
}

class _Step3State extends State<Step3PatientData> {
  late final _docNum = TextEditingController(text: widget.draft.documentNumber);
  late final _firstName = TextEditingController(text: widget.draft.firstName);
  late final _secondName = TextEditingController(
    text: widget.draft.secondName ?? '',
  );
  late final _firstLast = TextEditingController(
    text: widget.draft.firstLastName,
  );
  late final _secondLast = TextEditingController(
    text: widget.draft.secondLastName ?? '',
  );
  late final _street = TextEditingController(text: widget.draft.street ?? '');
  late final _city = TextEditingController(text: widget.draft.addressCity);
  late final _stateCtrl = TextEditingController(
    text: widget.draft.addressState,
  );
  late final _ethnicComm = TextEditingController(
    text: widget.draft.ethnicCommunity ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.draft.weight != null
        ? (widget.draft.weight! % 1 == 0
              ? widget.draft.weight!.toInt().toString()
              : widget.draft.weight!.toString())
        : '',
  );
  late final _height = TextEditingController(
    text: widget.draft.height != null
        ? widget.draft.height!.toInt().toString()
        : '',
  );
  String? _err;

  bool get _hasEthnicity {
    final v = widget.draft.ethnicity;
    return v != null && v != '06';
  }

  @override
  void dispose() {
    _docNum.dispose();
    _firstName.dispose();
    _secondName.dispose();
    _firstLast.dispose();
    _secondLast.dispose();
    _street.dispose();
    _city.dispose();
    _stateCtrl.dispose();
    _ethnicComm.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _save() {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';
    final missing = <String>[];

    if (_docNum.text.trim().isEmpty) missing.add(s.documentNumberLabel);
    if (_firstName.text.trim().isEmpty) missing.add(s.firstNameLabel);
    if (_firstLast.text.trim().isEmpty) missing.add(s.lastNameLabel);
    if (widget.draft.dob == null) missing.add(s.dobLabel);
    if (_city.text.trim().isEmpty) missing.add(s.municipality);
    if (_stateCtrl.text.trim().isEmpty) missing.add(s.department);

    final String cleanDoc = _docNum.text.trim();
    if (cleanDoc.isNotEmpty) {
      final docRegex = RegExp(r'^[a-zA-Z0-9-]{5,20}$');
      if (!docRegex.hasMatch(cleanDoc)) {
        missing.add(
          isEs
              ? 'Número de documento inválido (Mínimo 5 caracteres alfanuméricos sin símbolos)'
              : 'Invalid Document format',
        );
      }
    }

    if (missing.isNotEmpty) {
      final errPrefix = isEs ? 'Campos requeridos' : 'Required fields';
      setState(() => _err = '$errPrefix: ${missing.join(', ')}');
      return;
    }

    final d = widget.draft;
    d.documentNumber = _docNum.text.trim();
    d.firstName = _firstName.text.trim();
    d.secondName = _secondName.text.trim().isEmpty
        ? null
        : _secondName.text.trim();
    d.firstLastName = _firstLast.text.trim();
    d.secondLastName = _secondLast.text.trim().isEmpty
        ? null
        : _secondLast.text.trim();
    d.street = _street.text.trim().isEmpty ? null : _street.text.trim();
    d.addressCity = _city.text.trim();
    d.addressState = _stateCtrl.text.trim();
    d.ethnicCommunity = _ethnicComm.text.trim().isEmpty
        ? null
        : _ethnicComm.text.trim();

    d.weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    d.height = double.tryParse(_height.text.trim().replaceAll(',', '.'));

    d.bloodType = (d.bloodType == null || d.bloodType!.trim().isEmpty)
        ? 'O+'
        : d.bloodType;

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    // ── Local maps resolved dynamically with AppStrings keys ─────────────────
    final docTypes = {
      'RC': s.docTypeRC,
      'TI': s.docTypeTI,
      'CC': s.docTypeCC,
      'CE': s.docTypeCE,
      'PA': s.docTypePA,
      'PE': s.docTypePE,
      'PT': s.docTypePT,
      'SC': isEs ? 'Salvoconducto' : 'Safe-conduct',
      'MS': s.docTypeMS,
      'AS': d.biologicalSex == 'M'
          ? (isEs ? 'Adulto s/ID' : 'Adult w/o ID')
          : s.docTypeAS,
      'CN': isEs ? 'Cert. nacido vivo' : 'Live birth cert.',
      'DE': isEs ? 'Doc. extranjero' : 'Foreign ID',
    };

    final sex = {'F': s.sexFemale, 'M': s.sexMale, 'I': s.sexIndeterminate};

    final gender = {
      '01': s.sexMale,
      '02': s.sexFemale,
      '03': isEs ? 'Transgénero' : 'Transgender',
      '04': isEs ? 'No binario' : 'Non-binary',
      '99': isEs ? 'No reporta' : 'Not reported',
    };

    final nat = {
      'COL': isEs ? 'Colombiana' : 'Colombian',
      'VEN': isEs ? 'Venezolana' : 'Venezuelan',
      'ECU': isEs ? 'Ecuatoriana' : 'Ecuadorian',
      'PER': isEs ? 'Peruana' : 'Peruvian',
      'HTI': isEs ? 'Haitiana' : 'Haitian',
      'CUB': isEs ? 'Cubana' : 'Cuban',
    };

    final eth = {
      '06': isEs ? 'Ninguno' : 'None',
      '01': isEs ? 'Indígena' : 'Indigenous',
      '02': isEs ? 'ROM/Gitano' : 'Romani',
      '03': isEs ? 'Raizal' : 'Raizal',
      '04': isEs ? 'Palenquero' : 'Palenquero',
      '05': isEs ? 'Afrocolombiano' : 'Afro-Colombian',
    };

    final dis = {
      '00': isEs ? 'Ninguna' : 'None',
      '01': isEs ? 'Física' : 'Physical',
      '02': isEs ? 'Intelectual' : 'Intellectual',
      '03': isEs ? 'Auditiva' : 'Hearing',
      '04': isEs ? 'Visual' : 'Visual',
      '05': isEs ? 'Sordoceguera' : 'Deaf-blindness',
      '06': isEs ? 'Psicosocial' : 'Psychosocial',
      '07': isEs ? 'Múltiple' : 'Multiple',
    };

    final zones = {'01': s.zoneUrban, '02': s.zoneRural};

    // Constant options map references
    const blood = {
      'O+': 'O+',
      'O-': 'O-',
      'A+': 'A+',
      'A-': 'A-',
      'B+': 'B+',
      'B-': 'B-',
      'AB+': 'AB+',
      'AB-': 'AB-',
    };

    final noticeMsg = isEs
        ? 'Complete los datos del paciente. Los campos con * son obligatorios.'
        : 'Complete the patient data. Fields with * are required.';

    final optionalLabel = isEs ? 'Opcional' : 'Optional';
    final ethnicCommHint = isEs ? 'Nombre de la comunidad' : 'Community name';
    final ethnicCommHelper = isEs
        ? 'Opcional. Solo si pertenece a una comunidad específica.'
        : 'Optional. Only if belonging to a specific community.';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        noticeMsg,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_err != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _err!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ── Identification ─────────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionHeader(
                    icon: Icons.badge_outlined,
                    title: s.identification,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: _StyledDropdown<String>(
                          label: s.documentTypeLabel,
                          value: d.documentType,
                          items: docTypes,
                          required: true,
                          onChanged: (v) {
                            if (v != null) setState(() => d.documentType = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextField(
                          label: s.documentNumberLabel,
                          controller: _docNum,
                          hint: 'Ej. 1098765432',
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          label: s.firstNameLabel,
                          controller: _firstName,
                          hint: 'Ej. Carmen',
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextField(
                          label: isEs ? 'SEGUNDO NOMBRE' : 'SECOND NAME',
                          controller: _secondName,
                          hint: optionalLabel,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          label: s.lastNameLabel,
                          controller: _firstLast,
                          hint: 'Ej. Vargas',
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextField(
                          label: isEs ? 'SEGUNDO APELLIDO' : 'SECOND LAST NAME',
                          controller: _secondLast,
                          hint: optionalLabel,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Demographic Data ─────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionHeader(
                    icon: Icons.person_outline,
                    title: isEs ? 'Datos demográficos' : 'Demographic data',
                  ),
                  _StyledDateField(
                    label: s.dobLabel,
                    value: d.dob,
                    required: true,
                    onChanged: (v) => setState(() => d.dob = v),
                  ),
                  const SizedBox(height: 12),
                  _ChipSelector(
                    label: isEs ? 'SEXO BIOLÓGICO' : 'BIOLOGICAL SEX',
                    value: d.biologicalSex,
                    options: sex,
                    required: true,
                    onChanged: (v) => setState(() => d.biologicalSex = v),
                  ),
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: isEs ? 'IDENTIDAD DE GÉNERO' : 'GENDER IDENTITY',
                    value: d.genderIdentity ?? '99',
                    items: gender,
                    onChanged: (v) =>
                        setState(() => d.genderIdentity = v == '99' ? null : v),
                  ),
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: s.nationality,
                    value: d.nationalityCode,
                    items: nat,
                    required: true,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          d.nationalityCode = v;
                          d.nationalityName = nat[v];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: isEs ? 'ETNIA' : 'ETHNICITY',
                    value: d.ethnicity ?? '06',
                    items: eth,
                    onChanged: (v) =>
                        setState(() => d.ethnicity = v == '06' ? null : v),
                  ),
                  if (_hasEthnicity) ...[
                    const SizedBox(height: 12),
                    _StyledTextField(
                      label: isEs ? 'COMUNIDAD ÉTNICA' : 'ETHNIC COMMUNITY',
                      controller: _ethnicComm,
                      hint: ethnicCommHint,
                      helperText: ethnicCommHelper,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: isEs ? 'DISCAPACIDAD' : 'DISABILITY',
                    value: d.disabilityCategory ?? '00',
                    items: dis,
                    onChanged: (v) => setState(
                      () => d.disabilityCategory = v == '00' ? null : v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Blood type ─────────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionHeader(
                    icon: Icons.bloodtype_outlined,
                    title: s.bloodType,
                    subtitle: s.bloodTypeReadOnly,
                  ),
                  _ChipSelector(
                    label: '',
                    value: d.bloodType ?? 'O+',
                    options: blood,
                    onChanged: (v) => setState(() => d.bloodType = v),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Measurements (weight / height) ─────────────────────────
              _SectionCard(
                children: [
                  _SectionHeader(
                    icon: Icons.straighten,
                    title: isEs ? 'Medidas' : 'Measurements',
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          label: s.weightKg,
                          controller: _weight,
                          hint: 'Ej: 39.2',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextField(
                          label: s.heightCm,
                          controller: _height,
                          hint: 'Ej: 148',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Residence ─────────────────────────────────────────────────
              _SectionCard(
                children: [
                  _SectionHeader(icon: Icons.home_outlined, title: s.address),
                  _StyledTextField(
                    label: s.street,
                    controller: _street,
                    hint: s.streetHint,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          label: s.municipality,
                          controller: _city,
                          hint: s.cityHint,
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextField(
                          label: s.department,
                          controller: _stateCtrl,
                          hint: s.stateHint,
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ChipSelector(
                    label: s.zone,
                    value: d.zone ?? '01',
                    options: zones,
                    onChanged: (v) => setState(() => d.zone = v),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
        _NavButtons(onBack: widget.onBack, onContinue: _save),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? helperText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: _kLabelStyle),
          if (required) const Text(' *', style: _kReqStyle),
        ],
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: _kInputStyle,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _kHintStyle,
          filled: true,
          fillColor: AppColors.white,
          helperText: helperText,
          helperStyle: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: _kEnabledBorder,
          focusedBorder: _kFocusedBorder,
        ),
      ),
    ],
  );
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: _kLabelStyle),
          if (required) const Text(' *', style: _kReqStyle),
        ],
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        style: _kInputStyle,
        icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
        decoration: const InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: _kEnabledBorder,
          focusedBorder: _kFocusedBorder,
          border: _kEnabledBorder,
        ),
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

class _StyledDateField extends StatelessWidget {
  const _StyledDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;

  String get _display => value != null
      ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
      : '';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: _kLabelStyle),
          if (required) const Text(' *', style: _kReqStyle),
        ],
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _display.isEmpty ? 'YYYY-MM-DD' : _display,
                  style: _display.isEmpty ? _kHintStyle : _kInputStyle,
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Row(
          children: [
            Text(label, style: _kLabelStyle),
            if (required) const Text(' *', style: _kReqStyle),
          ],
        ),
        const SizedBox(height: 8),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.entries.map((e) {
          final selected = e.key == value;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFB0B8C4),
                  width: selected ? 2 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.onBack, required this.onContinue});
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
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
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
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
                onPressed: onContinue,
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
    );
  }
}
