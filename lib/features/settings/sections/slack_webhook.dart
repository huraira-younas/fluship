import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

class SlackWebhook extends StatelessWidget {
  const SlackWebhook({super.key});

  SlackConfig _slack(SlackConfig? config) => config ?? const SlackConfig();

  void _updateSlack(SlackConfig config) {
    final bloc = getIt<ConfigBloc>();

    bloc.add(
      UpdateConfig(
        config: bloc.state.distribution.copyWith(slackConfig: config),
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, SlackConfig>(
      selector: (s) => _slack(s.distribution.slackConfig),
      builder: (_, slack) {
        return AppCard(
          title: 'Slack Webhook',
          description:
              'Paste the Web Request URL from your Slack Workflow trigger. '
              'When Google Drive upload completes, Fluship will POST build '
              'metadata (version, platform, status, app, artifacts link) to this URL.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) => _updateSlack(
                slack.copyWith(webhookUrl: value.trim().isEmpty ? null : value),
              ),
              hint: 'https://hooks.slack.com/triggers/T.../...',
              initialValue: slack.webhookUrl,
              label: 'Web Request URL',
            ),
          ],
        );
      },
    );
  }
}
