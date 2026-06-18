import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class GooglePlayConsole extends StatelessWidget {
  const GooglePlayConsole({super.key});

  GooglePlayConsoleConfig _gp(GooglePlayConsoleConfig? gp) =>
      gp ?? const GooglePlayConsoleConfig();

  void _updateGp(
    GooglePlayConsoleConfig Function(GooglePlayConsoleConfig?) patch,
  ) {
    final bloc = getIt<ConfigBloc>();
    final android = bloc.state.android;

    bloc.add(
      UpdateConfig(
        config: android.copyWith(gpConfig: patch(android.gpConfig)),
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  Future<void> _pickSaJson() async {
    final path = await getIt<FilePickerService>().pickFile(
      dialogTitle: 'Select Service Account JSON file',
      allowedExtensions: ['json'],
    );

    if (path == null) return;

    _updateGp((gp) => _gp(gp).copyWith(saJsonPath: path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, GooglePlayConsoleConfig?>(
      selector: (state) => state.android.gpConfig,
      builder: (context, gpConfig) {
        return AppCard(
          title: 'Google Play Console',
          description:
              'Authorize Play Store uploads with a service account JSON key from Google Cloud Console. '
              'Leave the package name blank to use the value from your Flutter project automatically.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) => _updateGp((gp) {
                return _gp(gp).copyWith(packageName: value);
              }),
              initialValue: gpConfig?.packageName,
              label: 'Package name (optional)',
              hint: 'com.example.my_app',
            ),
            FieldButton(
              hint: 'C:/Users/Username/Documents/play_service_account.json',
              label: 'Service account JSON',
              value: gpConfig?.saJsonPath,
              onBrowse: _pickSaJson,
            ),
          ],
        );
      },
    );
  }
}
