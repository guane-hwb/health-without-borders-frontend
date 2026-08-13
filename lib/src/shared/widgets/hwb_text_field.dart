// lib/src/shared/widgets/hwb_text_field.dart

import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';

class HwbTextField extends StatelessWidget {
  const HwbTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.icon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: enabled ? AppColors.textSecondary : AppColors.disabled,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.secondary)
                : null,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
