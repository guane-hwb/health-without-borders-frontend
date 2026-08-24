// lib/src/features/nfc/presentation/shared_read_nfc_header.dart
import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';

class SharedReadNfcHeader extends StatelessWidget {
  const SharedReadNfcHeader({
    super.key,
    this.title = 'HWB',
    this.onBack,
    this.stepText,
  });

  final String title;
  final VoidCallback? onBack;
  final String? stepText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Row(
        children: [
          if (onBack != null)
            Material(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          else
            const Padding(padding: EdgeInsets.all(4), child: HwbLogo(size: 32, onDark: true)),
          const SizedBox(width: 8),
          if (onBack != null) const HwbLogo(size: 38, onDark: true),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (stepText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                stepText!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (stepText == null && onBack != null) const SizedBox(width: 48),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
