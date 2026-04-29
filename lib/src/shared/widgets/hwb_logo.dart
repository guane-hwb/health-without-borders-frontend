// lib/src/shared/widgets/hwb_logo.dart
import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

/// Health Without Borders logo — rounded blue square with a white medical
/// cross (top-left) and a white heart with pulse (bottom-right).
///
/// Uses a Stack with standard Flutter Icons for the cross and heart, and a
/// tiny CustomPaint only for the ECG pulse line. This approach renders
/// reliably on web (CanvasKit & HTML), iOS, and Android.
class HwbLogo extends StatelessWidget {
  const HwbLogo({super.key, this.size = 48, this.elevated = false});

  final double size;
  final bool elevated;

  factory HwbLogo.small({Key? key}) => HwbLogo(key: key, size: 32);
  factory HwbLogo.medium({Key? key}) => HwbLogo(key: key, size: 60);
  factory HwbLogo.large({Key? key}) =>
      HwbLogo(key: key, size: 120, elevated: true);

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    final crossSize = size * 0.30;
    final heartSize = size * 0.40;
    final pulseW = heartSize * 0.75;
    final pulseH = heartSize * 0.35;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
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
      child: Stack(
        children: [
          // ── White medical cross (top-left) ──
          Positioned(
            left: size * 0.10,
            top: size * 0.08,
            child: Icon(
              Icons.add_rounded,
              size: crossSize,
              color: AppColors.white,
            ),
          ),

          // ── White heart (bottom-right) ──
          Positioned(
            right: size * 0.10,
            bottom: size * 0.10,
            child: Icon(
              Icons.favorite,
              size: heartSize,
              color: AppColors.white,
            ),
          ),

          // ── Pulse ECG line (centered over the heart) ──
          Positioned(
            right: size * 0.10 + (heartSize - pulseW) / 2,
            bottom: size * 0.10 + (heartSize - pulseH) / 2,
            child: SizedBox(
              width: pulseW,
              height: pulseH,
              child: CustomPaint(
                size: Size(pulseW, pulseH),
                painter: _PulsePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the ECG/pulse waveform line inside the heart.
class _PulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.50;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.07).clamp(1.5, 4.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, midY)
      ..lineTo(w * 0.20, midY)
      ..lineTo(w * 0.32, midY - h * 0.40)
      ..lineTo(w * 0.48, midY + h * 0.42)
      ..lineTo(w * 0.60, midY - h * 0.32)
      ..lineTo(w * 0.72, midY)
      ..lineTo(w, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
