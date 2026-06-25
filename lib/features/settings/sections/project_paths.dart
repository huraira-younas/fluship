import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class ProjectPaths extends StatelessWidget {
  const ProjectPaths({super.key});

  Future<void> _pickFlutterProject(BuildContext context) async {
    final path = await getIt<FilePickerService>().pickDirectory(
      dialogTitle: 'Select Flutter project folder',
    );

    if (path == null || !context.mounted) return;
    getIt<ConfigBloc>().add(
      SyncProjectAppInfo(
        onSuccess: (_) => AppToast.success('Project root synced successfully'),
        onError: (error) => AppToast.error(error.message),
        flutterProjectPath: path,
      ),
    );
  }

  Future<void> _pickFlushipWorkspace(BuildContext context) async {
    final path = await getIt<FilePickerService>().pickDirectory(
      dialogTitle: 'Select Fluship workspace folder',
    );

    if (path == null || !context.mounted) return;

    final currentAppInfo = getIt<ConfigBloc>().state.appInfo;
    getIt<ConfigBloc>().add(
      UpdateConfig(
        config: currentAppInfo.copyWith(flushipWorkspacePath: path),
        onSuccess: (_) => AppToast.success('Fluship workspace saved'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, AppInfoModel>(
      selector: (state) => state.appInfo,
      builder: (context, appInfo) {
        return AppCard(
          title: 'Paths',
          description:
              'Flutter project is your app\'s root folder (pubspec.yaml). '
              'Fluship workspace is this tool\'s repo folder — where the outputs directory lives. '
              'Both are required before running a pipeline.',
          spacing: 14,
          children: [
            FieldButton(
              hint: '/Users/Username/Desktop/Flutter/my_app',
              onBrowse: () => _pickFlutterProject(context),
              value: appInfo.flutterProjectPath,
              label: 'Flutter project path',
            ),
            FieldButton(
              hint: '/Users/Username/Desktop/Flutter/fluship',
              onBrowse: () => _pickFlushipWorkspace(context),
              value: appInfo.flushipWorkspacePath,
              label: 'Fluship workspace path',
            ),
          ],
        );
      },
    );
  }
}
