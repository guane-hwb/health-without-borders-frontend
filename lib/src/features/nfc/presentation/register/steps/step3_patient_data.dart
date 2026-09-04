// lib/src/features/nfc/presentation/register/steps/step3_patient_data.dart

import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../core/validation/identity_validators.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/country_display.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/register_draft.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../widgets/nfc_uid_field.dart';

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

const List<String> kEthnicityCodes = <String>[
  '99',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
];
const List<String> kNoEthnicityCodes = <String>['99'];
const List<String> kDisabilityCodes = <String>[
  '08',
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
];
const List<String> kNoDisabilityCodes = <String>['08'];

const List<String> kGenderIdentityCodes = <String>[
  '01',
  '02',
  '03',
  '04',
  '05',
];
const List<String> kNoGenderIdentityCodes = <String>['05'];

bool patientHasEthnicity(String? ethnicity) =>
    ethnicity != null && !kNoEthnicityCodes.contains(ethnicity);

RegisterDraft applyDemographicSentinelDefaults(RegisterDraft d) {
  d.ethnicity ??= kNoEthnicityCodes.first;
  d.disabilityCategory ??= kNoDisabilityCodes.first;
  d.genderIdentity ??= kNoGenderIdentityCodes.first;
  return d;
}

Widget _buildLabel(String labelText, bool isRequired) {
  final cleanText = labelText.replaceAll('*', '').trim();
  return Text.rich(
    TextSpan(
      text: cleanText,
      style: _kLabelStyle,
      children: [if (isRequired) const TextSpan(text: ' *', style: _kReqStyle)],
    ),
    overflow: TextOverflow.ellipsis,
  );
}

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
  late final _patientUid = TextEditingController(
    text: widget.draft.deviceUid ?? '',
  );
  bool _scanningUid = false;
  String? _err;
  bool _isDocInvalid = false;

  bool get _hasEthnicity => patientHasEthnicity(widget.draft.ethnicity);

  @override
  void initState() {
    super.initState();
    _docNum.addListener(_validateDocInRealTime);
  }

  @override
  void dispose() {
    _docNum.removeListener(_validateDocInRealTime);
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
    _patientUid.dispose();
    super.dispose();
  }

  void _validateDocInRealTime() {
    final text = _docNum.text.trim();
    if (text.isEmpty) {
      if (_isDocInvalid) setState(() => _isDocInvalid = false);
      return;
    }
    final invalid = validateDocumentNumber(text) != null;
    if (invalid != _isDocInvalid) {
      setState(() => _isDocInvalid = invalid);
    }
  }

  Future<void> _scanPatientNfc() async {
    final s = AppStrings.of(context);
    setState(() => _scanningUid = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() {
          _patientUid.text = uid;
          widget.draft.deviceUid = uid;
          _scanningUid = false;
        });
      }
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() {
          _scanningUid = false;
          _err = s.nfcNotAvailable;
        });
      }
    } on NfcSessionException catch (e) {
      if (mounted) {
        setState(() {
          _scanningUid = false;
          _err = e.message;
        });
      }
    }
  }

  void _save() {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final missing = <String>[];

    if (_patientUid.text.trim().isEmpty) {
      missing.add(s.patientNfcDevice);
    }
    if (_docNum.text.trim().isEmpty) missing.add(s.documentNumberLabel);
    if (_firstName.text.trim().isEmpty) missing.add(s.firstNameLabel);
    if (_firstLast.text.trim().isEmpty) missing.add(s.lastNameLabel);
    if (widget.draft.dob == null) missing.add(s.dobLabel);
    if (_city.text.trim().isEmpty) missing.add(s.municipality);
    if (_stateCtrl.text.trim().isEmpty) missing.add(s.department);

    if (validateDocumentNumber(_docNum.text) != null) {
      setState(() => _isDocInvalid = true);
      missing.add(
        isEs
            ? 'Número de documento inválido (5 a 20 caracteres, sin símbolos)'
            : 'Invalid document number (5 to 20 characters, no symbols)',
      );
    }

    final natCode = widget.draft.nationalityCode;
    if (!kSupportedNationalityCodes.contains(natCode)) {
      missing.add(
        isEs
            ? 'Nacionalidad no válida (código ISO 3166-1 requerido)'
            : 'Invalid nationality (ISO 3166-1 code required)',
      );
    }

    if (missing.isNotEmpty) {
      final errPrefix = isEs ? 'Campos requeridos' : 'Required fields';
      setState(() => _err = '$errPrefix: ${missing.join(', ')}');
      return;
    }

    final d = widget.draft;
    d.deviceUid = _patientUid.text.trim().isEmpty
        ? null
        : _patientUid.text.trim();
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
    d.bloodType = (d.bloodType ?? '').trim().isEmpty ? null : d.bloodType;

    d.nationalityName = countryDisplay(d.nationalityCode).name(isEs: isEs);

    d.weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    d.height = double.tryParse(_height.text.trim().replaceAll(',', '.'));

    applyDemographicSentinelDefaults(d);

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final docTypes = <String, String>{
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

    final sex = <String, String>{
      'F': s.sexFemale,
      'M': s.sexMale,
      'I': s.sexIndeterminate,
    };

    final gender = <String, String>{
      '01': s.sexMale,
      '02': s.sexFemale,
      '03': isEs ? 'Transgénero' : 'Transgender',
      '04': isEs ? 'No binario' : 'Non-binary',
      '05': isEs ? 'No declara' : 'Does not declare',
    };
    assert(
      gender.keys.toSet().containsAll(kGenderIdentityCodes) &&
          kGenderIdentityCodes.toSet().containsAll(gender.keys),
      'kGenderIdentityCodes debe reflejar exactamente las llaves del mapa gender',
    );

    final nat = <String, String>{
      for (final code in kSupportedNationalityCodes)
        code: countryDisplay(code).name(isEs: isEs),
    };

    final ethLabels = <String, String>{
      '99': isEs ? 'Ninguno' : 'None',
      '1': isEs ? 'Indígena' : 'Indigenous',
      '2': isEs ? 'ROM/Gitano' : 'Romani',
      '3': isEs ? 'Raizal' : 'Raizal',
      '4': isEs ? 'Palenquero' : 'Palenquero',
      '5': isEs ? 'Afrocolombiano' : 'Afro-Colombian',
      '6': isEs ? 'Otras etnias' : 'Other ethnicities',
    };
    final eth = <String, String>{
      for (final code in kEthnicityCodes) code: ethLabels[code]!,
    };

    final disLabels = <String, String>{
      '08': isEs ? 'Ninguna' : 'None',
      '01': isEs ? 'Física' : 'Physical',
      '02': isEs ? 'Visual' : 'Visual',
      '03': isEs ? 'Auditiva' : 'Hearing',
      '04': isEs ? 'Intelectual' : 'Intellectual',
      '05': isEs ? 'Psicosocial' : 'Psychosocial',
      '06': isEs ? 'Sordoceguera' : 'Deaf-blindness',
      '07': isEs ? 'Múltiple' : 'Multiple',
    };
    final dis = <String, String>{
      for (final code in kDisabilityCodes) code: disLabels[code]!,
    };

    final zones = <String, String>{'01': s.zoneUrban, '02': s.zoneRural};

    const blood = <String, String>{
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

              _SectionCard(
                children: [
                  _SectionHeader(icon: Icons.nfc, title: s.patientNfcDevice),
                  NfcUidField(
                    controller: _patientUid,
                    scanning: _scanningUid,
                    onScan: _scanPatientNfc,
                    onChanged: () => setState(
                      () => widget.draft.deviceUid =
                          _patientUid.text.trim().isEmpty
                          ? null
                          : _patientUid.text.trim(),
                    ),
                    hintText: s.manualPatientUidHint,
                    prefixIcon: Icons.watch_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                children: [
                  _SectionHeader(
                    icon: Icons.badge_outlined,
                    title: s.identification,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabeledTextField(
                              label: s.documentNumberLabel,
                              controller: _docNum,
                              hint: 'Ej. 1098765432',
                              requiredField: true,
                              keyboardType: TextInputType.text,
                            ),
                            if (_isDocInvalid) ...[
                              const SizedBox(height: 4),
                              Text(
                                isEs
                                    ? 'Mínimo 5 caracteres alfanuméricos'
                                    : 'Min 5 alphanumeric chars',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: s.firstNameLabel,
                          controller: _firstName,
                          hint: 'Ej. Carmen',
                          requiredField: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledTextField(
                          label: isEs ? 'Segundo nombre' : 'Second name',
                          controller: _secondName,
                          hint: optionalLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: s.lastNameLabel,
                          controller: _firstLast,
                          hint: 'Ej. Vargas',
                          requiredField: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledTextField(
                          label: isEs ? 'Segundo apellido' : 'Second last name',
                          controller: _secondLast,
                          hint: optionalLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
                    label: isEs ? 'Sexo biológico' : 'Biological sex',
                    value: d.biologicalSex,
                    options: sex,
                    required: true,
                    onChanged: (v) => setState(() => d.biologicalSex = v),
                  ),
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: isEs ? 'Identidad de género' : 'Gender identity',
                    value: d.genderIdentity ?? '05',
                    items: gender,
                    onChanged: (v) => setState(() => d.genderIdentity = v),
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
                    label: isEs ? 'Etnia' : 'Ethnicity',
                    value: d.ethnicity ?? '99',
                    items: eth,
                    onChanged: (v) => setState(() => d.ethnicity = v),
                  ),
                  if (_hasEthnicity) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledTextField(
                          label: isEs ? 'Comunidad étnica' : 'Ethnic community',
                          controller: _ethnicComm,
                          hint: ethnicCommHint,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ethnicCommHelper,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _StyledDropdown<String>(
                    label: isEs ? 'Discapacidad' : 'Disability',
                    value: d.disabilityCategory ?? '08',
                    items: dis,
                    onChanged: (v) => setState(() => d.disabilityCategory = v),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                children: [
                  _ChipSelector(
                    label: s.bloodType,
                    value: d.bloodType,
                    options: blood,
                    required: false,
                    allowDeselect: true,
                    onChanged: (v) => setState(() {
                      d.bloodType = (d.bloodType == v) ? null : v;
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
                        child: LabeledTextField(
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
                        child: LabeledTextField(
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

              _SectionCard(
                children: [
                  _SectionHeader(icon: Icons.home_outlined, title: s.address),
                  LabeledTextField(
                    label: s.street,
                    controller: _street,
                    hint: s.streetHint,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: s.municipality,
                          controller: _city,
                          hint: s.cityHint,
                          requiredField: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledTextField(
                          label: s.department,
                          controller: _stateCtrl,
                          hint: s.stateHint,
                          requiredField: true,
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
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

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
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StyledDropdown<T> extends StatefulWidget {
  const _StyledDropdown({
    super.key,
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
  State<_StyledDropdown<T>> createState() => _StyledDropdownState<T>();
}

class _StyledDropdownState<T> extends State<_StyledDropdown<T>> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.items[widget.value] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildLabel(widget.label, widget.required),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              controller: _menuController,
              style: MenuStyle(
                fixedSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, double.nan),
                ),
                maximumSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, 250),
                ),
                backgroundColor: WidgetStateProperty.all(AppColors.white),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: _kEnabledBorder,
                      focusedBorder: _kFocusedBorder,
                      border: _kEnabledBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedLabel,
                            style: _kInputStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: widget.items.entries.map((e) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: MenuItemButton(
                    onPressed: () {
                      widget.onChanged(e.key);
                      _menuController.close();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        e.value,
                        style: _kInputStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
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
      _buildLabel(label, required),
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
    this.allowDeselect = false,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final bool required;
  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          _buildLabel(label, required),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map<Widget>((e) {
            final selected = e.key == value;
            return GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFB0B8C4),
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
