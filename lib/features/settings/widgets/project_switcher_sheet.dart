import 'package:fluship/features/settings/widgets/project_profile_tile.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ProjectSwitcherSheet extends StatelessWidget {
  const ProjectSwitcherSheet({
    required this.activeProjectPath,
    required this.activeProject,
    required this.projectNames,
    required this.appIconPath,
    super.key,
  });

  final List<String> projectNames;
  final String activeProjectPath;
  final String? appIconPath;
  final String activeProject;

  static Future<String?> show(
    BuildContext context, {
    required String activeProjectPath,
    required List<String> projectNames,
    required String activeProject,
    required String? appIconPath,
  }) {
    return showModalBottomSheet<String>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ProjectSwitcherSheet(
          activeProjectPath: activeProjectPath,
          activeProject: activeProject,
          projectNames: projectNames,
          appIconPath: appIconPath,
        ),
      ).align(align: .bottomCenter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Material(
      color: ft.colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: .all(.circular(ft.radius.card)),
        side: BorderSide(color: ft.colors.cardBorder),
      ),
      child: Padding(
        padding: .fromLTRB(
          ft.spacing.lg,
          ft.spacing.md,
          ft.spacing.lg,
          ft.spacing.lg,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: .circular(99),
                color: ft.colors.cardBorder,
              ),
              height: 4,
              width: 40,
            ).center(),
            SizedBox(height: ft.spacing.lg),
            const AppText.title('Switch project'),
            const SizedBox(height: 6),
            const AppText.label(
              'Choose the project profile you want to work with.',
            ),
            SizedBox(height: ft.spacing.md),
            ListView.separated(
              separatorBuilder: (_, _) => SizedBox(height: ft.spacing.sm),
              itemCount: projectNames.length,
              shrinkWrap: true,
              itemBuilder: (_, index) {
                final projectName = projectNames[index];
                final selected = projectName == activeProject;

                return ProjectProfileTile(
                  projectPath: selected ? activeProjectPath : null,
                  appIconPath: selected ? appIconPath : null,
                  projectName: projectName,
                  onTap: selected
                      ? null
                      : () => Navigator.of(context).pop(projectName),
                  contentPadding: .symmetric(horizontal: ft.spacing.md),
                  selected: selected,
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: ft.colors.accent,
                          size: 20,
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: ft.colors.textDim,
                          size: 20,
                        ),
                );
              },
            ).flexible(),
          ],
        ),
      ),
    ).padAll(ft.spacing.sm);
  }
}
