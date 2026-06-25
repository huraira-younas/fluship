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

class GooglePlayConsole extends StatelessWidget {
  const GooglePlayConsole({super.key});

  void _updateGp(GooglePlayConsoleConfig config) {
    final bloc = getIt<ConfigBloc>();
    final distribution = bloc.state.distribution;

    bloc.add(
      UpdateConfig(
        onError: (error) => AppToast.error(error.message),
        config: distribution.copyWith(playstore: config),
      ),
    );
  }

  Future<void> _pickSaJson(GooglePlayConsoleConfig gpConfig) async {
    final path = await getIt<FilePickerService>().pickFile(
      dialogTitle: 'Select Service Account JSON file',
      allowedExtensions: ['json'],
    );

    if (path == null) return;

    _updateGp(gpConfig.copyWith(saJsonPath: path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, GooglePlayConsoleConfig?>(
      selector: (s) =>
          s.distribution.playstore ?? const GooglePlayConsoleConfig(),
      builder: (_, c) {
        if (c == null) return const SizedBox.shrink();

        return AppCard(
          title: 'Google Play Console',
          description:
              'Configure your Android package name and Google Cloud service account JSON key so Fluship can upload AAB builds to the Play Store.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) => _updateGp(c.copyWith(packageName: value)),
              initialValue: c.packageName,
              hint: 'com.example.my_app',
              label: 'Package name',
            ),
            FieldButton(
              hint: 'C:/Users/Username/Documents/play_service_account.json',
              onBrowse: () => _pickSaJson(c),
              label: 'Service account JSON',
              value: c.saJsonPath,
            ),
          ],
        );
      },
    );
  }
}
