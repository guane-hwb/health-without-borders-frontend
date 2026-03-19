import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

enum HwbButtonVariant { primary, secondary }

class HwbButton extends StatelessWidget {
  const HwbButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.variant = HwbButtonVariant.primary,
    this.width = 237,
    this.height = 38,
    this.fontSize = 18,
    this.iconSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final HwbButtonVariant variant;
  final double width;
  final double height;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == HwbButtonVariant.primary;
    final background = isPrimary ? AppColors.primary : AppColors.secondary;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize, color: AppColors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? AppColors.disabled : background,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        label: Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
