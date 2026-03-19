import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'read_nfc_guardian_screen.dart';
import 'shared_read_nfc_header.dart';

class ReadNfcScreen extends StatefulWidget {
  const ReadNfcScreen({super.key});

  @override
  State<ReadNfcScreen> createState() => _ReadNfcScreenState();
}

class _ReadNfcScreenState extends State<ReadNfcScreen>
    with SingleTickerProviderStateMixin {
  bool _scanComplete = false;
  late final AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanComplete = true;
        });
        _spinnerController.stop();
      }
    });
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
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
                const SizedBox(height: 30),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Container(
                      width: 347,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          Text(
                            _scanComplete
                                ? 'Data read successful!'
                                : 'Reading a wristband with\nNFC',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 23,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (_scanComplete)
                            const Icon(
                              Icons.check_circle,
                              size: 120,
                              color: AppColors.success,
                            )
                          else
                            Icon(
                              Icons.nfc_rounded,
                              size: 120,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          const Spacer(),
                          Text(
                            _scanComplete
                                ? 'The wristband data was\nsuccessfully loaded'
                                : 'Please, wait a moment ...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_scanComplete)
                            RotationTransition(
                              turns: _spinnerController,
                              child: const Icon(
                                Icons.autorenew,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: SizedBox(
                              width: 320,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: _scanComplete
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ReadNfcGuardianScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _scanComplete
                                      ? const Color(0xFF00A396)
                                      : AppColors.disabled,
                                  disabledBackgroundColor: AppColors.disabled,
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
                      ),
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
}

