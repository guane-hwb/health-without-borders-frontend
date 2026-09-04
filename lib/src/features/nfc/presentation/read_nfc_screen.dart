// lib/src/features/nfc/presentation/read_nfc_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/nfc/nfc_guardian_payload.dart';
import '../../../core/nfc/nfc_payload_codec.dart';
import '../../../core/nfc/nfc_payload_service.dart' as payload;
import '../../../core/nfc/nfc_service.dart';
import '../../../core/nfc/nfc_session_manager.dart' show normalizeNfcUid;
import '../../../core/nfc/nfc_triage_payload.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'profile/patient_profile_screen.dart';
import 'shared_read_nfc_header.dart';

/// Read-NFC flow:
///   Step 1 — scan patient wristband (or enter UID manually for testing).
///   Step 2 — only for minors: scan guardian wristband (or enter UID
///   manually). Backend returns 403 with a specific message if the
///   patient is a minor and guardian was not provided.
class ReadNfcScreen extends StatefulWidget {
  const ReadNfcScreen({super.key});

  @override
  State<ReadNfcScreen> createState() => _ReadNfcScreenState();
}

class _ReadNfcScreenState extends State<ReadNfcScreen> {
  // ── Step state ──
  bool _step2 = false; // true after backend asks for guardian

  /// Offline: triage read from the patient wristband, kept while we ask for the
  /// guardian card. Non-null means we are in the offline guardian gate.
  TriageSummary? _offlineTriage;
  bool _offlineGuardianRequired = false;
  bool _scanning = false;
  String? _errorMessage;

  /// Set when a scan found no keyring because the session window closed, so the
  /// offline fallback can say "log in again" rather than blame the chip.
  bool _nfcSessionExpired = false;

  // ── Stored values across steps ──
  String? _patientDeviceUid;

  // ── Form controllers (manual entry — testing in Chrome) ──
  final _patientUidCtrl = TextEditingController();
  final _guardianUidCtrl = TextEditingController();

  @override
  void dispose() {
    NfcService.stopSession();
    _patientUidCtrl.dispose();
    _guardianUidCtrl.dispose();
    super.dispose();
  }

  // ── Patient scan ──────────────────────────────────────────────────────────

  Future<void> _scanPatient() async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    _nfcSessionExpired = false;

    payload.HwbChipReadResult? chip;
    try {
      final authRepository = AppScope.of(context).authRepository;
      final alertMessage = _nfcAlert(guardian: false);
      final keyring = await authRepository.getNfcKeyring();
      if (keyring != null && keyring.isNotEmpty) {
        chip = await payload.NfcPayloadService(
          codec: NfcPayloadCodec.fromKeyring(keyring: keyring),
        ).readHwbChip(alertMessage: alertMessage);
      } else {
        // No keyring: the scan can still resolve the patient online from the
        // chip UID, so only remember the reason for the offline fallback.
        _nfcSessionExpired = await authRepository.isNfcSessionExpired();
      }
    } on payload.NfcNotAvailableException {
      if (mounted) {
        setState(() {
          _scanning = false;
          _errorMessage = AppStrings.of(context).nfcNotAvailableHint;
        });
      }
      return;
    } catch (_) {
      chip = null;
    }

    String uid;
    if (chip != null && chip.uid.isNotEmpty) {
      uid = chip.uid;
    } else {
      try {
        uid = await NfcService.readDeviceUid(
          alertMessage: _nfcAlert(guardian: false),
        );
      } on NfcNotAvailableException {
        if (mounted) {
          setState(() {
            _scanning = false;
            _errorMessage = AppStrings.of(context).nfcNotAvailableHint;
          });
        }
        return;
      } on NfcSessionException catch (e) {
        if (mounted) {
          setState(() {
            _scanning = false;
            _errorMessage = e.message;
          });
        }
        return;
      }
    }

    if (!mounted) return;

    if (chip != null && chip.kind == payload.HwbChipKind.guardian) {
      final s = AppStrings.of(context);
      final isEs = s.isEs;
      setState(() {
        _scanning = false;
        _errorMessage = isEs
            ? 'Esta es la tarjeta del guardián. Escanee primero el dispositivo '
                  'del paciente.'
            : 'This is the guardian card. Scan the patient device first.';
      });
      return;
    }

    _patientUidCtrl.text = uid;
    await _submitPatient(uid, chip: chip);
  }

  Future<void> _submitPatientFromForm() async {
    final uid = _patientUidCtrl.text.trim();
    if (uid.isEmpty) return;
    await _submitPatient(uid);
  }

  Future<void> _submitPatient(
    String deviceUid, {
    payload.HwbChipReadResult? chip,
  }) async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final patient = await AppScope.of(
        context,
      ).patientRepository.scanDevice(deviceUid);
      if (!mounted) return;
      _patientDeviceUid = deviceUid;
      await _openProfile(patient);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && e.message.toLowerCase().contains('guardian')) {
        setState(() {
          _scanning = false;
          _patientDeviceUid = deviceUid;
          _step2 = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _scanning = false;
          _errorMessage = _retiredTagMessage(e) ?? e.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (chip != null && chip.kind == payload.HwbChipKind.triage) {
        final triage = chip.triage;
        _patientDeviceUid = deviceUid;

        if (triage != null && triage.isMinor) {
          setState(() {
            _scanning = false;
            _offlineTriage = triage;
            _offlineGuardianRequired = true;
            _errorMessage = null;
          });
          return;
        }

        final record = NfcGuardianPayload.reconstruct(
          triage: triage,
          guardianRecord: null,
          patientDeviceUid: chip.uid,
        );
        if (!mounted) return;
        await _openProfile(record, readOnly: true, offline: true);
      } else {
        final s = AppStrings.of(context);
        final isEs = s.isEs;
        setState(() {
          _scanning = false;
          _errorMessage = _nfcSessionExpired
              ? (isEs
                    ? 'Sin conexión y su sesión expiró: inicie sesión de nuevo '
                          'para leer el respaldo del chip.'
                    : 'Offline and your session expired: log in again to read '
                          'the chip backup.')
              : (isEs
                    ? 'Sin conexión y sin respaldo legible en el chip.'
                    : 'Offline and no readable backup on the chip.');
        });
      }
    }
  }

  String _nfcAlert({required bool guardian}) {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    if (guardian) {
      return isEs
          ? 'Acerque la tarjeta del guardián'
          : 'Hold the guardian card near the phone';
    }
    return isEs
        ? 'Acerque el dispositivo del paciente'
        : 'Hold the patient device near the phone';
  }

  // ── Offline guardian gate ─────────────────────────────────────────────────

  Future<void> _scanGuardianOffline() async {
    final triage = _offlineTriage;
    if (triage == null) return;

    setState(() {
      _scanning = true;
      _errorMessage = null;
    });

    final s = AppStrings.of(context);
    final isEs = s.isEs;
    try {
      final authRepository = AppScope.of(context).authRepository;
      final keyring = await authRepository.getNfcKeyring();
      if (keyring == null || keyring.isEmpty) {
        final bool expired = await authRepository.isNfcSessionExpired();
        throw NfcSessionException(
          expired
              ? (isEs
                    ? 'Su sesión expiró. Inicie sesión de nuevo para leer '
                          'dispositivos NFC.'
                    : 'Your session expired. Log in again to read NFC devices.')
              : (isEs ? 'No hay llave NFC disponible.' : 'No NFC key available.'),
        );
      }
      final chip = await payload.NfcPayloadService(
        codec: NfcPayloadCodec.fromKeyring(keyring: keyring),
      ).readHwbChip(alertMessage: _nfcAlert(guardian: true));
      if (!mounted) return;

      final expected = <String>[
        triage.guardianDeviceUid,
        if (triage.guardian2DeviceUid != null) triage.guardian2DeviceUid!,
      ].where((String u) => u.trim().isNotEmpty).map(normalizeNfcUid).toSet();

      if (expected.isEmpty || !expected.contains(normalizeNfcUid(chip.uid))) {
        setState(() {
          _scanning = false;
          _errorMessage = isEs
              ? 'Esa tarjeta no corresponde al guardián de este paciente.'
              : 'That card does not belong to this patient\'s guardian.';
        });
        return;
      }

      if (chip.kind != payload.HwbChipKind.guardian ||
          chip.guardianRecord == null) {
        setState(() {
          _scanning = false;
          _errorMessage = isEs
              ? 'La tarjeta del guardián está vacía o no se pudo leer.'
              : 'The guardian card is blank or could not be read.';
        });
        return;
      }

      final record = NfcGuardianPayload.reconstruct(
        triage: triage,
        guardianRecord: chip.guardianRecord,
        patientDeviceUid: _patientDeviceUid ?? '',
      );
      if (!mounted) return;
      await _openProfile(record, readOnly: true, offline: true);
    } on NfcNotAvailableException {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = AppStrings.of(context).nfcNotAvailableHint;
      });
    } on NfcSessionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = isEs
            ? 'No se pudo leer la tarjeta del guardián.'
            : 'Could not read the guardian card.';
      });
    }
  }

  /// If [e] is the backend's 410 "device retired" response, returns a localized
  /// message naming the retirement reason (lost / damaged / replaced). Returns
  /// null for any other error so the caller falls back to the generic text.
  String? _retiredTagMessage(ApiException e) {
    if (e.statusCode != 410) return null;
    final Object? detail = e.detail;
    if (detail is! Map || detail['code'] != 'device_retired') return null;

    final bool isEs = AppStrings.of(context).isEs;
    final String? reason = detail['reason']?.toString();
    final String reasonLabel = switch (reason) {
      'lost' => isEs ? 'perdida' : 'lost',
      'damaged' => isEs ? 'dañada' : 'damaged',
      'replaced' => isEs ? 'reemplazada' : 'replaced',
      _ => isEs ? 'retirada' : 'retired',
    };
    return isEs
        ? 'Este dispositivo fue retirado ($reasonLabel) y ya no pertenece a HWB.'
        : 'This device was retired ($reasonLabel) and no longer belongs to HWB.';
  }

  Future<void> _confirmEmergencyAccess() async {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(isEs ? 'Acceso de emergencia' : 'Emergency access'),
        content: Text(
          isEs
              ? 'Va a ver datos de un menor sin la autorización del guardián. '
                    'Este acceso queda registrado. ¿Continuar?'
              : 'You are about to view a minor\'s data without the guardian\'s '
                    'authorisation. This access is logged. Continue?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isEs ? 'Continuar' : 'Continue',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _emergencyAccess();
  }

  Future<void> _emergencyAccess() async {
    final triage = _offlineTriage;
    if (triage == null) return;

    final scope = AppScope.of(context);
    await scope.localDatabase.logEmergencyAccess(
      patientUid: _patientDeviceUid ?? '',
      patientName: '${triage.firstName} ${triage.lastName}'.trim(),
      userId: scope.authRepository.currentUser?.id,
    );

    final record = NfcGuardianPayload.reconstruct(
      triage: triage,
      guardianRecord: null,
      patientDeviceUid: _patientDeviceUid ?? '',
    );
    if (!mounted) return;
    await _openProfile(record, readOnly: true, offline: true, emergency: true);
  }

  // ── Guardian scan ─────────────────────────────────────────────────────────

  Future<void> _scanGuardian() async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final uid = await NfcService.readDeviceUid(
        alertMessage: _nfcAlert(guardian: true),
      );
      _guardianUidCtrl.text = uid;
      await _submitGuardian(uid);
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() {
          _scanning = false;
          _errorMessage = AppStrings.of(context).nfcNotAvailableHint;
        });
      }
    } on NfcSessionException catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _submitGuardianFromForm() async {
    final uid = _guardianUidCtrl.text.trim();
    if (uid.isEmpty) return;
    await _submitGuardian(uid);
  }

  Future<void> _submitGuardian(String guardianUid) async {
    if (_patientDeviceUid == null) return;
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final patient = await AppScope.of(context).patientRepository.scanDevice(
        _patientDeviceUid!,
        guardianDeviceUid: guardianUid,
      );
      if (!mounted) return;
      await _openProfile(patient);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = _retiredTagMessage(e) ?? e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openProfile(
    PatientFullRecord patient, {
    bool readOnly = false,
    bool offline = false,
    bool emergency = false,
  }) async {
    setState(() => _scanning = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientProfileScreen(
          patient: patient,
          readOnly: readOnly,
          offline: offline,
          emergency: emergency,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _step2 = false;
        _patientDeviceUid = null;
        _patientUidCtrl.clear();
        _guardianUidCtrl.clear();
        _errorMessage = null;
      });
    }
  }

  void _backToStep1() {
    setState(() {
      _step2 = false;
      _guardianUidCtrl.clear();
      _errorMessage = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: (_step2 || _offlineGuardianRequired)
                      ? s.scanGuardianTitle
                      : s.readWristbandTitle,
                  onBack: _step2
                      ? _backToStep1
                      : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _offlineGuardianRequired
                      ? _buildOfflineGuardianGate(s)
                      : (_step2 ? _buildGuardianStep(s) : _buildPatientStep(s)),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Patient ──────────────────────────────────────────────────────

  Widget _buildPatientStep(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Column(
        children: [
          _NfcButton(
            scanning: _scanning,
            onTap: _scanning ? null : _scanPatient,
          ),
          const SizedBox(height: 28),
          Text(
            s.scanPatientHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.scanPatientHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: 28),

          _ManualUidPanel(
            label: s.manualPatientUidLabel,
            hint: s.manualPatientUidHint,
            controller: _patientUidCtrl,
            onSubmit: _scanning ? null : _submitPatientFromForm,
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineGuardianGate(AppStrings s) {
    final isEs = s.isEs;
    final triage = _offlineTriage;
    final name = triage == null
        ? ''
        : '${triage.firstName} ${triage.lastName}'.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.patientWristbandReady,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _NfcButton(
            scanning: _scanning,
            onTap: _scanning ? null : _scanGuardianOffline,
            color: AppColors.accent,
          ),
          const SizedBox(height: 28),
          Text(
            s.scanGuardianHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEs
                ? '$name es menor de edad. Se requiere la tarjeta del guardián '
                      'para ver la historia completa.'
                : '$name is a minor. The guardian card is required to see the '
                      'full record.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.35,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _scanning ? null : _confirmEmergencyAccess,
                    icon: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                    label: Text(
                      isEs ? 'Acceso de emergencia' : 'Emergency access',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEs
                      ? 'Muestra solo alergias, tipo de sangre y condiciones '
                            'crónicas. Queda registrado.'
                      : 'Shows only allergies, blood type and chronic '
                            'conditions. It is logged.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianStep(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  s.patientWristbandReady,
                  style: const TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _NfcButton(
            scanning: _scanning,
            onTap: _scanning ? null : _scanGuardian,
            color: AppColors.accent,
          ),
          const SizedBox(height: 28),
          Text(
            s.scanGuardianHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: 28),

          _ManualUidPanel(
            label: s.manualGuardianUidLabel,
            hint: s.manualGuardianUidHint,
            controller: _guardianUidCtrl,
            onSubmit: _scanning ? null : _submitGuardianFromForm,
          ),
        ],
      ),
    );
  }
}

class _NfcButton extends StatelessWidget {
  const _NfcButton({
    required this.scanning,
    required this.onTap,
    this.color = const Color(0xFFFB8C00),
  });

  final bool scanning;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: scanning
                ? const Center(
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.wifi, size: 50, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _ManualUidPanel extends StatelessWidget {
  const _ManualUidPanel({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onSubmit,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.keyboard_outlined,
                size: 16,
                color: AppColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.white,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: onSubmit,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Text(
                AppStrings.of(context).useManualUid,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
