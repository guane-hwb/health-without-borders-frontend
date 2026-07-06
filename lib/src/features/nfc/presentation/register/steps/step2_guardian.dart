// lib/src/features/nfc/presentation/register/steps/step2_guardian.dart
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../register_nfc_screen.dart';
import '../../../../../core/i18n/app_strings.dart';

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
  late final TextEditingController _uid2;
  late final TextEditingController _email2;
  String _selectedDocType2 = 'CC';
  String _guardian2Relationship = '01';
  bool _auth2Accepted = false;
  final List<List<Offset>> _signatureStrokes2 = [];
  List<Offset>? _currentStroke2;
  bool _scanning2 = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _name = TextEditingController(text: d.guardianName ?? '');
    _phone = TextEditingController(text: d.guardianPhone ?? '');
    _uid = TextEditingController(text: d.guardianDeviceUid ?? '');
    _docNumber = TextEditingController(text: d.guardianDocNumber ?? '');
    _email = TextEditingController(text: d.guardianEmail ?? '');
    _selectedDocType = d.guardianDocType ?? 'CC';
    _authAccepted = d.guardianAuthAccepted ?? false;

    // Guardian 2
    _name2 = TextEditingController(text: d.guardian2Name ?? '');
    _phone2 = TextEditingController(text: d.guardian2Phone ?? '');
    _docNumber2 = TextEditingController(text: d.guardian2DocNumber ?? '');
    _uid2 = TextEditingController(text: d.guardian2DeviceUid ?? '');
    _email2 = TextEditingController(text: d.guardian2Email ?? '');
    _selectedDocType2 = d.guardian2DocType ?? 'CC';
    _guardian2Relationship = d.guardian2Relationship ?? '01';
    _auth2Accepted = d.guardian2AuthAccepted ?? false;
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
    _uid2.dispose();
    _email2.dispose();
    super.dispose();
  }

  // ── NFC ──────────────────────────────────────
  Future<void> _scanNfc() async {
    final s = AppStrings.of(context);
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
            content: Text(s.guardianNfcUnavailable),
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
            content: Text(s.guardianNfcError),
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

  Future<void> _scanNfc2() async {
    final s = AppStrings.of(context);
    setState(() => _scanning2 = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() {
          _uid2.text = uid;
          _scanning2 = false;
        });
      }
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() => _scanning2 = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.guardianNfcUnavailable),
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
        setState(() => _scanning2 = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.guardianNfcError),
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

  Future<String?> _signatureToBase64(List<List<Offset>> strokes) async {
    if (strokes.isEmpty) return null;
    const w = 400.0, h = 200.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFFFFFFF),
    );
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
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(byteData.buffer.asUint8List());
  }

  // ── Validation and saving ─────────────────────
  Future<void> _save() async {
    final s = AppStrings.of(context);
    final missing = <String>[];

    final isEs = s.welcome == 'Bienvenido';
    final bioSigLabel = isEs ? 'Firma biométrica' : 'Biometric signature';
    final auth2Label = isEs
        ? 'Autorización guardián 2'
        : 'Guardian 2 Authorization';
    final requiredFieldsLabel = isEs ? 'Campos requeridos' : 'Required fields';

    if (widget.requiredForMinor) {
      if (_name.text.trim().isEmpty) missing.add(s.guardianFullName);
      if (_phone.text.trim().isEmpty) missing.add(s.guardianPhoneLabel);
      if (_uid.text.trim().isEmpty) missing.add(s.guardianNfcDevice);
      if (_docNumber.text.trim().isEmpty) missing.add(s.documentNumberLabel);
      if (_signatureStrokes.isEmpty) missing.add(bioSigLabel);
    }

    final String cleanDoc = _docNumber.text.trim();
    if (cleanDoc.isNotEmpty) {
      final docRegex = RegExp(r'^[a-zA-Z0-9-]{5,20}$');
      if (!docRegex.hasMatch(cleanDoc)) {
        missing.add(
          isEs
              ? 'Documento de guardián inválido (Mínimo 5 caracteres sin símbolos)'
              : 'Invalid Guardian Document format',
        );
      }
    }

    final String cleanPhone = _phone.text.trim();
    if (cleanPhone.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
      if (!phoneRegex.hasMatch(cleanPhone)) {
        missing.add(
          isEs
              ? 'Teléfono inválido (mínimo 7 dígitos)'
              : 'Invalid Phone format',
        );
      }
    }

    final String cleanEmail = _email.text.trim();
    if (cleanEmail.isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(cleanEmail)) {
        missing.add(
          isEs ? 'Correo electrónico inválido' : 'Invalid Email format',
        );
      }
    }

    if (_signatureStrokes.isNotEmpty) {
      if (!_authAccepted) missing.add(s.confirmChanges);
    }

    if (_hasGuardian2 && _name2.text.trim().isNotEmpty) {
      final String cleanDoc2 = _docNumber2.text.trim();
      final String cleanPhone2 = _phone2.text.trim();
      final String cleanEmail2 = _email2.text.trim();

      if (cleanDoc2.isNotEmpty &&
          !RegExp(r'^[a-zA-Z0-9-]{5,20}$').hasMatch(cleanDoc2)) {
        missing.add(
          isEs
              ? 'Documento de Guardián 2 inválido'
              : 'Invalid Guardian 2 Document',
        );
      }
      if (cleanPhone2.isNotEmpty &&
          !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleanPhone2)) {
        missing.add(
          isEs ? 'Teléfono de Guardián 2 inválido' : 'Invalid Guardian 2 Phone',
        );
      }
      if (cleanEmail2.isNotEmpty &&
          !RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          ).hasMatch(cleanEmail2)) {
        missing.add(
          isEs ? 'Correo de Guardián 2 inválido' : 'Invalid Guardian 2 Email',
        );
      }

      if (_signatureStrokes2.isNotEmpty) {
        if (!_auth2Accepted) missing.add(auth2Label);
      }
    }

    if (missing.isNotEmpty) {
      setState(() => _err = '$requiredFieldsLabel: ${missing.join(', ')}');
      return;
    }

    setState(() => _err = null);

    final sig1Base64 = await _signatureToBase64(_signatureStrokes);
    final sig2Base64 = _hasGuardian2
        ? await _signatureToBase64(_signatureStrokes2)
        : null;

    final d = widget.draft;
    d.guardianName = _name.text.trim().isEmpty ? null : _name.text.trim();
    d.guardianPhone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    d.guardianDeviceUid = _uid.text.trim().isEmpty ? null : _uid.text.trim();
    d.guardianDocType = _selectedDocType;
    d.guardianDocNumber = _docNumber.text.trim().isEmpty
        ? null
        : _docNumber.text.trim();
    d.guardianAuthAccepted = _authAccepted;
    d.guardianEmail = _email.text.trim().isEmpty ? null : _email.text.trim();
    d.guardianSignatureBase64 = sig1Base64;
    d.guardianRelationship = d.guardianRelationship ?? '01';

    if (_hasGuardian2 && _name2.text.trim().isNotEmpty) {
      d.guardian2Name = _name2.text.trim();
      d.guardian2Phone = _phone2.text.trim().isEmpty
          ? null
          : _phone2.text.trim();
      d.guardian2DeviceUid = _uid2.text.trim().isEmpty
          ? null
          : _uid2.text.trim();
      d.guardian2DocType = _selectedDocType2;
      d.guardian2DocNumber = _docNumber2.text.trim().isEmpty
          ? null
          : _docNumber2.text.trim();
      d.guardian2Relationship = _guardian2Relationship;
      d.guardian2AuthAccepted = _auth2Accepted;
      d.guardian2Email = _email2.text.trim().isEmpty
          ? null
          : _email2.text.trim();
      d.guardian2SignatureBase64 = sig2Base64;
    } else {
      d.guardian2Name = null;
      d.guardian2Phone = null;
      d.guardian2DeviceUid = null;
      d.guardian2DocType = null;
      d.guardian2DocNumber = null;
      d.guardian2Relationship = null;
      d.guardian2AuthAccepted = null;
      d.guardian2Email = null;
      d.guardian2SignatureBase64 = null;
    }

    if (_hasGuardian2) {
      d.guardian2Name = _name2.text.trim().isEmpty ? null : _name2.text.trim();
      d.guardian2Phone = _phone2.text.trim().isEmpty
          ? null
          : _phone2.text.trim();
      d.guardian2DeviceUid = _uid2.text.trim().isEmpty
          ? null
          : _uid2.text.trim();
      d.guardian2DocType = _selectedDocType2;
      d.guardian2DocNumber = _docNumber2.text.trim().isEmpty
          ? null
          : _docNumber2.text.trim();
      d.guardian2Relationship = _guardian2Relationship;
      d.guardian2AuthAccepted = _auth2Accepted;
      d.guardian2Email = _email2.text.trim().isEmpty
          ? null
          : _email2.text.trim();
      d.guardian2SignatureBase64 = sig2Base64;
    } else {
      d.guardian2Name = null;
      d.guardian2Phone = null;
      d.guardian2DeviceUid = null;
      d.guardian2DocNumber = null;
      d.guardian2Relationship = null;
      d.guardian2AuthAccepted = null;
      d.guardian2Email = null;
      d.guardian2SignatureBase64 = null;
    }

    widget.onContinue();
  }

  void _clearSignature() {
    setState(() {
      _signatureStrokes.clear();
      _currentStroke = null;
    });
  }

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
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    final docTypes = {'CC': s.docTypeCC, 'CE': s.docTypeCE};
    final rels = {
      '01': s.relParents,
      '02': s.relSiblings,
      '03': s.relUncles,
      '04': s.relGrandparents,
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              _NoticeBanner(requiredForMinor: widget.requiredForMinor),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Icon(
                    Icons.family_restroom,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEs ? 'Información del guardián' : 'Guardian information',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!_hasGuardian2)
                    TextButton.icon(
                      onPressed: () => setState(() => _hasGuardian2 = true),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        isEs ? 'Agregar' : 'Add',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
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
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
                                '1',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEs ? 'Editar guardián 1' : 'Edit guardian 1',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 18,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StyledTextField(
                            label: s.guardianFullName,
                            controller: _name,
                            hint: s.guardianFullNameHint,
                            required: widget.requiredForMinor,
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          _RelChipSelector(
                            label: s.guardianRelationship,
                            required: widget.requiredForMinor,
                            value: d.guardianRelationship ?? '01',
                            options: rels,
                            onChanged: (v) =>
                                setState(() => d.guardianRelationship = v),
                          ),
                          const SizedBox(height: 12),
                          _StyledTextField(
                            label: s.guardianPhoneLabel,
                            controller: _phone,
                            hint: s.guardianPhoneHint,
                            required: widget.requiredForMinor,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _DocTypeSelector(
                            label: s.documentTypeLabel,
                            required: widget.requiredForMinor,
                            value: _selectedDocType,
                            options: docTypes,
                            onChanged: (v) =>
                                setState(() => _selectedDocType = v),
                          ),
                          const SizedBox(height: 12),
                          _StyledTextField(
                            label: s.documentNumberLabel,
                            controller: _docNumber,
                            hint: 'Ej. 1234567890',
                            required: widget.requiredForMinor,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          FormSectionHeader(
                            icon: Icons.nfc,
                            title: s.guardianNfcDevice,
                          ),
                          const SizedBox(height: 12),
                          _NfcField(
                            controller: _uid,
                            scanning: _scanning,
                            onScan: _scanNfc,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _AuthSection(
                            accepted: _authAccepted,
                            emailController: _email,
                            emailRequired: false,
                            signatureStrokes: _signatureStrokes,
                            currentStroke: _currentStroke,
                            onAcceptedChanged: (v) =>
                                setState(() => _authAccepted = v),
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
                            onSignatureEnd: () =>
                                setState(() => _currentStroke = null),
                            onClearSignature: _clearSignature,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Section guardian 2 ────────────────────────────────────────
              if (_hasGuardian2) ...[
                const SizedBox(height: 16),
                _Guardian2Section(
                  nameCtrl: _name2,
                  phoneCtrl: _phone2,
                  docNumberCtrl: _docNumber2,
                  uidCtrl: _uid2,
                  emailCtrl: _email2,
                  selectedDocType: _selectedDocType2,
                  relationship: _guardian2Relationship,
                  requiredForMinor: widget.requiredForMinor,
                  authAccepted: _auth2Accepted,
                  signatureStrokes: _signatureStrokes2,
                  currentStroke: _currentStroke2,
                  scanning: _scanning2,
                  onDocTypeChanged: (v) =>
                      setState(() => _selectedDocType2 = v),
                  onRelationshipChanged: (v) =>
                      setState(() => _guardian2Relationship = v),
                  onRemove: () {
                    setState(() {
                      _hasGuardian2 = false;
                      _name2.clear();
                      _phone2.clear();
                      _docNumber2.clear();
                      _uid2.clear();
                      _email2.clear();
                      _selectedDocType2 = 'CC';
                      _guardian2Relationship = '01';
                      _auth2Accepted = false;
                      _signatureStrokes2.clear();
                      _currentStroke2 = null;
                    });
                  },
                  onScanNfc: _scanNfc2,
                  onAuthChanged: (v) => setState(() => _auth2Accepted = v),
                  onPrivacyTap: _showPrivacyPolicy,
                  onSignatureStart: (offset) {
                    setState(() {
                      _currentStroke2 = [offset];
                      _signatureStrokes2.add(_currentStroke2!);
                    });
                  },
                  onSignatureUpdate: (offset) {
                    setState(() => _currentStroke2?.add(offset));
                  },
                  onSignatureEnd: () => setState(() => _currentStroke2 = null),
                  onClearSignature: () {
                    setState(() {
                      _signatureStrokes2.clear();
                      _currentStroke2 = null;
                    });
                  },
                  onNfcFieldChanged: () => setState(() {}),
                ),
              ],

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
            border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
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
    this.emailRequired = false,
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
  final bool emailRequired;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';
    final signatureLabel = isEs ? 'Firma biométrica' : 'Biometric signature';

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
          Text(
            s.confirmChanges,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          _AuthCheckbox(
            accepted: accepted,
            onChanged: onAcceptedChanged,
            onPrivacyTap: onPrivacyTap,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                s.email,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (emailRequired)
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
              hintText: s.emailHint,
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

          Row(
            children: [
              Text(
                signatureLabel,
                style: const TextStyle(
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
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

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
                  TextSpan(
                    text: isEs
                        ? 'El guardián reconoce haber leído y autorizado el tratamiento de los datos del menor y la '
                        : 'The guardian acknowledges having read and authorized the processing of the minor\'s data and the ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onPrivacyTap,
                      child: Text(
                        isEs ? 'política de privacidad' : 'privacy policy',
                        style: const TextStyle(
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
                  TextSpan(
                    text: isEs
                        ? ' incluyendo el recibo electrónico de comprobantes.'
                        : ' including the electronic receipt of credentials.',
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
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
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
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEs ? 'Firmar aquí' : 'Sign here',
                            style: const TextStyle(
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
            label: Text(
              isEs ? 'Limpiar firma' : 'Clear signature',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

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
//  Privacy policy modal
// ═════════════════════════════════════════════════════════════════════════════
class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEs ? 'Política de privacidad' : 'Privacy Policy',
                    style: const TextStyle(
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isEs
                    ? const [
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
                      ]
                    : const [
                        _PolicyTitle(
                          'Privacy Policy: Notice on the Processing of Minor\'s Data',
                        ),
                        SizedBox(height: 12),
                        _PolicySection(
                          title: '1. Introduction',
                          body:
                              'This Privacy Policy describes how we collect, use, and protect the personal data of minors and their legal guardians. By providing your consent, you authorize the processing of this information for medical identification and emergency assistance purposes.',
                        ),
                        _PolicySection(
                          title: '2. Data We Collect',
                          body: '',
                          bullets: [
                            'Minor\'s information: Full name, identification number, and relevant medical/health conditions.',
                            'Guardian\'s information: Full name, relationship to the minor, contact details, and physical address.',
                            'Biometric data: Digital signature as proof of legal authorization.',
                          ],
                        ),
                        _PolicySection(
                          title: '3. Data Security',
                          body:
                              'We implement high-level encryption and security protocols to ensure that personal and medical information is stored securely and is only accessible by authorized parties in an emergency.',
                        ),
                        _PolicySection(
                          title: '4. Your Rights (ARCO Rights)',
                          body:
                              'As a guardian, you have the right to access, rectify, cancel, or object to the processing of your data or the minor\'s data at any time through our support channels.',
                        ),
                        _PolicySection(
                          title: '5. Receipt of Proof of Consent',
                          body:
                              'Once accepted, a digital copy of this authorization and your digital signature will be sent to the provided email address as legal proof of this transaction.',
                        ),
                        _PolicySection(
                          title: '6. Purpose of Processing',
                          body:
                              'The data will be used exclusively for medical identification, emergency assistance, and communication with the legal guardian of the minor registered on the platform.',
                        ),
                      ],
              ),
            ),
          ),
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
                child: Text(
                  s.ok,
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
    final s = AppStrings.of(context);
    final isWarning = requiredForMinor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF3CD) : const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? const Color(0xFFD4A017) : const Color(0xFF90CAF9),
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
              isWarning ? s.guardianRequiredSub : s.guardianHelper,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
    final s = AppStrings.of(context);
    final hasValue = controller.text.trim().isNotEmpty;
    final isEs = s.welcome == 'Bienvenido';
    final deviceLinkedLabel = isEs ? 'Dispositivo vinculado' : 'Linked device';

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
                  hintText: s.guardianNfcUidHint,
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
                '$deviceLinkedLabel: ${controller.text.trim()}',
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
//  Section guardian 2
// ═════════════════════════════════════════════════════════════════════════════
class _Guardian2Section extends StatelessWidget {
  const _Guardian2Section({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.docNumberCtrl,
    required this.uidCtrl,
    required this.emailCtrl,
    required this.selectedDocType,
    required this.relationship,
    required this.requiredForMinor,
    required this.authAccepted,
    required this.signatureStrokes,
    required this.currentStroke,
    required this.scanning,
    required this.onDocTypeChanged,
    required this.onRelationshipChanged,
    required this.onRemove,
    required this.onScanNfc,
    required this.onAuthChanged,
    required this.onPrivacyTap,
    required this.onSignatureStart,
    required this.onSignatureUpdate,
    required this.onSignatureEnd,
    required this.onClearSignature,
    required this.onNfcFieldChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController docNumberCtrl;
  final TextEditingController uidCtrl;
  final TextEditingController emailCtrl;
  final String selectedDocType;
  final String relationship;
  final bool requiredForMinor;
  final bool authAccepted;
  final List<List<Offset>> signatureStrokes;
  final List<Offset>? currentStroke;
  final bool scanning;
  final ValueChanged<String> onDocTypeChanged;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onRemove;
  final VoidCallback onScanNfc;
  final ValueChanged<bool> onAuthChanged;
  final VoidCallback onPrivacyTap;
  final ValueChanged<Offset> onSignatureStart;
  final ValueChanged<Offset> onSignatureUpdate;
  final VoidCallback onSignatureEnd;
  final VoidCallback onClearSignature;
  final VoidCallback onNfcFieldChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';
    final deleteTooltip = isEs ? 'Eliminar guardián 2' : 'Remove guardian 2';
    final docTypes = {'CC': s.docTypeCC, 'CE': s.docTypeCE};

    final rels = {
      '01': s.relParents,
      '02': s.relSiblings,
      '03': s.relUncles,
      '04': s.relGrandparents,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
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
                Text(
                  '${s.editGuardianTitle} 2',
                  style: const TextStyle(
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
                  tooltip: deleteTooltip,
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
                  label: s.guardianFullName,
                  controller: nameCtrl,
                  hint: s.guardianFullNameHint,
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _RelChipSelector(
                  label: s.guardianRelationship,
                  value: relationship,
                  options: rels,
                  onChanged: onRelationshipChanged,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  label: s.guardianPhoneLabel,
                  controller: phoneCtrl,
                  hint: s.guardianPhoneHint,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _DocTypeSelector(
                  label: s.documentTypeLabel,
                  value: selectedDocType,
                  options: docTypes,
                  onChanged: onDocTypeChanged,
                ),
                const SizedBox(height: 12),
                _StyledTextField(
                  label: s.documentNumberLabel,
                  controller: docNumberCtrl,
                  hint: 'Ej. 1234567890',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                FormSectionHeader(
                  icon: Icons.nfc,
                  title: '${s.guardianNfcDevice} 2',
                ),
                const SizedBox(height: 12),
                _NfcField(
                  controller: uidCtrl,
                  scanning: scanning,
                  onScan: onScanNfc,
                  onChanged: onNfcFieldChanged,
                ),
                const SizedBox(height: 16),
                _AuthSection(
                  accepted: authAccepted,
                  emailController: emailCtrl,
                  emailRequired: false,
                  signatureStrokes: signatureStrokes,
                  currentStroke: currentStroke,
                  onAcceptedChanged: onAuthChanged,
                  onPrivacyTap: onPrivacyTap,
                  onSignatureStart: onSignatureStart,
                  onSignatureUpdate: onSignatureUpdate,
                  onSignatureEnd: onSignatureEnd,
                  onClearSignature: onClearSignature,
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
