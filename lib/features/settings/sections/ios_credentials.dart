import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, IosConfig?>(
      selector: (s) => s.distribution.appstore ?? const IosConfig(),
      builder: (_, ios) {
        if (ios == null) return const SizedBox.shrink();

        return AppCard(
          title: 'iOS Config',
          description:
              'Browse to your Google Cloud service account JSON key so Fluship can authenticate Play Store uploads when you build an AAB. Leave package name blank to auto-detect it from your Flutter project.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) => _updateIos(ios.copyWith(issuerId: value)),
              initialValue: ios.issuerId,
              label: 'Issuer ID',
              hint: '1234567890',
            ),
            AppTextField.label(
              onChanged: (value) => _updateIos(ios.copyWith(apiKeyId: value)),
              initialValue: ios.apiKeyId,
              label: 'API Key ID',
              hint: '1234567890',
            ),
          ],
        );
      },
    );
  }
}
