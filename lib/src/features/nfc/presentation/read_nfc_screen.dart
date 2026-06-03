// lib/src/features/nfc/presentation/read_nfc_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/nfc/nfc_service.dart';
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
  bool _scanning = false;
  String? _errorMessage;

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
    try {
      final uid = await NfcService.readDeviceUid();
      _patientUidCtrl.text = uid;
      await _submitPatient(uid);
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

  Future<void> _submitPatientFromForm() async {
    final uid = _patientUidCtrl.text.trim();
    if (uid.isEmpty) return;
    await _submitPatient(uid);
  }

  Future<void> _submitPatient(String deviceUid) async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final patient = await AppScope.of(
        context,
      ).patientRepository.scanDevice(deviceUid);
      if (!mounted) return;
      // Adult patient — go directly to profile
      _patientDeviceUid = deviceUid;
      await _openProfile(patient);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 403 + guardian-required → switch to step 2
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
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ── Guardian scan ─────────────────────────────────────────────────────────

  Future<void> _scanGuardian() async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
    });
    try {
      final uid = await NfcService.readDeviceUid();
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
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openProfile(PatientFullRecord patient) async {
    setState(() => _scanning = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientProfileScreen(patient: patient),
      ),
    );
    // After returning from profile, reset the screen
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
                  title: _step2 ? s.scanGuardianTitle : s.readWristbandTitle,
                  onBack: _step2
                      ? _backToStep1
                      : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _step2 ? _buildGuardianStep(s) : _buildPatientStep(s),
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

          // ── Manual UID input (Chrome / no NFC) ─────────────────
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

  // ── Step 2: Guardian ─────────────────────────────────────────────────────

  Widget _buildGuardianStep(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Patient confirmed pill
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

          // ── Manual UID input ──────────────────────
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

// ═════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

/// Pulsating NFC button with circular progress when scanning.
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
          // Outer halo
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
          // Main orange circle
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

/// Expandable panel with manual UID textbox + confirm button.
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
