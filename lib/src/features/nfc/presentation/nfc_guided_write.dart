import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/nfc/nfc_payload_service.dart';
import '../../../design/tokens/app_colors.dart';

/// The write operation for a single chip. Should throw
/// [NfcUidMismatchException] on a wrong-device tap, or any other exception on
/// failure.
typedef ChipWriteAction = Future<void> Function();

/// Shows a guided bottom sheet that walks the user through writing one NFC
/// chip: prompt to tap → writing → success, with retry/skip on failure.
///
/// Returns true if the chip was written, false if the user skipped (or
/// dismissed). Modeled on the visual language of [showNfcSaveFlow].
Future<bool> showNfcGuidedWrite(
  BuildContext context, {
  required String title,
  required String instruction,
  required ChipWriteAction write,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _NfcGuidedWriteSheet(
      title: title,
      instruction: instruction,
      write: write,
    ),
  );
  return ok ?? false;
}

enum _Step { prompt, writing, success, error }

class _NfcGuidedWriteSheet extends StatefulWidget {
  const _NfcGuidedWriteSheet({
    required this.title,
    required this.instruction,
    required this.write,
  });

  final String title;
  final String instruction;
  final ChipWriteAction write;

  @override
  State<_NfcGuidedWriteSheet> createState() => _NfcGuidedWriteSheetState();
}

class _NfcGuidedWriteSheetState extends State<_NfcGuidedWriteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _Step _step = _Step.prompt;
  bool _mismatch = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _step = _Step.writing);
    try {
      await widget.write();
      if (!mounted) return;
      setState(() => _step = _Step.success);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop(true);
    } on NfcUidMismatchException {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _mismatch = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _mismatch = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = AppStrings.of(context).welcome == 'Bienvenido';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            switch (_step) {
              _Step.prompt => _buildPrompt(isEs),
              _Step.writing => _buildWriting(isEs),
              _Step.success => _buildSuccess(isEs),
              _Step.error => _buildError(isEs),
            },
          ],
        ),
      ),
    );
  }

  Widget _nfcCircle() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          color: AppColors.primary.withValues(alpha: 0.06),
        ),
        child: const Icon(Icons.nfc, size: 46, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPrompt(bool isEs) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nfcCircle(),
          const SizedBox(height: 18),
          Text(
            widget.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEs ? 'Empezar' : 'Start',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              isEs ? 'Omitir' : 'Skip',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );

  Widget _buildWriting(bool isEs) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEs
                ? 'Grabando… mantenga el dispositivo cerca'
                : 'Writing… keep the device close',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
        ],
      );

  Widget _buildSuccess(bool isEs) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 72, color: AppColors.success),
          const SizedBox(height: 14),
          Text(
            isEs ? 'Grabado' : 'Written',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
      );

  Widget _buildError(bool isEs) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gpp_bad_rounded, size: 72, color: AppColors.error),
          const SizedBox(height: 14),
          Text(
            _mismatch
                ? (isEs
                    ? 'Ese no es el dispositivo registrado para este paciente'
                    : 'That is not the device registered for this patient')
                : (isEs ? 'No se pudo grabar' : 'Could not write'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEs ? 'Omitir' : 'Skip'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _run,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEs ? 'Reintentar' : 'Retry',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
