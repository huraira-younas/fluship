import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

import 'package:fluship/shared/widgets/app_text.dart';

Future<bool> confirmDeleteSelectedItems({
  required BuildContext context,
  required int count,
}) async {
  final label = count == 1 ? '1 item' : '$count items';
  final ft = context.flushipTheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ft.colors.cardBg,
      title: AppText.title('Delete $label?'),
      content: const AppText.body(
        'This will permanently remove the selected files and folders from outputs.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const AppText.body('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const AppText.danger('Delete'),
        ),
      ],
    ),
  );

  return result ?? false;
}
