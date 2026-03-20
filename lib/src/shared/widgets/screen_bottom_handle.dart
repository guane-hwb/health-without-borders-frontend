import 'package:flutter/material.dart';

class ScreenBottomHandle extends StatelessWidget {
  const ScreenBottomHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF3F4A5A).withValues(alpha: 0.65),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: const SizedBox(height: 5),
    );
  }
}
