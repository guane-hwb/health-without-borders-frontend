// lib/src/features/nfc/presentation/profile/shared/profile_section_header.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';

/// Section header used inside profile tabs.
///
/// Shows an uppercase title with an icon on the left. When [onAction] is
/// provided, an "Editar" / "Agregar" link button is shown on the right.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.actionLabel,
    this.actionIcon = Icons.edit_outlined,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (onAction != null && actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
