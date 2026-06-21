import 'package:fluship/services/pipeline/pipeline.dart';
import 'dart:io' show File;

import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';
import '../email/report_html_builder.dart';
import '../contracts/email_client.dart';

class ReportEmailHandler implements DistributionHandler {
  const ReportEmailHandler({
    required this._htmlBuilder,
    required this._emailClient,
  });

  final ReportHtmlBuilder _htmlBuilder;
  final EmailClient _emailClient;

  @override
  String get name => 'Build Report Email';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final report = context.config.reportRecipient;
    if (report == null || !report.buildReport) {
      return DistributionResult.skipped('Build report is disabled.');
    }

    final recipient = report.reportRecipient?.trim() ?? '';
    if (recipient.isEmpty) {
      return DistributionResult.skipped('Report recipient email is not set.');
    }

    final gmailUser = report.gmailAddress?.trim() ?? '';
    final gmailPass = report.appPassword?.trim() ?? '';
    if (gmailUser.isEmpty || gmailPass.isEmpty) {
      return DistributionResult.skipped(
        'Gmail credentials are not configured.',
      );
    }

    final logPath = context.snapshot.logFilePath.trim();
    if (logPath.isEmpty) {
      return DistributionResult.skipped(
        'Pipeline log file path is unavailable.',
      );
    }

    if (!await File(logPath).exists()) {
      return DistributionResult.skipped('Pipeline log file was not found.');
    }

    final snapshot = context.snapshot;
    final html = _htmlBuilder.build(
      totalElapsed: PipelineUtils.formatPipelineDuration(snapshot.totalElapsed),
      steps: _htmlBuilder.stepsFromPipelineViews(snapshot.steps),
      buildNumber: snapshot.buildNumber,
      platforms: snapshot.platforms,
      success: snapshot.success,
      theme: context.emailTheme,
      appName: snapshot.appName,
      version: snapshot.version,
    );

    final statusEmoji = snapshot.success ? '✓' : '✗';
    final subject =
        '$statusEmoji ${snapshot.appName} '
        'v${snapshot.version}+${snapshot.buildNumber} — Build Report';

    try {
      await _emailClient.send(
        EmailMessage(
          attachmentPath: logPath,
          recipients: [recipient],
          password: gmailPass,
          sender: gmailUser,
          subject: subject,
          html: html,
        ),
      );

      return DistributionResult.success('Build report emailed to $recipient');
    } catch (error) {
      return DistributionResult.failed('Failed to email build report: $error');
    }
  }
}
