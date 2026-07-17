import 'package:fluship/features/settings/widgets/project_profile_tile.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter/material.dart';

class ProjectSwitcherSheet extends StatelessWidget {
  const ProjectSwitcherSheet({
    required this.profileAppInfo,
    required this.activeProject,
    required this.projectNames,
    super.key,
  });

  final Map<String, AppInfoModel> profileAppInfo;
  final List<String> projectNames;
  final String activeProject;

  static Future<String?> show(
    BuildContext context, {
    required Map<String, AppInfoModel> profileAppInfo,
    required String activeProject,
    required List<String> projectNames,
  }) {
    return showModalBottomSheet<String>(
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ProjectSwitcherSheet(
          profileAppInfo: profileAppInfo,
          activeProject: activeProject,
          projectNames: projectNames,
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
                final appInfo = profileAppInfo[projectName];
                final selected = projectName == activeProject;

                return ProjectProfileTile(
                  projectPath: appInfo?.flutterProjectPath,
                  appIconPath: appInfo?.appIconPath,
                  projectName: projectName,
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
                  onTap: selected
                      ? null
                      : () => Navigator.of(context).pop(projectName),
                );
              },
            ).flexible(),
          ],
        ),
      ),
    ).padAll(ft.spacing.sm);
  }
}
