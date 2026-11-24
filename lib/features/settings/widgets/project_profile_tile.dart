import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

import 'dart:io' show File;

class const ProjectProfileTile({
  required final String projectName,
  final bool selected = false,
  final String? appIconPath,
  final String? projectPath,
  final Widget? trailing,
  final VoidCallback? onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final path = projectPath;
    final shape = RoundedRectangleBorder(
      borderRadius: .circular(ft.radius.input),
      side: BorderSide(
        color: selected ? ft.colors.accent : ft.colors.cardBorder,
      ),
    );

    return Material(
      color: selected
          ? ft.colors.accent.withValues(alpha: 0.08)
          : ft.colors.cardBg,
      clipBehavior: .antiAlias,
      shape: shape,
      child: ListTile(
        shape: shape,
        leading: _ProjectLogo(
          appIconPath: appIconPath,
          projectName: projectName,
        ),
        title: AppText.subtitle(projectName, weight: .w600),
        subtitle: path == null
            ? null
            : AppText.label(
                overflow: .ellipsis,
                selectable: true,
                maxLines: 1,
                path,
              ).padOnly(t: 7),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class const _ProjectLogo({
  required final String? appIconPath,
  required final String projectName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final fallback = ColoredBox(
      color: ft.colors.accent.withValues(alpha: 0.14),
      child: AppText.accent(
        projectName.isEmpty ? '?' : projectName[0].toUpperCase(),
        size: .subtitle,
        weight: .w700,
      ).center(),
    );
    final iconPath = appIconPath;

    return SizedBox.square(
      dimension: 50,
      child: ClipRRect(
        borderRadius: .circular(ft.radius.input),
        child: iconPath == null
            ? fallback
            : Image.file(
                File(iconPath),
                errorBuilder: (_, _, _) => fallback,
                fit: .cover,
              ),
      ).padAll(4),
    );
  }
}
