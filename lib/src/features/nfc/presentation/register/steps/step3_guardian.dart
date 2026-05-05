// lib/src/features/nfc/presentation/register/steps/step3_guardian.dart
import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../../../shared/widgets/form_widgets.dart';
import '../register_nfc_screen.dart';

class Step3Guardian extends StatefulWidget {
  const Step3Guardian({
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
  State<Step3Guardian> createState() => _Step3State();
}

class _Step3State extends State<Step3Guardian> {
  late final _name = TextEditingController(
    text: widget.draft.guardianName ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.draft.guardianPhone ?? '',
  );
  late final _uid = TextEditingController(
    text: widget.draft.guardianDeviceUid ?? '',
  );
  bool _scanning = false;
  String? _err;

  static const _rels = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _uid.dispose();
    super.dispose();
  }

  Future<void> _scanNfc() async {
    setState(() => _scanning = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted)
        setState(() {
          _uid.text = uid;
          _scanning = false;
        });
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC no disponible. Use el campo manual.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _save() {
    if (widget.requiredForMinor) {
      final missing = <String>[];
      if (_name.text.trim().isEmpty) missing.add('Nombre');
      if (_phone.text.trim().isEmpty) missing.add('Teléfono');
      if (missing.isNotEmpty) {
        setState(() => _err = 'Campos requeridos: ${missing.join(', ')}');
        return;
      }
    }
    final d = widget.draft;
    d.guardianName = _name.text.trim().isEmpty ? null : _name.text.trim();
    d.guardianPhone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    d.guardianDeviceUid = _uid.text.trim().isEmpty ? null : _uid.text.trim();
    widget.onContinue();
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
              // Notice banner
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: widget.requiredForMinor
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.requiredForMinor
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      size: 16,
                      color: widget.requiredForMinor
                          ? const Color(0xFFB8800F)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.requiredForMinor
                            ? 'El paciente es menor de 18 años. El guardián es obligatorio (Ley 1098/2006).'
                            : 'Opcional para adultos. Si lo registra, podrá ser usado como contacto de emergencia.',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.requiredForMinor
                              ? const Color(0xFF7A5500)
                              : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FormSectionHeader(
                icon: Icons.family_restroom,
                title: 'Información del guardián',
              ),
              LabeledTextField(
                label: 'NOMBRE COMPLETO',
                controller: _name,
                hint: 'Ej. Carmen Vargas Pinto',
                requiredField: widget.requiredForMinor,
              ),
              const SizedBox(height: 12),
              ChipSelector<String>(
                label: 'PARENTESCO',
                value: d.guardianRelationship ?? '01',
                options: _rels,
                onChanged: (v) => setState(() => d.guardianRelationship = v),
                requiredField: widget.requiredForMinor,
              ),
              const SizedBox(height: 12),
              LabeledTextField(
                label: 'TELÉFONO',
                controller: _phone,
                hint: '+57 310 482 9914',
                keyboardType: TextInputType.phone,
                requiredField: widget.requiredForMinor,
              ),
              const SizedBox(height: 18),
              FormSectionHeader(
                icon: Icons.nfc,
                title: 'Dispositivo NFC del guardián',
                subtitle:
                    'Necesaria para autenticación 2FA al consultar el historial de menores.',
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _uid,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'UID del dispositivo NFC',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.disabled,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.family_restroom,
                          size: 18,
                          color: _uid.text.trim().isNotEmpty
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE3E5EA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _scanning ? null : _scanNfc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.disabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 0,
                      ),
                      child: _scanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.nfc,
                              size: 22,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ],
              ),
              if (_err != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
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
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: const Text(
                      'Atrás',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
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
