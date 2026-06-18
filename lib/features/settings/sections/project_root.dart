import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../../config/bloc/config_bloc.dart';
import '../widgets/field_button.dart';

class ProjectRoot extends StatelessWidget {
  const ProjectRoot({
    super.key,
    this.filePickerService = const FilePickerService(),
  });

  final FilePickerService filePickerService;

  Future<void> _pickProjectRoot(BuildContext context) async {
    final path = await filePickerService.pickDirectory(
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

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, AppInfoModel>(
      selector: (state) => state.appInfo,
      builder: (context, appInfo) {
        return AppCard(
          title: 'Project Root',
          description:
              'Point Fluship at your Flutter app folder — the directory that contains pubspec.yaml. '
              'Build commands, config files, and artifact paths are all resolved from here.',
          children: [
            FieldButton(
              hint: 'C:/Users/Username/Desktop/flutter_project',
              onBrowse: () => _pickProjectRoot(context),
              value: appInfo.flutterProjectPath,
              label: 'Flutter project path',
            ),
          ],
        );
      },
    );
  }
}
