import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_button.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/read_nfc_screen.dart';
import '../../nfc/presentation/register_nfc_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HwbButton(
                  label: 'Read NFC',
                  icon: Icons.read_more,
                  fontSize: 32 / 2,
                  iconSize: 17,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReadNfcScreen()),
                    );
                  },
                ),
                const SizedBox(height: 31),
                HwbButton(
                  label: 'Register NFC',
                  variant: HwbButtonVariant.secondary,
                  icon: Icons.edit_note,
                  fontSize: 32 / 2,
                  iconSize: 17,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterNfcScreen(),
                      ),
                    );
                  },
                ),
              ],
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
