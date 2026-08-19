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
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool enabled;
  final bool required;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cleanLabel.isNotEmpty) ...[
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: cleanLabel),
                if (required || label.contains('*'))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
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
