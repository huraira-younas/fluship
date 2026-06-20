import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/console_bloc.dart';

class ConsoleToolbar extends StatelessWidget {
  const ConsoleToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, String?>(
      selector: (state) => state.activeSession?.workingDirectory,
      builder: (context, workingDirectory) {
        final ft = context.flushipTheme;
        final path = workingDirectory?.trim();
        final cwd = (path == null || path.isEmpty)
            ? 'No project path set — configure in Settings'
            : path;

        return Container(
          decoration: BoxDecoration(
            border: .all(color: ft.colors.consoleBorder),
            borderRadius: .circular(ft.radius.btn),
            color: ft.colors.consoleBg,
          ),
          padding: .symmetric(
            horizontal: ft.spacing.md,
            vertical: ft.spacing.md,
          ),
          child: Row(
            spacing: ft.spacing.md,
            children: [
              Icon(Icons.folder_outlined, size: 20, color: ft.colors.muted),
              AppText.code(
                overflow: .ellipsis,
                size: .caption,
                maxLines: 1,
                cwd,
              ).expanded(),
            ],
          ),
        );
      },
    );
  }
}
