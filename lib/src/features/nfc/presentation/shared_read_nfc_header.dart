import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../home/presentation/home_screen.dart';

class SharedReadNfcHeader extends StatelessWidget {
  const SharedReadNfcHeader({
    super.key,
    this.title = 'Read NFC',
    this.showHomeAction = true,
  });

  final String title;
  final bool showHomeAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 103,
      color: AppColors.primary,
      child: Stack(
        children: [
          const Positioned(
            left: 14,
            top: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x2221ABE2),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.health_and_safety, color: AppColors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 58,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 50,
            child: Row(
              children: [
                if (showHomeAction)
                  Tooltip(
                    message: 'Go to Home',
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const HomeScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.home_rounded,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 37,
                  height: 37,
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
