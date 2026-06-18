import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class GoogleDrive extends StatelessWidget {
  const GoogleDrive({super.key});

  GoogleDriveConfig _drive(GoogleDriveConfig? config) =>
      config ?? const GoogleDriveConfig();

  void _updateDrive(GoogleDriveConfig config) {
    final bloc = getIt<ConfigBloc>();

    bloc.add(
      UpdateConfig(
        config: bloc.state.distribution.copyWith(driveConfig: config),
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  Future<void> _pickJson(
    GoogleDriveConfig drive, {
    required String dialogTitle,
    required GoogleDriveConfig Function(GoogleDriveConfig, String) patch,
  }) async {
    final path = await getIt<FilePickerService>().pickFile(
      allowedExtensions: ['json'],
      dialogTitle: dialogTitle,
    );

    if (path == null) return;

    _updateDrive(patch(drive, path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, GoogleDriveConfig>(
      selector: (s) => _drive(s.distribution.driveConfig),
      builder: (_, drive) {
        return AppCard(
          title: 'Google Drive',
          description:
              '• Add your OAuth client JSON from Google Cloud Console to enable Drive uploads.\n'
              '• Optionally provide a saved token JSON to skip re-authorization on the next run.\n'
              '• Set a parent folder ID to control where build artifacts are stored in Drive.',
          spacing: 15,
          children: [
            FieldButton(
              hint: 'C:/Users/Username/Documents/oauth_client.json',
              label: 'OAuth client JSON',
              value: drive.oauthJson,
              onBrowse: () => _pickJson(
                patch: (c, path) => c.copyWith(oauthJson: path),
                dialogTitle: 'Select OAuth client JSON file',
                drive,
              ),
            ),
            FieldButton(
              hint: 'C:/Users/Username/Documents/gdrive_token.json',
              label: 'Token JSON (optional)',
              value: drive.tokenJson,
              onBrowse: () => _pickJson(
                patch: (c, path) => c.copyWith(tokenJson: path),
                dialogTitle: 'Select token JSON file',
                drive,
              ),
            ),
            AppTextField.label(
              onChanged: (value) =>
                  _updateDrive(drive.copyWith(folderId: value)),
              hint: '1k21HPdFxA8Xa8R9qh7CBcB6A6TtE0kQF',
              label: 'Parent folder ID (optional)',
              initialValue: drive.folderId,
            ),
          ],
        );
      },
    );
  }
}
