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

  /// When true, a white rounded border is drawn around the logo so it
  /// stands out against the blue header background.
  final bool onDark;

  factory HwbLogo.small({Key? key}) =>
      HwbLogo(key: key, size: 32, onDark: true);
  factory HwbLogo.medium({Key? key}) => HwbLogo(key: key, size: 60);
  factory HwbLogo.large({Key? key}) =>
      HwbLogo(key: key, size: 120, elevated: true);

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    final pad = onDark ? size * 0.001 : 0.0;
    final imgSize = size - pad * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : null,
        borderRadius: BorderRadius.circular(radius),
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
      padding: EdgeInsets.all(pad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.2),
        child: Image.asset(
          'assets/images/app-icon.png',
          width: imgSize,
          height: imgSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
