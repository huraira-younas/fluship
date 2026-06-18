import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ConsoleToolbar extends StatelessWidget {
  const ConsoleToolbar({
    required this.projectPath,
    required this.isRunning,
    required this.onClear,
    required this.onStop,
    super.key,
  });

  final VoidCallback onClear;
  final VoidCallback onStop;
  final String? projectPath;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final path = projectPath?.trim();
    final cwd = (path == null || path.isEmpty)
        ? 'No project path set — configure in Settings'
        : path;

    return Container(
      decoration: BoxDecoration(
        border: .all(color: ft.colors.consoleBorder),
        borderRadius: .circular(ft.radius.btn),
        color: ft.colors.consoleBg,
      ),
      padding: .symmetric(horizontal: ft.spacing.md, vertical: ft.spacing.md),
      child: Row(
        spacing: ft.spacing.md,
        children: [
          Icon(Icons.folder_outlined, size: 16, color: ft.colors.muted),
          AppText.code(
            overflow: .ellipsis,
            size: .caption,
            maxLines: 1,
            cwd,
          ).expanded(),
          if (isRunning)
            AppButton.danger(onPressed: onStop, label: 'Stop', size: .sm),
          AppButton.outline(
            label: 'Clear Console',
            onPressed: onClear,
            size: .sm,
          ),
        ],
      ),
    );
  }
}
