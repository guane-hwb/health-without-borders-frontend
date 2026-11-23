// lib/src/features/nfc/presentation/register/steps/step3_patient_data.dart

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../core/validation/identity_validators.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/country_display.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../../../domain/register_draft.dart';
import '../../../../../core/i18n/app_strings.dart';
import '../widgets/nfc_uid_field.dart';
import '../widgets/validation_feedback.dart';
import '../../profile/sheets/edit_vital_signs_helpers.dart';

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

/// Lets the register screen ask the patient-data step, before leaving the
/// registration, whether it shows input not yet saved to the draft: what is
/// typed there reaches the draft only on "Continuar".
class UnsavedInputProbe {
  bool Function()? _check;

  /// True while the step on screen shows input not yet saved to the draft.
  bool get hasUnsavedInput => _check?.call() ?? false;
}

/// The fields «Continuar» checks, in the order they appear on screen.
enum _PatientField {
  uid,
  docNum,
  firstName,
  firstLast,
  dob,
  nationality,
  weight,
  height,
  city,
  state,
}

class Step3PatientData extends StatefulWidget {
  const Step3PatientData({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onContinue,
    this.unsavedInput,
  });

  final RegisterDraft draft;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  /// Answers, while this step is on screen, whether it has unsaved input.
  final UnsavedInputProbe? unsavedInput;

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

  /// An NFC reading error; it takes the banner's place until «Continuar».
  String? _err;

  /// What the last «Continuar» found; the banner shows what is still open
  /// ([openSummary]).
  List<SummaryEntry<_PatientField>> _summary = const [];
  final _scroll = ScrollController();
  final _focus = <_PatientField, FocusNode>{
    for (final f in const [
      _PatientField.uid,
      _PatientField.docNum,
      _PatientField.firstName,
      _PatientField.firstLast,
      _PatientField.weight,
      _PatientField.height,
      _PatientField.city,
      _PatientField.state,
    ])
      f: FocusNode(),
  };

  /// The error under each field, set by «Continuar» (and, for the document,
  /// on leaving the field); typing in a field clears its own.
  final _fieldErrors = <_PatientField, String>{};

  bool get _hasEthnicity => patientHasEthnicity(widget.draft.ethnicity);

  /// The step's input when it opened, to tell whether any was entered since.
  late final List<Object?> _openedWith;

  @override
  void initState() {
    super.initState();
    _focus[_PatientField.docNum]!.addListener(_validateDocOnBlur);
    _openedWith = _input();
    widget.unsavedInput?._check = _hasUnsavedInput;
  }

  @override
  void dispose() {
    if (widget.unsavedInput?._check == _hasUnsavedInput) {
      widget.unsavedInput!._check = null;
    }
    _focus[_PatientField.docNum]!.removeListener(_validateDocOnBlur);
    for (final node in _focus.values) {
      node.dispose();
    }
    _scroll.dispose();
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

  /// The text typed in the fields, and what the selectors put in the draft.
  List<Object?> _input() {
    final d = widget.draft;
    return <Object?>[
      for (final TextEditingController field in <TextEditingController>[
        _docNum,
        _firstName,
        _secondName,
        _firstLast,
        _secondLast,
        _street,
        _city,
        _stateCtrl,
        _ethnicComm,
        _weight,
        _height,
        _patientUid,
      ])
        field.text.trim(),
      d.documentType,
      d.dob,
      d.biologicalSex,
      d.genderIdentity,
      d.nationalityCode,
      d.ethnicity,
      d.disabilityCategory,
      d.bloodType,
      d.isBloodTypeCertified,
      d.zone,
    ];
  }

  bool _hasUnsavedInput() => !listEquals(_input(), _openedWith);

  String? _docNumberError(bool isEs) =>
      validateDocumentNumber(_docNum.text) == null
      ? null
      : (isEs
            ? 'Número de documento inválido (5 a 20 caracteres, sin símbolos)'
            : 'Invalid document number (5 to 20 characters, no symbols)');

  /// The document's format is checked on leaving the field, not on each key.
  void _validateDocOnBlur() {
    if (!mounted || _focus[_PatientField.docNum]!.hasFocus) return;
    if (_docNum.text.trim().isEmpty) return;
    final error = _docNumberError(AppStrings.of(context).isEs);
    if (error == _fieldErrors[_PatientField.docNum]) return;
    setState(() {
      if (error == null) {
        _fieldErrors.remove(_PatientField.docNum);
      } else {
        _fieldErrors[_PatientField.docNum] = error;
      }
    });
  }

  void _clearFieldError(_PatientField field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
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
          _fieldErrors.remove(_PatientField.uid);
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
    final entries = <SummaryEntry<_PatientField>>[];
    final fieldErrors = <_PatientField, String>{};

    void requireText(
      _PatientField field,
      TextEditingController controller,
      String label,
    ) {
      if (controller.text.trim().isNotEmpty) return;
      final shown = field == _PatientField.uid
          ? s.nfcUidRequired
          : s.formFieldRequired;
      entries.add(SummaryEntry(label, field: field, fieldError: shown));
      fieldErrors[field] = shown;
    }

    void reject(_PatientField field, String error) {
      entries.add(
        SummaryEntry(error, field: field, fieldError: error, invalid: true),
      );
      fieldErrors[field] = error;
    }

    requireText(_PatientField.uid, _patientUid, s.patientNfcDevice);
    requireText(_PatientField.docNum, _docNum, s.documentNumberLabel);
    requireText(_PatientField.firstName, _firstName, s.firstNameLabel);
    requireText(_PatientField.firstLast, _firstLast, s.lastNameLabel);
    if (widget.draft.dob == null) {
      entries.add(
        SummaryEntry(
          s.dobLabel,
          field: _PatientField.dob,
          fieldError: s.formFieldRequired,
        ),
      );
      fieldErrors[_PatientField.dob] = s.formFieldRequired;
    }
    requireText(_PatientField.city, _city, s.municipality);
    requireText(_PatientField.state, _stateCtrl, s.department);

    final docError = _docNumberError(isEs);
    if (docError != null) reject(_PatientField.docNum, docError);

    final natCode = widget.draft.nationalityCode;
    if (!kSupportedNationalityCodes.contains(natCode)) {
      reject(
        _PatientField.nationality,
        isEs
            ? 'Nacionalidad no válida (código ISO 3166-1 requerido)'
            : 'Invalid nationality (ISO 3166-1 code required)',
      );
    }

    final weightText = _weight.text.trim();
    if (weightText.isNotEmpty) {
      final parsedWeight = parseWeight(weightText);
      if (parsedWeight == null || !isWeightInRange(parsedWeight)) {
        reject(_PatientField.weight, weightErrorMessage(isEs: isEs));
      }
    }

    final heightText = _height.text.trim();
    if (heightText.isNotEmpty) {
      final parsedHeight = parseHeight(heightText);
      if (parsedHeight == null || !isHeightInRange(parsedHeight)) {
        reject(_PatientField.height, heightErrorMessage(isEs: isEs));
      }
    }

    final summary = openSummary(s, entries, fieldErrors);
    if (summary != null) {
      setState(() {
        _err = null;
        _summary = entries;
        _fieldErrors
          ..clear()
          ..addAll(fieldErrors);
      });
      announceValidation(context, summary);
      final first = _PatientField.values
          .where(fieldErrors.containsKey)
          .firstOrNull;
      revealFirstInvalid(_scroll, _focus[first]);
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
    if (d.bloodType == null) {
      d.isBloodTypeCertified = false;
    }

    d.nationalityName = countryDisplay(d.nationalityCode).name(isEs: isEs);

    d.weight = _weight.text.trim().isEmpty ? null : parseWeight(_weight.text);
    d.height = _height.text.trim().isEmpty ? null : parseHeight(_height.text);

    applyDemographicSentinelDefaults(d);

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final banner = _err ?? openSummary(s, _summary, _fieldErrors);

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
            controller: _scroll,
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

              if (banner != null) ...[
                const SizedBox(height: 12),
                validationLiveRegion(
                  context,
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
                            banner,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    onChanged: () => setState(() {
                      widget.draft.deviceUid = _patientUid.text.trim().isEmpty
                          ? null
                          : _patientUid.text.trim();
                      _fieldErrors.remove(_PatientField.uid);
                    }),
                    hintText: s.manualPatientUidHint,
                    prefixIcon: Icons.watch_outlined,
                    errorText: _fieldErrors[_PatientField.uid],
                    focusNode: _focus[_PatientField.uid],
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
                    // With an error under the number, aligning the bottoms
                    // would push the type selector down beside the message.
                    crossAxisAlignment:
                        _fieldErrors.containsKey(_PatientField.docNum)
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
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
                        child: LabeledTextField(
                          label: s.documentNumberLabel,
                          controller: _docNum,
                          hint: 'Ej. 1098765432',
                          requiredField: true,
                          keyboardType: TextInputType.text,
                          errorText: _fieldErrors[_PatientField.docNum],
                          focusNode: _focus[_PatientField.docNum],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.docNum),
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
                          errorText: _fieldErrors[_PatientField.firstName],
                          focusNode: _focus[_PatientField.firstName],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.firstName),
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
                          errorText: _fieldErrors[_PatientField.firstLast],
                          focusNode: _focus[_PatientField.firstLast],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.firstLast),
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
                    onChanged: (v) => setState(() {
                      d.dob = v;
                      _fieldErrors.remove(_PatientField.dob);
                    }),
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
                          _fieldErrors.remove(_PatientField.nationality);
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
                      if (d.bloodType == v) {
                        d.bloodType = null;
                        d.isBloodTypeCertified = false;
                      } else {
                        d.bloodType = v;
                      }
                    }),
                  ),
                  if (d.bloodType != null) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    _ChipSelector(
                      label: isEs
                          ? '¿El cuidador presentó certificado o examen?'
                          : 'Did the caregiver show a certificate or lab test?',
                      value: d.isBloodTypeCertified ? 'certified' : 'mentioned',
                      options: {
                        'certified': isEs ? 'Sí' : 'Yes',
                        'mentioned': isEs ? 'No' : 'No',
                      },
                      required: true,
                      onChanged: (val) => setState(() {
                        d.isBloodTypeCertified = (val == 'certified');
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          d.isBloodTypeCertified
                              ? Icons.lock_outline
                              : Icons.info_outline,
                          size: 14,
                          color: d.isBloodTypeCertified
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.isBloodTypeCertified
                                ? (isEs
                                      ? 'Al estar certificado, quedará bloqueado en Leer NFC.'
                                      : 'Once certified, it will be locked in Read NFC.')
                                : (isEs
                                      ? 'Podrá editarse desde Leer NFC si luego presentan examen.'
                                      : 'Can be edited from Read NFC if a test is provided later.'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          errorText: _fieldErrors[_PatientField.weight],
                          focusNode: _focus[_PatientField.weight],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.weight),
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
                          errorText: _fieldErrors[_PatientField.height],
                          focusNode: _focus[_PatientField.height],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.height),
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
                          errorText: _fieldErrors[_PatientField.city],
                          focusNode: _focus[_PatientField.city],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.city),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LabeledTextField(
                          label: s.department,
                          controller: _stateCtrl,
                          hint: s.stateHint,
                          requiredField: true,
                          errorText: _fieldErrors[_PatientField.state],
                          focusNode: _focus[_PatientField.state],
                          onChanged: (_) =>
                              _clearFieldError(_PatientField.state),
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
