import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

class HwbTextField extends StatelessWidget {
  const HwbTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          enabled: enabled,
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 10,
              color: enabled ? AppColors.textPrimary : AppColors.disabled,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 14, color: AppColors.primary)
                : null,
          ),
        ),
      ],
    );
  }
}
