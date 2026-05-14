// lib/src/features/nfc/presentation/register/steps/step2_guardian.dart
import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../register_nfc_screen.dart';

// ─────────────────────────────────────────────
//  Document types
// ─────────────────────────────────────────────
const _docTypes = {
  'CC': 'Cédula de ciudadanía',
  'CE': 'Cédula de extranjero',
};

// ─────────────────────────────────────────────
//  Main widget
// ─────────────────────────────────────────────
class Step2Guardian extends StatefulWidget {
  const Step2Guardian({
    super.key,
    required this.draft,
    required this.requiredForMinor,
    required this.onBack,
    required this.onContinue,
  });
  final RegisterDraft draft;
  final bool requiredForMinor;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<Step2Guardian> createState() => _Step2State();
}

class _Step2State extends State<Step2Guardian> {
  // ── Controllers guardian 1 — initialized in initState ─
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _uid;
  late final TextEditingController _docNumber;
  late final TextEditingController _email;

  // ── Guardian 1 State ─────────────────
  String _selectedDocType = 'CC';
  bool _authAccepted = false;
  final List<List<Offset>> _signatureStrokes = [];
  List<Offset>? _currentStroke;
  bool _scanning = false;
  String? _err;

  // ── Guardian 2 ───────────────────
  bool _hasGuardian2 = false;
  late final TextEditingController _name2;
  late final TextEditingController _phone2;
  late final TextEditingController _docNumber2;
  String _selectedDocType2 = 'CC';
  String _guardian2Relationship = '01';

  static const _rels = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _name        = TextEditingController(text: d.guardianName ?? '');
    _phone       = TextEditingController(text: d.guardianPhone ?? '');
    _uid         = TextEditingController(text: d.guardianDeviceUid ?? '');
    _docNumber   = TextEditingController(text: d.guardianDocNumber ?? '');
    _email       = TextEditingController(text: d.guardianEmail ?? '');
    _selectedDocType = d.guardianDocType ?? 'CC';
    _authAccepted    = d.guardianAuthAccepted ?? false;

    // Guardian 2
    _name2      = TextEditingController(text: d.guardian2Name ?? '');
    _phone2     = TextEditingController(text: d.guardian2Phone ?? '');
    _docNumber2 = TextEditingController(text: d.guardian2DocNumber ?? '');
    _selectedDocType2    = d.guardian2DocType ?? 'CC';
    _guardian2Relationship = d.guardian2Relationship ?? '01';
    _hasGuardian2 = d.guardian2Name != null && d.guardian2Name!.isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _uid.dispose();
    _docNumber.dispose();
    _email.dispose();
    _name2.dispose();
    _phone2.dispose();
    _docNumber2.dispose();
    super.dispose();
  }

  // ── NFC ──────────────────────────────────────
  Future<void> _scanNfc() async {
    setState(() => _scanning = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() {
          _uid.text = uid;
          _scanning = false;
        });
      }
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('NFC no disponible. Use el campo manual.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al leer NFC. Inténtalo de nuevo.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    }
  }

  // ── Validation and saving ─────────────────────
  void _save() {
    final missing = <String>[];

    if (widget.requiredForMinor) {
      if (_name.text.trim().isEmpty) missing.add('Nombre completo');
      if (_phone.text.trim().isEmpty) missing.add('Teléfono');
      if (_uid.text.trim().isEmpty) missing.add('UID del dispositivo NFC');
      if (_docNumber.text.trim().isEmpty) missing.add('Número de documento');
      if (_email.text.trim().isEmpty) missing.add('Correo electrónico');
      if (_signatureStrokes.isEmpty) missing.add('Firma biométrica');
    }

    // Validate authorization always when there's an email or signature
    if (_email.text.trim().isNotEmpty || _signatureStrokes.isNotEmpty) {
      if (!_authAccepted) missing.add('Autorización y privacidad');
    }

    if (missing.isNotEmpty) {
      setState(() => _err = 'Campos requeridos: ${missing.join(', ')}');
      return;
    }

    setState(() => _err = null);
    final d = widget.draft;
    d.guardianName = _name.text.trim().isEmpty ? null : _name.text.trim();
    d.guardianPhone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    d.guardianDeviceUid = _uid.text.trim().isEmpty ? null : _uid.text.trim();
    d.guardianDocType = _selectedDocType;
    d.guardianDocNumber =
        _docNumber.text.trim().isEmpty ? null : _docNumber.text.trim();
    d.guardianAuthAccepted = _authAccepted;
    d.guardianEmail =
        _email.text.trim().isEmpty ? null : _email.text.trim();

    // Save guardian 2 if it was added
    if (_hasGuardian2) {
      d.guardian2Name = _name2.text.trim().isEmpty ? null : _name2.text.trim();
      d.guardian2Phone = _phone2.text.trim().isEmpty ? null : _phone2.text.trim();
      d.guardian2DocType = _selectedDocType2;
      d.guardian2DocNumber = _docNumber2.text.trim().isEmpty ? null : _docNumber2.text.trim();
      d.guardian2Relationship = _guardian2Relationship;
    } else {
      d.guardian2Name = null;
      d.guardian2Phone = null;
      d.guardian2DocNumber = null;
      d.guardian2Relationship = null;
    }

    widget.onContinue();
  }

  // ── Signature: clean ────────────────────────────
  void _clearSignature() {
    setState(() {
      _signatureStrokes.clear();
      _currentStroke = null;
    });
  }

  // ── Modal privacy policy ──────────────
  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _PrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              _NoticeBanner(requiredForMinor: widget.requiredForMinor),
              const SizedBox(height: 20),

              // ── Guardian section ────────────────
              FormSectionHeader(
                icon: Icons.family_restroom,
                title: 'Información del guardián',
              ),
              const SizedBox(height: 14),

              _StyledTextField(
                label: 'Nombre completo',
                controller: _name,
                hint: 'Ej. Carmen Vargas Pinto',
                required: widget.requiredForMinor,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),

              _RelChipSelector(
                label: 'Parentesco',
                required: widget.requiredForMinor,
                value: d.guardianRelationship ?? '01',
                options: _rels,
                onChanged: (v) => setState(() => d.guardianRelationship = v),
              ),
              const SizedBox(height: 14),

              _StyledTextField(
                label: 'Teléfono',
                controller: _phone,
                hint: '+57 310 482 9914',
                required: widget.requiredForMinor,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // ── Document Type ────────
              _DocTypeSelector(
                label: 'Tipo de documento',
                required: widget.requiredForMinor,
                value: _selectedDocType,
                options: _docTypes,
                onChanged: (v) => setState(() => _selectedDocType = v),
              ),
              const SizedBox(height: 14),

              // ── Document Number ───────
              _StyledTextField(
                label: 'Número de documento',
                controller: _docNumber,
                hint: 'Ej. 1234567890',
                required: widget.requiredForMinor,
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),

              // ── NFC ─────────────────────────────
              FormSectionHeader(
                icon: Icons.nfc,
                title: 'Dispositivo NFC del guardián',
                subtitle:
                    'Necesaria para autenticación 2FA al consultar el historial de menores.',
              ),
              const SizedBox(height: 12),

              _NfcField(
                controller: _uid,
                scanning: _scanning,
                onScan: _scanNfc,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 26),

              // ── Button + Add guardian 2 (only if it doesn't already exist) ────────
              if (!_hasGuardian2)
                _AddGuardianButton(
                  onTap: () => setState(() => _hasGuardian2 = true),
                ),

              // ── Section guardian 2 ────────────────────────────────────────
              if (_hasGuardian2) ...[
                const SizedBox(height: 4),
                _Guardian2Section(
                  nameCtrl: _name2,
                  phoneCtrl: _phone2,
                  docNumberCtrl: _docNumber2,
                  selectedDocType: _selectedDocType2,
                  relationship: _guardian2Relationship,
                  requiredForMinor: widget.requiredForMinor,
                  onDocTypeChanged: (v) => setState(() => _selectedDocType2 = v),
                  onRelationshipChanged: (v) => setState(() => _guardian2Relationship = v),
                  onRemove: () {
                    setState(() {
                      _hasGuardian2 = false;
                      _name2.clear();
                      _phone2.clear();
                      _docNumber2.clear();
                      _selectedDocType2 = 'CC';
                      _guardian2Relationship = '01';
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 26),

              // ── Authorization and privacy ─
              _AuthSection(
                accepted: _authAccepted,
                emailController: _email,
                signatureStrokes: _signatureStrokes,
                currentStroke: _currentStroke,
                onAcceptedChanged: (v) => setState(() => _authAccepted = v),
                onPrivacyTap: _showPrivacyPolicy,
                onSignatureStart: (offset) {
                  setState(() {
                    _currentStroke = [offset];
                    _signatureStrokes.add(_currentStroke!);
                  });
                },
                onSignatureUpdate: (offset) {
                  setState(() => _currentStroke?.add(offset));
                },
                onSignatureEnd: () => setState(() => _currentStroke = null),
                onClearSignature: _clearSignature,
              ),

              // ── Error ────────────────────────────
              if (_err != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _err!),
              ],
            ],
          ),
        ),
        _NavButtons(onBack: widget.onBack, onContinue: _save),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Document Type Selector (styled dropdown)
// ═════════════════════════════════════════════════════════════════════════════
class _DocTypeSelector extends StatelessWidget {
  const _DocTypeSelector({
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFB0B8C4),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: options.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.credit_card_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(e.value),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Authorization and Privacy Section
// ═════════════════════════════════════════════════════════════════════════════
class _AuthSection extends StatelessWidget {
  const _AuthSection({
    required this.accepted,
    required this.emailController,
    required this.signatureStrokes,
    required this.currentStroke,
    required this.onAcceptedChanged,
    required this.onPrivacyTap,
    required this.onSignatureStart,
    required this.onSignatureUpdate,
    required this.onSignatureEnd,
    required this.onClearSignature,
  });

  final bool accepted;
  final TextEditingController emailController;
  final List<List<Offset>> signatureStrokes;
  final List<Offset>? currentStroke;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onPrivacyTap;
  final ValueChanged<Offset> onSignatureStart;
  final ValueChanged<Offset> onSignatureUpdate;
  final VoidCallback onSignatureEnd;
  final VoidCallback onClearSignature;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título sección
          const Text(
            'Autorización y Privacidad',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // ── Checkbox with text and link ──────────
          _AuthCheckbox(
            accepted: accepted,
            onChanged: onAcceptedChanged,
            onPrivacyTap: onPrivacyTap,
          ),
          const SizedBox(height: 16),

          // ── Email ──────────────────────────────
          Row(
            children: [
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'correo@ejemplo.com',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFB0B8C4),
                  width: 1.5,
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
          const SizedBox(height: 16),

          // ── Biometric Signature ───────────────────
          Row(
            children: [
              const Text(
                'Firma biométrica',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SignaturePad(
            strokes: signatureStrokes,
            onPanStart: onSignatureStart,
            onPanUpdate: onSignatureUpdate,
            onPanEnd: onSignatureEnd,
            onClear: onClearSignature,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Authorization checkbox with link to policy
// ─────────────────────────────────────────────
class _AuthCheckbox extends StatelessWidget {
  const _AuthCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.onPrivacyTap,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: accepted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!accepted),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(
                    text:
                        'El guardián reconoce haber leído y autorizado el tratamiento de los datos del menor y la ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onPrivacyTap,
                      child: const Text(
                        'política de privacidad',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' incluyendo el recibo electrónico de comprobantes.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Biometric signature pad
// ─────────────────────────────────────────────
class _SignaturePad extends StatelessWidget {
  const _SignaturePad({
    required this.strokes,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onClear,
  });

  final List<List<Offset>> strokes;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onClear;

  bool get _hasSignature => strokes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFB0B8C4),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: GestureDetector(
            onPanStart: (d) => onPanStart(d.localPosition),
            onPanUpdate: (d) => onPanUpdate(d.localPosition),
            onPanEnd: (_) => onPanEnd(),
            child: CustomPaint(
              painter: _SignaturePainter(strokes: strokes),
              child: _hasSignature
                  ? null
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Firmar aquí',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: _hasSignature ? onClear : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _hasSignature
                    ? AppColors.primary
                    : const Color(0xFFB0B8C4),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text(
              'Limpiar firma',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Painter of the firm
// ─────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes});
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.strokes != strokes;
}

// ═════════════════════════════════════════════════════════════════════════════
//  Privacy policy modality
// ═════════════════════════════════════════════════════════════════════════════
class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Head ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Política de privacidad',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // ── Scrollable content ──────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _PolicyTitle(
                    'Política de Privacidad: Aviso sobre el Tratamiento de Datos de Menores',
                  ),
                  SizedBox(height: 12),
                  _PolicySection(
                    title: '1. Introducción',
                    body:
                        'Esta Política de Privacidad describe cómo recopilamos, usamos y protegemos los datos personales de menores y sus tutores legales. Al proporcionar su consentimiento, usted autoriza el tratamiento de esta información con el propósito de identificación médica y asistencia de emergencia.',
                  ),
                  _PolicySection(
                    title: '2. Datos que recopilamos',
                    body: '',
                    bullets: [
                      'Información del menor: Nombre completo, número de identificación y condiciones médicas/de salud relevantes.',
                      'Información del guardián: Nombre completo, relación con el menor, datos de contacto y dirección física.',
                      'Datos biométricos: Firma digital como prueba de autorización legal.',
                    ],
                  ),
                  _PolicySection(
                    title: '3. Seguridad de los datos',
                    body:
                        'Implementamos protocolos de cifrado y seguridad de alto nivel para garantizar que la información personal y médica se almacene de forma segura y solo sea accesible por partes autorizadas en una emergencia.',
                  ),
                  _PolicySection(
                    title: '4. Sus derechos (Derechos ARCO)',
                    body:
                        'Como guardián, tiene derecho a acceder, rectificar, cancelar u oponerse al tratamiento de sus datos o los datos del menor en cualquier momento a través de nuestros canales de soporte.',
                  ),
                  _PolicySection(
                    title: '5. Recibo de prueba de consentimiento',
                    body:
                        'Una vez aceptada, se enviará a la dirección de correo electrónico proporcionada una copia digital de esta autorización y su firma digital como comprobante legal de esta transacción.',
                  ),
                  _PolicySection(
                    title: '6. Finalidad del tratamiento',
                    body:
                        'Los datos se utilizarán exclusivamente para identificación médica, asistencia de emergencia y comunicación con el guardián legal del menor registrado en la plataforma.',
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Accept button ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Aceptar',
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
    );
  }
}

class _PolicyTitle extends StatelessWidget {
  const _PolicyTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.requiredForMinor});
  final bool requiredForMinor;

  @override
  Widget build(BuildContext context) {
    final isWarning = requiredForMinor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF3CD) : const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFD4A017)
              : const Color(0xFF90CAF9),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 22,
            color: isWarning
                ? const Color(0xFF8B6914)
                : const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isWarning
                  ? 'El paciente es menor de 18 años. El guardián es obligatorio (Ley 1098/2006).'
                  : 'Opcional para adultos. Si lo registra, podrá ser usado como contacto de emergencia.',
              style: TextStyle(
                fontSize: 13,
                color: isWarning
                    ? const Color(0xFF5D4400)
                    : const Color(0xFF0D47A1),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFB0B8C4),
                width: 1.5,
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
      ],
    );
  }
}

class _RelChipSelector extends StatelessWidget {
  const _RelChipSelector({
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
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
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
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

class _NfcField extends StatelessWidget {
  const _NfcField({
    required this.controller,
    required this.scanning,
    required this.onScan,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool scanning;
  final VoidCallback onScan;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'UID del dispositivo NFC',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.family_restroom,
                    size: 20,
                    color: hasValue
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: hasValue
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.success,
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFB0B8C4),
                      width: 1.5,
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
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              width: 56,
              child: ElevatedButton(
                onPressed: scanning ? null : onScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  elevation: 0,
                ),
                child: scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.nfc, size: 22, color: AppColors.white),
              ),
            ),
          ],
        ),
        if (hasValue) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 13,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                'Dispositivo vinculado: ${controller.text.trim()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Button + Add guardian 2
// ═════════════════════════════════════════════════════════════════════════════
class _AddGuardianButton extends StatelessWidget {
  const _AddGuardianButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.family_restroom,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Guardián 2',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
          label: const Text(
            'Agregar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Section guardian 2
// ═════════════════════════════════════════════════════════════════════════════
class _Guardian2Section extends StatelessWidget {
  const _Guardian2Section({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.docNumberCtrl,
    required this.selectedDocType,
    required this.relationship,
    required this.requiredForMinor,
    required this.onDocTypeChanged,
    required this.onRelationshipChanged,
    required this.onRemove,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController docNumberCtrl;
  final String selectedDocType;
  final String relationship;
  final bool requiredForMinor;
  final ValueChanged<String> onDocTypeChanged;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onRemove;

  static const _rels = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFB0B8C4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Información del guardián 2',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  tooltip: 'Eliminar guardián 2',
                ),
              ],
            ),
          ),
          const Divider(height: 16, thickness: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StyledTextField(
                  label: 'Nombre completo',
                  controller: nameCtrl,
                  hint: 'Ej. Roberto Martínez',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _RelChipSelector(
                  label: 'Parentesco',
                  value: relationship,
                  options: _rels,
                  onChanged: onRelationshipChanged,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  label: 'Teléfono',
                  controller: phoneCtrl,
                  hint: '+57 310 000 0000',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _DocTypeSelector(
                  label: 'Tipo de documento',
                  value: selectedDocType,
                  options: _docTypes,
                  onChanged: onDocTypeChanged,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  label: 'Número de documento',
                  controller: docNumberCtrl,
                  hint: 'Ej. 1234567890',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
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
    );
  }
}