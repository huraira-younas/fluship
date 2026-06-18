import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/distribution_recipients_panel.dart';

class ReportsRecipients extends StatelessWidget {
  const ReportsRecipients({super.key});

  static ReportRecipientConfig _report(ReportRecipientConfig? config) =>
      config ?? const ReportRecipientConfig();

  void _updateReport(ReportRecipientConfig config) {
    final bloc = getIt<ConfigBloc>();

    bloc.add(
      UpdateConfig(
        onError: (error) => AppToast.error(error.message),
        config: bloc.state.distribution.copyWith(reportRecipient: config),
      ),
    );
  }

  void _updateEmails(List<DistributionEmail> emails) {
    final distribution = getIt<ConfigBloc>().state.distribution;
    final report = _report(distribution.reportRecipient);

    _updateReport(report.copyWith(emails: emails));
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigBloc, ConfigState, DistributionConfigModel>(
      selector: (s) => s.distribution,
      builder: (_, distribution) {
        final report = _report(distribution.reportRecipient);

        return AppCard(
          title: 'Reports & Recipients',
          description:
              '• Enter your Gmail address and an App Password from Google Account → Security → 2-Step Verification.\n'
              '• Set the report recipient who receives the build summary after each run.\n'
              '• Add distribution recipients with a name and email for automated sharing.',
          spacing: 15,
          children: [
            AppTextField.label(
              onChanged: (value) =>
                  _updateReport(report.copyWith(gmailAddress: value)),
              initialValue: report.gmailAddress,
              keyboardType: .emailAddress,
              label: 'Gmail address',
              hint: 'you@gmail.com',
            ),
            AppTextField.label(
              onChanged: (value) =>
                  _updateReport(report.copyWith(appPassword: value)),
              initialValue: report.appPassword,
              hint: '••••••••••••••••',
              label: 'App password',
              obscureText: true,
            ),
            AppTextField.label(
              onChanged: (value) =>
                  _updateReport(report.copyWith(reportRecipient: value)),
              initialValue: report.reportRecipient,
              keyboardType: .emailAddress,
              hint: 'reports@example.com',
              label: 'Report recipient',
            ),
            DistributionRecipientsPanel(
              onChanged: _updateEmails,
              emails: report.emails,
            ),
          ],
        );
      },
    );
  }
}
