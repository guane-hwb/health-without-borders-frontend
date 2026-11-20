// lib/src/shared/widgets/discard_changes_dialog.dart

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../design/tokens/app_colors.dart';

/// Asks before leaving a form that has something written in it: nothing of it
/// is saved yet. True means discard and leave; false (or dismissing the
/// dialog), keep editing.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final s = AppStrings.of(context);
  final bool? discard = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.keepEditing),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            s.discard,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  return discard ?? false;
}
