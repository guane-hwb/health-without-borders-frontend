import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/nfc/nfc_payload_service.dart';
import '../../../core/nfc/nfc_session_manager.dart';
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

/// Shows the same guided bottom sheet as [showNfcGuidedWrite], but labeled for a
/// *read* (verify) step: "Reading… / Read / Could not read" instead of the
/// write wording. Use for steps that only inspect a tag (e.g. verifying a new
/// blank tag before writing).
///
/// Returns true if the read completed, false if the user skipped or dismissed.
Future<bool> showNfcGuidedRead(
  BuildContext context, {
  required String title,
  required String instruction,
  required ChipWriteAction read,
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
      write: read,
      readMode: true,
    ),
  );
  return ok ?? false;
}

enum _Step { prompt, writing, success, error }

/// Why a write failed, so the sheet can say something the clinician can act on.
///
/// Before the session manager existed there was nothing to distinguish: the
/// radio never reported errors on Android, so every failure — including "no
/// chip ever arrived" — surfaced as an indefinite spinner.
enum _Failure {
  /// Right flow, wrong chip.
  mismatch,

  /// No chip arrived before the timeout.
  timeout,

  /// A chip is parked on the antenna. Android will not re-poll it, so the tap
  /// has to be redone rather than waited out.
  alreadyPresent,

  /// The data does not fit this chip. Carries the numbers.
  tooLarge,

  /// NFC is switched off in system settings.
  nfcOff,

  /// Anything else: transceive error, chip left the field, locked chip.
  generic,
}

class _NfcGuidedWriteSheet extends StatefulWidget {
  const _NfcGuidedWriteSheet({
    required this.title,
    required this.instruction,
    required this.write,
    this.readMode = false,
  });

  final String title;
  final String instruction;
  final ChipWriteAction write;

  /// When true, the sheet is labeled for a read/verify step rather than a write.
  final bool readMode;

  @override
  State<_NfcGuidedWriteSheet> createState() => _NfcGuidedWriteSheetState();
}

class _NfcGuidedWriteSheetState extends State<_NfcGuidedWriteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _Step _step = _Step.prompt;
  _Failure _failure = _Failure.generic;
  NfcPayloadTooLargeException? _tooLarge;

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

  /// Releases the radio's pending caller. The write's future then completes
  /// with [NfcCancelledException] and [_run] pops the sheet.
  ///
  /// A no-op once the chip is in hand: the manager will not abort a transceive
  /// half-way through, which is what we want — a partially written chip is
  /// worse than a slow one.
  void _cancel() => NfcSessionManager.instance.cancelPending();

  void _fail(_Failure failure, {NfcPayloadTooLargeException? tooLarge}) {
    if (!mounted) return;
    setState(() {
      _step = _Step.error;
      _failure = failure;
      _tooLarge = tooLarge;
    });
  }

  Future<void> _run() async {
    setState(() => _step = _Step.writing);
    try {
      await widget.write();
      if (!mounted) return;
      setState(() => _step = _Step.success);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop(true);
    } on NfcCancelledException {
      // The user backed out or hit Cancel; that is not an error to report.
      if (mounted) Navigator.of(context).pop(false);
    } on NfcInterruptedException {
      if (mounted) Navigator.of(context).pop(false);
    } on NfcUidMismatchException {
      _fail(_Failure.mismatch);
    } on NfcTimeoutException {
      _fail(_Failure.timeout);
    } on NfcTagAlreadyPresentException {
      _fail(_Failure.alreadyPresent);
    } on NfcPayloadTooLargeException catch (e) {
      _fail(_Failure.tooLarge, tooLarge: e);
    } on NfcDisabledException {
      _fail(_Failure.nfcOff);
    } catch (_) {
      _fail(_Failure.generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    // Back is allowed at every step, but while a chip is being waited on it has
    // to go through _cancel() rather than tearing the sheet down: popping used
    // to leave the radio's caller registered forever, so the *next* sheet — the
    // guardian's — could never get the radio and hung too.
    return PopScope(
      canPop: _step != _Step.writing,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _cancel();
      },
      child: SafeArea(
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
      ),
    );
  }

  Widget _nfcCircle() {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.92,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
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
        widget.readMode
            ? (isEs
                  ? 'Leyendo… mantenga el dispositivo cerca'
                  : 'Reading… keep the device close')
            : (isEs
                  ? 'Grabando… mantenga el dispositivo cerca'
                  : 'Writing… keep the device close'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _cancel,
        child: Text(
          isEs ? 'Cancelar' : 'Cancel',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );

  Widget _buildSuccess(bool isEs) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle, size: 72, color: AppColors.success),
      const SizedBox(height: 14),
      Text(
        widget.readMode
            ? (isEs ? 'Leído' : 'Read')
            : (isEs ? 'Grabado' : 'Written'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
    ],
  );

  String _failureText(bool isEs) {
    switch (_failure) {
      case _Failure.mismatch:
        return isEs
            ? 'Ese no es el dispositivo registrado para este paciente'
            : 'That is not the device registered for this patient';
      case _Failure.timeout:
        return isEs
            ? 'No se detectó ningún dispositivo. Acérquelo al lector e intente '
                  'de nuevo.'
            : 'No device detected. Hold it against the reader and try again.';
      case _Failure.alreadyPresent:
        return isEs
            ? 'Retire el dispositivo y vuelva a acercarlo.'
            : 'Lift the device away and tap it again.';
      case _Failure.tooLarge:
        final e = _tooLarge;
        if (e == null) {
          return isEs ? 'No se pudo grabar' : 'Could not write';
        }
        return isEs
            ? 'Los datos no caben en este chip: necesita ${e.messageBytes} '
                  'bytes y el chip guarda ${e.chipCapacity}.'
            : 'The data does not fit this chip: it needs ${e.messageBytes} '
                  'bytes and the chip holds ${e.chipCapacity}.';
      case _Failure.nfcOff:
        return isEs
            ? 'El NFC está apagado. Actívelo en los ajustes del teléfono.'
            : 'NFC is turned off. Enable it in system settings.';
      case _Failure.generic:
        if (widget.readMode) {
          return isEs ? 'No se pudo leer' : 'Could not read';
        }
        return isEs ? 'No se pudo grabar' : 'Could not write';
    }
  }

  Widget _buildError(bool isEs) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.gpp_bad_rounded, size: 72, color: AppColors.error),
      const SizedBox(height: 14),
      Text(
        _failureText(isEs),
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
