import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

class HwbBackButton extends StatelessWidget {
  const HwbBackButton({super.key, this.label = 'Back', this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A396),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 15,
          color: AppColors.white,
        ),
        label: Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
        ),
      ),
    );
  }
}
