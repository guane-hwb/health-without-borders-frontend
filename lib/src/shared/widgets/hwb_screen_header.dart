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
  });

  final String title;
  final VoidCallback? onBack;
  final bool showLocaleSwitcher;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
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
