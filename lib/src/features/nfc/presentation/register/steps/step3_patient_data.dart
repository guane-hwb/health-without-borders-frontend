// lib/src/features/nfc/presentation/register/steps/step3_patient_data.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../register_nfc_screen.dart';

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
const _kHintStyle  = TextStyle(fontSize: 14, color: AppColors.textSecondary);
const _kLabelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
const _kReqStyle   = TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w700);

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
  late final _docNum       = TextEditingController(text: widget.draft.documentNumber);
  late final _firstName    = TextEditingController(text: widget.draft.firstName);
  late final _secondName   = TextEditingController(text: widget.draft.secondName ?? '');
  late final _firstLast    = TextEditingController(text: widget.draft.firstLastName);
  late final _secondLast   = TextEditingController(text: widget.draft.secondLastName ?? '');
  late final _street       = TextEditingController(text: widget.draft.street ?? '');
  late final _city         = TextEditingController(text: widget.draft.addressCity);
  late final _stateCtrl    = TextEditingController(text: widget.draft.addressState);
  late final _ethnicComm   = TextEditingController(text: widget.draft.ethnicCommunity ?? '');
  String? _err;

  static const _docTypes = {
    'TI': 'Tarjeta de Identidad', 'CC': 'Cédula de Ciudadanía',
    'RC': 'Registro Civil',       'CE': 'Cédula de Extranjería',
    'PA': 'Pasaporte',            'PE': 'Permiso Especial',
    'PT': 'PPT',                  'SC': 'Salvoconducto',
    'MS': 'Menor s/ID',           'AS': 'Adulto s/ID',
    'CN': 'Cert. nacido vivo',    'DE': 'Doc. extranjero',
  };
  static const _sex    = {'F': 'Femenino', 'M': 'Masculino', 'I': 'Indeterminado'};
  static const _gender = {'01': 'Masculino', '02': 'Femenino', '03': 'Transgénero', '04': 'No binario', '99': 'No reporta'};
  static const _nat    = {'COL': 'Colombiana', 'VEN': 'Venezolana', 'ECU': 'Ecuatoriana', 'PER': 'Peruana', 'HTI': 'Haitiana', 'CUB': 'Cubana'};
  static const _eth    = {'06': 'Ninguno', '01': 'Indígena', '02': 'ROM/Gitano', '03': 'Raizal', '04': 'Palenquero', '05': 'Afrocolombiano'};
  static const _dis    = {'00': 'Ninguna', '01': 'Física', '02': 'Intelectual', '03': 'Auditiva', '04': 'Visual', '05': 'Sordoceguera', '06': 'Psicosocial', '07': 'Múltiple'};
  static const _blood  = {'O+': 'O+', 'O-': 'O-', 'A+': 'A+', 'A-': 'A-', 'B+': 'B+', 'B-': 'B-', 'AB+': 'AB+', 'AB-': 'AB-'};
  static const _zones  = {'01': 'Urbana', '02': 'Rural'};

  bool get _hasEthnicity {
    final v = widget.draft.ethnicity;
    return v != null && v != '06';
  }

  @override
  void dispose() {
    _docNum.dispose(); _firstName.dispose(); _secondName.dispose();
    _firstLast.dispose(); _secondLast.dispose(); _street.dispose();
    _city.dispose(); _stateCtrl.dispose(); _ethnicComm.dispose();
    super.dispose();
  }

  void _save() {
    final missing = <String>[];
    if (_docNum.text.trim().isEmpty)    missing.add('Número de documento');
    if (_firstName.text.trim().isEmpty) missing.add('Primer nombre');
    if (_firstLast.text.trim().isEmpty) missing.add('Primer apellido');
    if (widget.draft.dob == null)       missing.add('Fecha de nacimiento');
    if (_city.text.trim().isEmpty)      missing.add('Municipio');
    if (_stateCtrl.text.trim().isEmpty) missing.add('Departamento');
    if (missing.isNotEmpty) {
      setState(() => _err = 'Campos requeridos: ${missing.join(', ')}');
      return;
    }
    final d = widget.draft;
    d.documentNumber  = _docNum.text.trim();
    d.firstName       = _firstName.text.trim();
    d.secondName      = _secondName.text.trim().isEmpty ? null : _secondName.text.trim();
    d.firstLastName   = _firstLast.text.trim();
    d.secondLastName  = _secondLast.text.trim().isEmpty ? null : _secondLast.text.trim();
    d.street          = _street.text.trim().isEmpty ? null : _street.text.trim();
    d.addressCity     = _city.text.trim();
    d.addressState    = _stateCtrl.text.trim();
    d.ethnicCommunity = _ethnicComm.text.trim().isEmpty ? null : _ethnicComm.text.trim();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Column(children: [
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
              child: const Row(children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Complete los datos del paciente. Los campos con * son obligatorios.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                )),
              ]),
            ),

            if (_err != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_err!, style: const TextStyle(fontSize: 12, color: AppColors.error))),
                ]),
              ),
            ],

            const SizedBox(height: 18),

            // ── Identification ─────────────────────────────────────────────
            _SectionCard(children: [
              const _SectionHeader(icon: Icons.badge_outlined, title: 'Identificación'),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 130,
                  child: _StyledDropdown<String>(
                    label: 'TIPO DOC.',
                    value: d.documentType,
                    items: _docTypes,
                    required: true,
                    onChanged: (v) { if (v != null) setState(() => d.documentType = v); },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _StyledTextField(
                  label: 'NÚMERO',
                  controller: _docNum,
                  hint: 'Ej. 1098765432',
                  required: true,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _StyledTextField(
                  label: 'PRIMER NOMBRE', controller: _firstName,
                  hint: 'Ej. Carmen', required: true,
                  textCapitalization: TextCapitalization.words,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StyledTextField(
                  label: 'SEGUNDO NOMBRE', controller: _secondName,
                  hint: 'Opcional',
                  textCapitalization: TextCapitalization.words,
                )),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _StyledTextField(
                  label: 'PRIMER APELLIDO', controller: _firstLast,
                  hint: 'Ej. Vargas', required: true,
                  textCapitalization: TextCapitalization.words,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StyledTextField(
                  label: 'SEGUNDO APELLIDO', controller: _secondLast,
                  hint: 'Opcional',
                  textCapitalization: TextCapitalization.words,
                )),
              ]),
            ]),

            const SizedBox(height: 14),

            // ── Demographic Data ─────────────────────────────────────────
            _SectionCard(children: [
              const _SectionHeader(icon: Icons.person_outline, title: 'Datos demográficos'),
              _StyledDateField(
                label: 'FECHA DE NACIMIENTO',
                value: d.dob,
                required: true,
                onChanged: (v) => setState(() => d.dob = v),
              ),
              const SizedBox(height: 12),
              _ChipSelector(
                label: 'SEXO BIOLÓGICO',
                value: d.biologicalSex,
                options: _sex,
                required: true,
                onChanged: (v) => setState(() => d.biologicalSex = v),
              ),
              const SizedBox(height: 12),
              _StyledDropdown<String>(
                label: 'IDENTIDAD DE GÉNERO',
                value: d.genderIdentity ?? '99',
                items: _gender,
                onChanged: (v) => setState(() => d.genderIdentity = v == '99' ? null : v),
              ),
              const SizedBox(height: 12),
              _StyledDropdown<String>(
                label: 'NACIONALIDAD',
                value: d.nationalityCode,
                items: _nat,
                required: true,
                onChanged: (v) {
                  if (v != null) setState(() { d.nationalityCode = v; d.nationalityName = _nat[v]; });
                },
              ),
              const SizedBox(height: 12),
              _StyledDropdown<String>(
                label: 'ETNIA',
                value: d.ethnicity ?? '06',
                items: _eth,
                onChanged: (v) => setState(() => d.ethnicity = v == '06' ? null : v),
              ),
              if (_hasEthnicity) ...[
                const SizedBox(height: 12),
                _StyledTextField(
                  label: 'COMUNIDAD ÉTNICA',
                  controller: _ethnicComm,
                  hint: 'Nombre de la comunidad',
                  helperText: 'Opcional. Solo si pertenece a una comunidad específica.',
                ),
              ],
              const SizedBox(height: 12),
              _StyledDropdown<String>(
                label: 'DISCAPACIDAD',
                value: d.disabilityCategory ?? '00',
                items: _dis,
                onChanged: (v) => setState(() => d.disabilityCategory = v == '00' ? null : v),
              ),
            ]),

            const SizedBox(height: 14),

            // ── Blood type ─────────────────────────────────────────────
            _SectionCard(children: [
              const _SectionHeader(
                icon: Icons.bloodtype_outlined,
                title: 'Tipo de sangre',
                subtitle: 'Dato biológico permanente',
              ),
              _ChipSelector(
                label: '',
                value: d.bloodType ?? 'O+',
                options: _blood,
                onChanged: (v) => setState(() => d.bloodType = v),
              ),
            ]),

            const SizedBox(height: 14),

            // ── Residence ─────────────────────────────────────────────────
            _SectionCard(children: [
              const _SectionHeader(icon: Icons.home_outlined, title: 'Residencia'),
              _StyledTextField(
                label: 'DIRECCIÓN',
                controller: _street,
                hint: 'Ej. Cra. 18 #27-43',
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _StyledTextField(
                  label: 'MUNICIPIO', controller: _city,
                  hint: 'Ej. Riohacha', required: true,
                  textCapitalization: TextCapitalization.words,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StyledTextField(
                  label: 'DEPARTAMENTO', controller: _stateCtrl,
                  hint: 'Ej. La Guajira', required: true,
                  textCapitalization: TextCapitalization.words,
                )),
              ]),
              const SizedBox(height: 12),
              _ChipSelector(
                label: 'ZONA',
                value: d.zone ?? '01',
                options: _zones,
                onChanged: (v) => setState(() => d.zone = v),
              ),
            ]),

            const SizedBox(height: 8),
          ],
        ),
      ),
      _NavButtons(onBack: widget.onBack, onContinue: _save),
    ]);
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
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
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
          Row(children: [
            Text(label, style: _kLabelStyle),
            if (required) const Text(' *', style: _kReqStyle),
          ]),
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
              helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          Row(children: [
            Text(label, style: _kLabelStyle),
            if (required) const Text(' *', style: _kReqStyle),
          ]),
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
                .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
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
          Row(children: [
            Text(label, style: _kLabelStyle),
            if (required) const Text(' *', style: _kReqStyle),
          ]),
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
              child: Row(children: [
                Expanded(child: Text(
                  _display.isEmpty ? 'YYYY-MM-DD' : _display,
                  style: _display.isEmpty ? _kHintStyle : _kInputStyle,
                )),
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              ]),
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
            Row(children: [
              Text(label, style: _kLabelStyle),
              if (required) const Text(' *', style: _kReqStyle),
            ]),
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
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, -3))],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: Row(children: [
          Expanded(child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.textSecondary),
              label: const Text('Atrás', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
              label: const Text('Continuar', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          )),
        ]),
      );
}