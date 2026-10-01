// lib/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/guardian_identity.dart';
import '../../../domain/patient_record.dart';

const _kEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
);
const _kFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.primary, width: 2),
);
const _kErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(color: AppColors.error, width: 1.5),
);
const _kInputStyle = TextStyle(
  fontSize: 15,
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w500,
);

class EditGuardianSheet extends StatefulWidget {
  const EditGuardianSheet({
    super.key,
    required this.guardian,
    required this.guardianIndex,
    required this.onConfirm,
  });

  final GuardianInfo guardian;
  final int guardianIndex;
  final ValueChanged<GuardianInfo> onConfirm;

  @override
  State<EditGuardianSheet> createState() => _EditGuardianSheetState();
}

class _EditGuardianSheetState extends State<EditGuardianSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _docNumberCtrl;
  late TextEditingController _emailCtrl;
  late String _relationship;
  late String _selectedDocType;

  late final String _initialName;
  late final String _initialPhone;
  late final String _initialDocNumber;
  late final String _initialRelationship;
  late final String _initialDocType;

  bool _authAccepted = false;
  final List<List<Offset>> _signatureStrokes = [];
  List<Offset>? _currentStroke;
  String? _authErrorMsg;

  static const List<String> _relationshipCodes = ['01', '02', '03', '04'];

  String _relationshipLabel(AppStrings s, String code) {
    switch (code) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return code;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialName = widget.guardian.name;
    _initialPhone = widget.guardian.phone;
    _initialDocNumber =
        widget.guardian.docNumber ?? widget.guardian.documentNumber ?? '';
    _initialRelationship = widget.guardian.relationship;
    _initialDocType =
        widget.guardian.docType ?? widget.guardian.documentType ?? 'CC';

    _nameCtrl = TextEditingController(text: _initialName);
    _phoneCtrl = TextEditingController(text: _initialPhone);
    _docNumberCtrl = TextEditingController(text: _initialDocNumber);
    _emailCtrl = TextEditingController();
    _relationship = _initialRelationship;
    _selectedDocType = _initialDocType;

    _nameCtrl.addListener(_onFieldChanged);
    _docNumberCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _docNumberCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _docNumberCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _isIdentityChanged {
    final nameChanged = _nameCtrl.text.trim() != _initialName;
    final docNumChanged = _docNumberCtrl.text.trim() != _initialDocNumber;
    return nameChanged && docNumChanged;
  }

  bool get _hasUnsavedChanges {
    final nameChanged = _nameCtrl.text.trim() != _initialName;
    final phoneChanged = _phoneCtrl.text.trim() != _initialPhone;
    final docNumChanged = _docNumberCtrl.text.trim() != _initialDocNumber;
    final relChanged = _relationship != _initialRelationship;
    final docTypeChanged = _selectedDocType != _initialDocType;

    return nameChanged ||
        phoneChanged ||
        docNumChanged ||
        relChanged ||
        docTypeChanged ||
        _authAccepted ||
        _signatureStrokes.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final s = AppStrings.of(context);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          s.unsyncedChangesTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          s.exitWithoutSyncMsg,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.exit, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _handleClose() async {
    if (await _onWillPop() && mounted) {
      Navigator.of(context).pop();
    }
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

  void _submitSave() {
    setState(() => _authErrorMsg = null);

    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    final s = AppStrings.of(context);
    final isEs = s.isEs;

    if (_isIdentityChanged && (_authAccepted || _signatureStrokes.isNotEmpty)) {
      final missing = <String>[];
      if (!_authAccepted) {
        missing.add(
          isEs
              ? 'Autorización de política de privacidad'
              : 'Privacy policy authorization',
        );
      }
      if (_signatureStrokes.isEmpty) {
        missing.add(isEs ? 'Firma biométrica' : 'Biometric signature');
      }

      if (missing.isNotEmpty) {
        setState(() {
          _authErrorMsg = isEs
              ? 'Campos requeridos: ${missing.join(', ')}'
              : 'Required fields: ${missing.join(', ')}';
        });
        return;
      }
    }

    final edited = GuardianInfo(
      name: _nameCtrl.text.trim(),
      relationship: _relationship,
      phone: _phoneCtrl.text.trim(),
      docType: _selectedDocType,
      docNumber: _docNumberCtrl.text.trim().isEmpty
          ? null
          : _docNumberCtrl.text.trim(),
      deviceUid: widget.guardian.deviceUid,
    );

    widget.onConfirm(
      edited.copyWith(
        consent: isSameGuardian(widget.guardian, edited)
            ? widget.guardian.consent
            : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final docTypes = {'CC': s.docTypeCC, 'CE': s.docTypeCE};

    final dynamicTitle = widget.guardianIndex == 1
        ? (isEs ? 'Editar Guardián Principal' : 'Edit Primary Guardian')
        : (isEs ? 'Editar Guardián Secundario' : 'Edit Secondary Guardian');

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _handleClose();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dynamicTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _handleClose,
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.divider,
                  ),

                  _ValidatedField(
                    label: s.guardianFullName,
                    controller: _nameCtrl,
                    hint: s.guardianFullNameHint,
                    prefixIcon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El nombre del guardián es obligatorio'
                            : 'Guardian name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _LabelText(text: s.guardianRelationship),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _relationshipCodes.map((code) {
                      final sel = _relationship == code;
                      return GestureDetector(
                        onTap: () => setState(() => _relationship = code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            _relationshipLabel(s, code),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: s.guardianPhoneLabel,
                    controller: _phoneCtrl,
                    hint: s.guardianPhoneHint,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El teléfono es obligatorio'
                            : 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _DocTypeSelector(
                    label: s.documentTypeLabel,
                    value: _selectedDocType,
                    options: docTypes,
                    onChanged: (v) => setState(() => _selectedDocType = v),
                  ),
                  const SizedBox(height: 14),

                  _ValidatedField(
                    label: s.documentNumberLabel,
                    controller: _docNumberCtrl,
                    hint: 'Ej. 1234567890',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEs
                            ? 'El documento es obligatorio'
                            : 'Document number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_isIdentityChanged) ...[
                    _AuthSection(
                      accepted: _authAccepted,
                      emailController: _emailCtrl,
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
                    const SizedBox(height: 14),
                  ],

                  if (_authErrorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _authErrorMsg!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _submitSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      label: Text(
                        s.confirmChanges,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  const _ValidatedField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(text: label),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: _kInputStyle,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: _kEnabledBorder,
            focusedBorder: _kFocusedBorder,
            errorBorder: _kErrorBorder,
            focusedErrorBorder: _kErrorBorder,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocTypeSelector extends StatefulWidget {
  const _DocTypeSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_DocTypeSelector> createState() => _DocTypeSelectorState();
}

class _DocTypeSelectorState extends State<_DocTypeSelector> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.options[widget.value] ?? '';
    const itemHeight = 48.0;
    final calculatedHeight = (widget.options.length * itemHeight).clamp(
      itemHeight,
      250.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(text: widget.label),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              controller: _menuController,
              style: MenuStyle(
                fixedSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, calculatedHeight),
                ),
                maximumSize: WidgetStateProperty.all(
                  Size(constraints.maxWidth, calculatedHeight),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: _kEnabledBorder,
                      focusedBorder: _kFocusedBorder,
                      border: _kEnabledBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedLabel,
                                  style: _kInputStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
              menuChildren: widget.options.entries.map((e) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: itemHeight,
                  child: MenuItemButton(
                    onPressed: () {
                      widget.onChanged(e.key);
                      _menuController.close();
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: _kInputStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

class _LabelText extends StatelessWidget {
  const _LabelText({required this.text, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text.replaceAll('*', '').trim(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

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
    final isEs = s.isEs;
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
          _LabelText(text: s.confirmChanges, required: true),
          const SizedBox(height: 14),

          _AuthCheckbox(
            accepted: accepted,
            onChanged: onAcceptedChanged,
            onPrivacyTap: onPrivacyTap,
          ),
          const SizedBox(height: 16),

          _ValidatedField(
            label: s.email,
            controller: emailController,
            hint: s.emailHint,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          _LabelText(text: signatureLabel, required: true),
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
    final isEs = s.isEs;

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
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
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
    final isEs = s.isEs;

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

class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;

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
