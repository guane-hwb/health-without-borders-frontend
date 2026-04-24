import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'read_nfc_guardian_screen.dart';
import 'shared_read_nfc_header.dart';

class ReadNfcScreen extends StatefulWidget {
  const ReadNfcScreen({super.key});

  @override
  State<ReadNfcScreen> createState() => _ReadNfcScreenState();
}

enum _ScanState { idle, scanning, guardianRequired, success, error }

class _ReadNfcScreenState extends State<ReadNfcScreen> {
  _ScanState _state = _ScanState.idle;
  PatientFullRecord? _patient;
  String? _errorMessage;
  String? _lastDeviceUid;
  bool _nfcAvailable = true;

  // Fallback manual UID entry
  final TextEditingController _uidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcService.isAvailable;
    if (mounted) setState(() => _nfcAvailable = available);
  }

  @override
  void dispose() {
    NfcService.stopSession();
    _uidCtrl.dispose();
    super.dispose();
  }

  // ── NFC scan flow ─────────────────────────────────────────────────────────

  Future<void> _startNfcScan() async {
    setState(() {
      _state = _ScanState.scanning;
      _errorMessage = null;
      _patient = null;
    });

    try {
      final String uid = await NfcService.readDeviceUid();
      _lastDeviceUid = uid;
      _uidCtrl.text = uid;
      await _fetchPatient(uid);
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'NFC is not available on this device. Use manual entry.';
          _nfcAvailable = false;
        });
      }
    } on NfcSessionException catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _fetchPatient(String deviceUid, {String? guardianUid}) async {
    setState(() {
      _state = _ScanState.scanning;
      _errorMessage = null;
    });

    try {
      final patient = await AppScope.of(context)
          .patientRepository
          .scanDevice(deviceUid, guardianDeviceUid: guardianUid);
      if (mounted) {
        setState(() {
          _patient = patient;
          _state = _ScanState.success;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 403 &&
            e.message.contains('Guardian bracelet scan required')) {
          setState(() => _state = _ScanState.guardianRequired);
        } else {
          setState(() {
            _state = _ScanState.error;
            _errorMessage = e.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Guardian 2FA: scan the guardian's wristband and retry the patient lookup.
  Future<void> _scanGuardianAndRetry() async {
    setState(() => _state = _ScanState.scanning);

    try {
      final String guardianUid = await NfcService.readDeviceUid();
      await _fetchPatient(_lastDeviceUid!, guardianUid: guardianUid);
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'NFC not available for guardian scan.';
        });
      }
    } on NfcSessionException catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'Guardian scan failed: ${e.message}';
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F7),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SharedReadNfcHeader(),
                Padding(
                  padding: const EdgeInsets.only(left: 21, top: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 33,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A396),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.arrow_back_ios,
                            size: 15, color: AppColors.white),
                        label: const Text('Back',
                            style: TextStyle(
                                color: AppColors.white, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Manual UID entry + NFC button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _uidCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _nfcAvailable
                                ? 'Tap NFC button or enter UID'
                                : 'Enter device UID manually',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.disabled),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // NFC scan button
                      if (_nfcAvailable)
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed:
                                _state == _ScanState.scanning ? null : _startNfcScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.disabled,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.nfc,
                                color: AppColors.white, size: 22),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Manual search button
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _state == _ScanState.scanning
                              ? null
                              : () {
                                  if (_uidCtrl.text.isNotEmpty) {
                                    _lastDeviceUid = _uidCtrl.text.trim();
                                    _fetchPatient(_lastDeviceUid!);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            disabledBackgroundColor: AppColors.disabled,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Icon(Icons.search,
                              color: AppColors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Container(
                      width: 347,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40000000), blurRadius: 10),
                        ],
                      ),
                      child: _buildCardContent(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
            const Positioned(
              left: 116, right: 116, bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    switch (_state) {
      case _ScanState.idle:
        return _centerContent(
          icon: Icons.nfc_rounded,
          iconColor: AppColors.primary.withValues(alpha: 0.5),
          title: _nfcAvailable
              ? 'Tap the NFC button to\nscan a wristband'
              : 'Enter a device UID\nand tap Search',
          subtitle: 'Ready to scan',
        );

      case _ScanState.scanning:
        return _centerContent(
          icon: Icons.nfc_rounded,
          iconColor: AppColors.primary,
          title: 'Scanning...',
          subtitle: 'Hold the wristband near the device',
          showSpinner: true,
        );

      case _ScanState.guardianRequired:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 80, color: AppColors.secondary),
            const SizedBox(height: 16),
            const Text(
              'Guardian verification required',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'This patient is a minor. Please scan the guardian\'s wristband to access the record.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240, height: 40,
              child: ElevatedButton.icon(
                onPressed: _scanGuardianAndRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.nfc, size: 20, color: AppColors.white),
                label: const Text('Scan Guardian Wristband',
                    style: TextStyle(color: AppColors.white, fontSize: 14)),
              ),
            ),
          ],
        );

      case _ScanState.error:
        return _centerContent(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          title: 'Scan failed',
          subtitle: _errorMessage ?? 'Unknown error',
        );

      case _ScanState.success:
        return Column(
          children: [
            const SizedBox(height: 28),
            const Text('Data read successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 23,
                    fontWeight: FontWeight.w400)),
            const Spacer(),
            const Icon(Icons.check_circle, size: 120, color: AppColors.success),
            const Spacer(),
            const Text('The wristband data was\nsuccessfully loaded',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 320, height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ReadNfcGuardianScreen(patient: _patient!),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A396),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Continue to Read NFC',
                      style: TextStyle(color: AppColors.white, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
    }
  }

  Widget _centerContent({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showSpinner = false,
  }) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: iconColor == AppColors.error
                    ? AppColors.error
                    : AppColors.secondary,
                fontSize: 23,
                fontWeight: FontWeight.w400)),
        const Spacer(),
        if (showSpinner)
          const SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                  strokeWidth: 4, color: AppColors.primary))
        else
          Icon(icon, size: 120, color: iconColor),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}