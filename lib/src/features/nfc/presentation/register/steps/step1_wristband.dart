// lib/src/features/nfc/presentation/register/steps/step1_wristband.dart
import 'package:flutter/material.dart';
import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../register_nfc_screen.dart';

class Step1Wristband extends StatefulWidget {
  const Step1Wristband({
    super.key,
    required this.draft,
    required this.onContinue,
  });
  final RegisterDraft draft;
  final VoidCallback onContinue;
  @override
  State<Step1Wristband> createState() => _Step1WristbandState();
}

class _Step1WristbandState extends State<Step1Wristband> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.draft.deviceUid ?? '',
  );
  bool _scanning = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final uid = await NfcService.readDeviceUid();
      _ctrl.text = uid;
      widget.draft.deviceUid = uid;
      if (mounted) setState(() => _scanning = false);
    } on NfcNotAvailableException {
      if (mounted)
        setState(() {
          _scanning = false;
          _error = 'NFC no disponible. Use el campo manual.';
        });
    } on NfcSessionException catch (e) {
      if (mounted)
        setState(() {
          _scanning = false;
          _error = e.message;
        });
    }
  }

  void _accept() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      setState(
        () => _error = 'Debe escanear o ingresar el UID del dispositivo NFC.',
      );
      return;
    }
    widget.draft.deviceUid = v;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const Text(
          'Dispositivo NFC del paciente',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Acerque el dispositivo NFC o ingrese el UID manualmente.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        // NFC button
        Center(
          child: GestureDetector(
            onTap: _scanning ? null : _scan,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _scanning
                      ? const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.nfc, size: 42, color: AppColors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        // Manual UID
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E5EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.keyboard_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'UID manual del paciente (testing)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Ej. HWB-04:1A:2C:DE',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.disabled,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE3E5EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (v) => widget.draft.deviceUid = v.trim(),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
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
                    _error!,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.arrow_forward,
              color: AppColors.white,
              size: 20,
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
      ],
    );
  }
}
