import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class IosCredentials extends StatelessWidget {
  const IosCredentials({super.key});

  void _updateIos(IosConfig config) {
    final bloc = getIt<ConfigBloc>();
    final distribution = bloc.state.distribution;

    bloc.add(
      UpdateConfig(
        onError: (error) => AppToast.error(error.message),
        config: distribution.copyWith(appstore: config),
      ),
    );
  }

  Future<void> _pickApiKey(IosConfig ios) async {
    final path = await getIt<FilePickerService>().pickFile(
      dialogTitle: 'Select App Store Connect API Key (.p8)',
      allowedExtensions: ['p8'],
    );

    if (path == null) return;

    _updateIos(ios.copyWith(apiKeyPath: path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, IosConfig?>(
      selector: (s) => s.distribution.appstore ?? const IosConfig(),
      builder: (_, ios) {
        if (ios == null) return const SizedBox.shrink();

        return AppCard(
          title: 'App Store Connect',
          description:
              'Enter your App Store Connect API credentials so Fluship can upload IPA builds to TestFlight. '
              'Create an API key in App Store Connect under Users and Access, then browse to the downloaded AuthKey .p8 file.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) => _updateIos(ios.copyWith(issuerId: value)),
              initialValue: ios.issuerId,
              label: 'Issuer ID',
              hint: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            ),
            AppTextField.label(
              onChanged: (value) => _updateIos(ios.copyWith(apiKeyId: value)),
              initialValue: ios.apiKeyId,
              label: 'API Key ID',
              hint: 'XXXXXXXXXX',
            ),
            FieldButton(
              hint: '/Users/Username/Keys/AuthKey_XXXXXXXXXX.p8',
              onBrowse: () => _pickApiKey(ios),
              label: 'Auth Key (.p8)',
              value: ios.apiKeyPath,
            ),
          ],
        );
      },
    );
  }
}
