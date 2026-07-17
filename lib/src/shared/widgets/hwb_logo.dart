// lib/src/shared/widgets/hwb_logo.dart
import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

/// Health Without Borders logo — renders the brand icon from the PNG asset.
///
/// Set [onDark] = true when placing the logo on a dark/blue background
/// (e.g. headers) so it gets a white border that makes it visible.
class HwbLogo extends StatelessWidget {
  const HwbLogo({
    super.key,
    this.size = 48,
    this.elevated = false,
    this.onDark = false,
  });

  final double size;
  final bool elevated;

  /// When true, a small white rounded background is drawn behind the logo
  /// so it stands out against the blue header background.
  final bool onDark;

  factory HwbLogo.small({Key? key}) =>
      HwbLogo(key: key, size: 32, onDark: true);
  factory HwbLogo.medium({Key? key}) => HwbLogo(key: key, size: 60);
  factory HwbLogo.large({Key? key}) =>
      HwbLogo(key: key, size: 120, elevated: true);

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onDark)
            Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius * 0.8),
                boxShadow: elevated
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: size * 0.16,
                          offset: Offset(0, size * 0.06),
                        ),
                      ]
                    : null,
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.asset(
              'assets/images/app-icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}