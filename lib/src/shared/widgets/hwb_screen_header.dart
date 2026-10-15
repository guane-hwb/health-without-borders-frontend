// lib/src/shared/widgets/hwb_screen_header.dart

import 'package:flutter/material.dart';
import '../../design/tokens/app_colors.dart';
import 'locale_switcher.dart';

class HwbScreenHeader extends StatelessWidget {
  const HwbScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showLocaleSwitcher = true,
    this.showBack = true,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showLocaleSwitcher;

  /// False on a screen the user may not leave (e.g. a mandatory step).
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
          SizedBox(width: showBack ? 4 : 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showLocaleSwitcher) const LocaleSwitcher(),
        ],
      ),
    );
  }
}
