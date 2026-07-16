import 'package:fluship/features/settings/views/profile_form_screen.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
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
        onSuccess: (_) => AppToast.success('Active profile changed'),
        onError: (error) => AppToast.error(error.message),
        projectName: projectName,
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
                'Add a project profile by selecting its Flutter folder or importing a config JSON.',
            spacing: 12,
            title: 'Project Profile',
            children: [
              AppButton.primary(
                onPressed: () => _addProfile(context, state),
                leading: const Icon(Icons.add),
                label: 'Add Profile',
              ),
            ],
          );
        }

        final appInfo = state.appInfo;
        return AppCard(
          description: 'Active project profile',
          spacing: 12,
          title: appInfo.appName ?? activeProject,
          children: [
            _ProfileDetail(value: activeProject, label: 'Project key'),
            _ProfileDetail(
              value: appInfo.flutterProjectPath ?? 'Not selected',
              label: 'Flutter project',
            ),
            DropdownButtonFormField<String>(
              initialValue: activeProject,
              decoration: const InputDecoration(labelText: 'Switch project'),
              onChanged: state.loading
                  ? null
                  : (name) {
                      if (name == null || name == activeProject) return;
                      _switchProfile(context, name);
                    },
              items: [
                for (final name in state.projectNames)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                AppButton.outline(
                  onPressed: () => _openForm(context, isAdding: false),
                  leading: const Icon(Icons.edit),
                  label: 'Edit Profile',
                ).expanded(),
                AppButton.primary(
                  onPressed: () => _addProfile(context, state),
                  leading: const Icon(Icons.add),
                  label: 'Add Profile',
                ).expanded(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        AppText.label('$label: '),
        AppText.body(value, selectable: true).expanded(),
      ],
    );
  }
}
