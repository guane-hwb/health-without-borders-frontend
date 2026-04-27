import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';

class SharedReadNfcHeader extends StatelessWidget {
  const SharedReadNfcHeader({
    super.key,
    this.title = 'Read NFC',
    this.onBack,
    this.stepText,
  });

  final String title;

  /// When provided, a back arrow is shown on the left of the header.
  final VoidCallback? onBack;

  /// Optional step indicator shown at the right, e.g. "1/3".
  final String? stepText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 103,
      color: AppColors.primary,
      child: Stack(
        children: [
          // Back arrow or app icon
          Positioned(
            left: 14,
            top: 44,
            child: onBack != null
                ? GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0x2221ABE2),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x2221ABE2),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child:
                          Icon(Icons.health_and_safety, color: AppColors.white),
                    ),
                  ),
          ),

          // Title
          Positioned(
            left: 70,
            right: 70,
            top: 58,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Step indicator or profile icon
          Positioned(
            right: 14,
            top: 52,
            child: stepText != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x3DFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stepText!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox(
                    width: 37,
                    height: 37,
                    child: Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}