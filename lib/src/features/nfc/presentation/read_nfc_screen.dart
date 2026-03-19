import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_button.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';

class ReadNfcScreen extends StatelessWidget {
  const ReadNfcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.28,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.public,
                    size: 220,
                    color: AppColors.lightPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'unicef',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 74,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.53)),
          ),
          Center(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    HwbButton(
                      label: 'Read NFC',
                      icon: Icons.read_more,
                      fontSize: 16,
                      iconSize: 17,
                      onPressed: null,
                    ),
                    SizedBox(height: 31),
                    HwbButton(
                      label: 'Register NFC',
                      variant: HwbButtonVariant.secondary,
                      icon: Icons.edit_note,
                      fontSize: 16,
                      iconSize: 17,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Name: So*** Ro***',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Weight: 24 kg',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Height: 122 cm',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Blood type: A+',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Companion / Guardian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Name: Ana Torres',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Relationship: Madre',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 116,
            right: 116,
            bottom: 14,
            child: ScreenBottomHandle(),
          ),
        ],
      ),
    );
  }
}
