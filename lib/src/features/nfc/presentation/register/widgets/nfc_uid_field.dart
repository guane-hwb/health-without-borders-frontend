// lib/src/features/nfc/presentation/register/widgets/nfc_uid_field.dart
//
// Reusable NFC UID field: an editable text field (for manual entry / testing)
// with a scan button beside it and a "linked device" confirmation below.
// Used for both the patient wristband and the guardian card so the two share
// the same look and behaviour.

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';

class NfcUidField extends StatelessWidget {
  const NfcUidField({
    super.key,
    required this.controller,
    required this.scanning,
    required this.onScan,
    required this.onChanged,
    required this.hintText,
    this.prefixIcon = Icons.contactless,
  });

  final TextEditingController controller;
  final bool scanning;
  final VoidCallback onScan;
  final VoidCallback onChanged;
  final String hintText;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hasValue = controller.text.trim().isNotEmpty;
    final isEs = s.welcome == 'Bienvenido';
    final deviceLinkedLabel = isEs ? 'Dispositivo vinculado' : 'Linked device';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    prefixIcon,
                    size: 20,
                    color: hasValue
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  suffixIcon: hasValue
                      ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.success,
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFB0B8C4),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              width: 56,
              child: ElevatedButton(
                onPressed: scanning ? null : onScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  elevation: 0,
                ),
                child: scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.nfc, size: 22, color: AppColors.white),
              ),
            ),
          ],
        ),
        if (hasValue) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 13,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '$deviceLinkedLabel: ${controller.text.trim()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
