import 'package:flutter/material.dart';

class ScreenBottomHandle extends StatelessWidget {
  const ScreenBottomHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF666666),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SizedBox(height: 5),
    );
  }
}
