import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
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

class _ReadNfcScreenState extends State<ReadNfcScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinnerController;

  bool _scanning = true;
  bool _isReadingPhysicalTag = false;
  PatientFullRecord? _patient;
  String? _errorMessage;

  final TextEditingController _uidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan(String deviceUid) async {
    setState(() {
      _scanning = true;
      _errorMessage = null;
      _patient = null;
    });
    _spinnerController.repeat();

    try {
      final patient = await AppScope.of(
        context,
      ).patientRepository.scanDevice(deviceUid);
      if (mounted) {
        setState(() {
          _patient = patient;
          _scanning = false;
        });
        _spinnerController.stop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _scanning = false;
        });
        _spinnerController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _scanning = false;
        });
        _spinnerController.stop();
      }
    }
  }

  Future<void> _scanFromPhysicalTag() async {
    if (_isReadingPhysicalTag) return;

    final NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NFC is not available on this device. Enter the device UID manually.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isReadingPhysicalTag = true;
      _scanning = true;
      _errorMessage = null;
      _patient = null;
    });
    _spinnerController.repeat();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: <NfcPollingOption>{
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        alertMessageIos: 'Hold your iPhone near the NFC wristband.',
        onDiscovered: (NfcTag tag) async {
          try {
            final String? uid = _extractDeviceUid(tag);
            if (uid == null || uid.isEmpty) {
              await NfcManager.instance.stopSession(
                errorMessageIos:
                    'Unable to read an NFC identifier. Try another wristband.',
              );
              if (mounted) {
                setState(() {
                  _isReadingPhysicalTag = false;
                  _scanning = false;
                  _errorMessage =
                      'NFC tag was detected but no identifier could be read.';
                });
                _spinnerController.stop();
              }
              return;
            }

            _uidCtrl.text = uid;
            await NfcManager.instance.stopSession(
              alertMessageIos: 'NFC read successful.',
            );

            if (mounted) {
              setState(() => _isReadingPhysicalTag = false);
            }
            await _scan(uid);
          } catch (error) {
            await NfcManager.instance.stopSession(
              errorMessageIos: 'NFC read failed. Please try again.',
            );
            if (mounted) {
              setState(() {
                _isReadingPhysicalTag = false;
                _scanning = false;
                _errorMessage = error.toString();
              });
              _spinnerController.stop();
            }
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isReadingPhysicalTag = false;
          _scanning = false;
          _errorMessage = 'Unable to start NFC session: $error';
        });
        _spinnerController.stop();
      }
    }
  }

  String? _extractDeviceUid(NfcTag tag) {
    final MiFareIos? iosMiFare = MiFareIos.from(tag);
    if (iosMiFare != null && iosMiFare.identifier.isNotEmpty) {
      return _toHex(iosMiFare.identifier);
    }

    final Iso15693Ios? iosIso15693 = Iso15693Ios.from(tag);
    if (iosIso15693 != null && iosIso15693.identifier.isNotEmpty) {
      return _toHex(iosIso15693.identifier);
    }

    final NfcTagAndroid? androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null && androidTag.id.isNotEmpty) {
      return _toHex(androidTag.id);
    }

    return null;
  }

  String _toHex(Uint8List bytes) {
    return bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 15,
                          color: AppColors.white,
                        ),
                        label: const Text(
                          'Back',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _uidCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter device UID or scan NFC',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.disabled,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _isReadingPhysicalTag
                              ? null
                              : () {
                                  final String typedUid = _uidCtrl.text.trim();
                                  if (typedUid.isNotEmpty) {
                                    _scan(typedUid);
                                    return;
                                  }
                                  _scanFromPhysicalTag();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isReadingPhysicalTag
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
                                  color: AppColors.white,
                                  size: 22,
                                ),
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

  Widget _buildCardContent() {
    if (_scanning && _patient == null && _errorMessage == null) {
      return Column(
        children: [
          const SizedBox(height: 28),
          const Text(
            'Enter a device UID and tap\nthe NFC button to scan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 23,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.nfc_rounded,
            size: 120,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const Spacer(),
          const Text(
            'Ready to scan',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const SizedBox(height: 28),
          const Text(
            'Scan failed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 23,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          const Icon(Icons.error_outline, size: 120, color: AppColors.error),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 28),
        const Text(
          'Data read successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 23,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        const Icon(Icons.check_circle, size: 120, color: AppColors.success),
        const Spacer(),
        const Text(
          'The wristband data was\nsuccessfully loaded',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: 320,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReadNfcGuardianScreen(patient: _patient!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continue to Read NFC',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
