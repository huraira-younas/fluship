import 'package:fluship/features/settings/widgets/project_switcher_sheet.dart';
import 'package:fluship/features/settings/widgets/project_profile_tile.dart';
import 'package:fluship/features/settings/views/profile_form_screen.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_cta_button.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  void _openForm(
    BuildContext context, {
    required bool isAdding,
    String? previousProject,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileFormScreen(
          previousProject: previousProject,
          isAdding: isAdding,
        ),
      ),
    );
  }

  void _addProfile(BuildContext context, ConfigState state) {
    context.read<ConfigBloc>().add(
      StartNewProfile(
        onSuccess: (_) {
          if (!context.mounted) return;
          _openForm(
            previousProject: state.activeProject,
            isAdding: true,
            context,
          );
        },
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  void _switchProfile(BuildContext context, String projectName) {
    context.read<ConfigBloc>().add(
      SwitchProjectProfile(
        projectName: projectName,
        onSuccess: (_) => AppToast.success('Active profile changed'),
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, state) {
        final activeProject = state.activeProject;
        if (activeProject == null) {
          return AppCard(
            description:
                'Connect a Flutter project to save its pipeline settings.',
            spacing: 12,
            title: 'Workspace',
            children: [
              const SizedBox(height: 12),
              AppCtaButton(
                onTap: () => _addProfile(context, state),
                text: "Choose a Flutter project to save its pipeline settings.",
                title: "No project selected",
                btnText: "Choose project",
                icon: Icons.add_rounded,
                iconSize: 60,
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        final path = state.appInfo.flutterProjectPath ?? 'Not selected';

        return AppCard(
          description: 'Project-specific pipeline settings.',
          title: 'Workspace',
          spacing: 12,
          children: [
            ProjectProfileTile(
              appIconPath: state.appInfo.appIconPath,
              projectName: activeProject,
              projectPath: path,
              trailing: _ProjectSwitcher(
                appIconPath: state.appInfo.appIconPath,
                activeProject: activeProject,
                projectNames: state.projectNames,
                projectPath: path,
                onSelected: state.loading
                    ? null
                    : (name) {
                        if (name == activeProject) return;
                        _switchProfile(context, name);
                      },
                loading: state.loading,
              ),
            ),
            Row(
              mainAxisAlignment: .end,
              spacing: 12,
              children: [
                AppButton.outline(
                  onPressed: () => _openForm(context, isAdding: false),
                  leading: const Icon(Icons.edit_outlined),
                  label: 'Edit',
                ),
                AppButton.primary(
                  onPressed: () => _addProfile(context, state),
                  leading: const Icon(Icons.add_rounded),
                  label: 'New project',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProjectSwitcher extends StatelessWidget {
  const _ProjectSwitcher({
    required this.activeProject,
    required this.projectNames,
    required this.appIconPath,
    required this.projectPath,
    required this.onSelected,
    required this.loading,
  });

  final ValueChanged<String>? onSelected;
  final List<String> projectNames;
  final String activeProject;
  final String? appIconPath;
  final String projectPath;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return AppButton.icon(
      onPressed: loading || onSelected == null
          ? null
          : () async {
              final selected = await ProjectSwitcherSheet.show(
                activeProjectPath: projectPath,
                activeProject: activeProject,
                projectNames: projectNames,
                appIconPath: appIconPath,
                context,
              );
              if (!context.mounted ||
                  selected == null ||
                  selected == activeProject) {
                return;
              }
              onSelected?.call(selected);
            },
      tooltip: 'Switch project',
      leading: loading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                color: ft.colors.accent,
                strokeWidth: 2,
              ),
            )
          : Icon(Icons.swap_horiz_rounded, color: ft.colors.textDim, size: 22),
      size: .sm,
    );
  }
}
