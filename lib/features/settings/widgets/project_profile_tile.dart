import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File;

class ProjectProfileTile extends StatelessWidget {
  const ProjectProfileTile({
    this.contentPadding = .zero,
    required this.projectName,
    this.selected = false,
    this.appIconPath,
    this.projectPath,
    this.trailing,
    this.onTap,
    super.key,
  });

  final EdgeInsetsGeometry contentPadding;
  final String? appIconPath;
  final String? projectPath;
  final VoidCallback? onTap;
  final String projectName;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final path = projectPath;

    return ListTile(
      contentPadding: contentPadding,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(ft.radius.input),
        side: BorderSide(
          color: selected ? ft.colors.accent : ft.colors.cardBorder,
        ),
      ),
      tileColor: selected
          ? ft.colors.accent.withValues(alpha: 0.08)
          : ft.colors.cardBg,
      leading: _ProjectLogo(appIconPath: appIconPath, projectName: projectName),
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
    );
  }
}

class _ProjectLogo extends StatelessWidget {
  const _ProjectLogo({required this.appIconPath, required this.projectName});

  final String? appIconPath;
  final String projectName;

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
