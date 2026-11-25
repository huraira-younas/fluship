import 'package:fluship/services/pipeline/pipeline.dart';

import 'dart:io' show File;

import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';
import '../email/report_html_builder.dart';
import '../contracts/email_client.dart';

class const ReportEmailHandler({
  required final ReportHtmlBuilder _htmlBuilder,
  required final EmailClient _emailClient,
}) implements DistributionHandler {
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
    final totalElapsed = PipelineUtils.formatPipelineDuration(
      snapshot.totalElapsed,
    );
    final steps = _htmlBuilder.stepsFromPipelineViews(snapshot.steps);
    final html = _htmlBuilder.build(
      buildNumber: snapshot.buildNumber,
      platforms: snapshot.platforms,
      success: snapshot.success,
      theme: context.emailTheme,
      appName: snapshot.appName,
      version: snapshot.version,
      totalElapsed: totalElapsed,
      steps: steps,
    );
    final text = _htmlBuilder.buildText(
      buildNumber: snapshot.buildNumber,
      platforms: snapshot.platforms,
      success: snapshot.success,
      appName: snapshot.appName,
      version: snapshot.version,
      totalElapsed: totalElapsed,
      steps: steps,
    );

    // Plain words only: a leading symbol in the subject reads as spam.
    final outcome = snapshot.success ? 'succeeded' : 'failed';
    final subject =
        '${snapshot.appName} v${snapshot.version}+${snapshot.buildNumber} '
        'build report: $outcome';

    try {
      await _emailClient.send(
        EmailMessage(
          attachmentPath: logPath,
          recipients: [recipient],
          password: gmailPass,
          sender: gmailUser,
          subject: subject,
          html: html,
          text: text,
        ),
      );

      return DistributionResult.success('Build report emailed to $recipient');
    } catch (error) {
      return DistributionResult.failed('Failed to email build report: $error');
    }
  }
}
