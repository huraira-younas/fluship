import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../drive/drive_upload_outcome.dart';
import '../models/distribution_result.dart';
import '../email/report_html_builder.dart';
import '../contracts/email_client.dart';
import '../slack/slack_notifier.dart';
import '../drive/drive_uploader.dart';

class const GoogleDriveHandler({
  required final EmailClient emailClient,
  required final ReportHtmlBuilder htmlBuilder,
  required final DriveUploader uploader,
  final SlackNotifier slackNotifier = const SlackNotifier(),
}) implements DistributionHandler {
  @override
  String get name => 'Google Drive';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final drive = context.config.driveConfig;
    if (drive == null || !drive.enabled) {
      return DistributionResult.skipped('Google Drive is disabled.');
    }

    if (!(drive.oauthJson?.trim().isNotEmpty ?? false)) {
      return DistributionResult.skipped('OAuth client JSON is not configured.');
    }

    // Drive is the QA channel, and only an APK is installable from a link.
    final snapshot = context.snapshot;
    final apks = snapshot.artifactsWithExtension('.apk');
    if (apks.isEmpty) {
      return DistributionResult.skipped('No APK was collected in this run.');
    }

    DriveUploadOutcome upload;

    try {
      var fileIndex = 0;
      upload = await uploader.upload(
        files: apks,
        buildNumber: snapshot.buildNumber,
        appName: snapshot.appName,
        version: snapshot.version,
        driveConfig: drive,
        onFileUploaded: (name) async {
          fileIndex++;
          await context.logger.logLine(
            DistributionResult.success('Google Drive: uploading $name\n'),
          );
        },
        onProgress: (bytes, total, name) {
          context.notifyUploadProgress(
            fileIndex: fileIndex == 0 ? 1 : fileIndex,
            fileCount: apks.length,
            channel: .drive,
            fileName: name,
            bytes: bytes,
            total: total,
          );
        },
      );
    } catch (error) {
      return DistributionResult.failed('Google Drive upload failed: $error');
    }

    context.publishLink(name, upload.link);

    final emailResult = await _sendDriveLinkEmail(
      context: context,
      upload: upload,
    );

    await _notifySlack(context: context, upload: upload);

    if (emailResult != null) return emailResult;

    return DistributionResult.success('Uploaded to Drive: ${upload.link}');
  }

  Future<DistributionResult?> _sendDriveLinkEmail({
    required DistributionContext context,
    required DriveUploadOutcome upload,
  }) async {
    final report = context.config.reportRecipient;
    if (report == null) return null;

    final recipients = [
      for (final entry in report.emails)
        if (entry.enabled && entry.email.trim().isNotEmpty) entry.email.trim(),
    ];
    if (recipients.isEmpty) {
      return null;
    }

    final gmailUser = report.gmailAddress?.trim() ?? '';
    final gmailPass = report.appPassword?.trim() ?? '';
    if (gmailUser.isEmpty || gmailPass.isEmpty) {
      return null;
    }

    final snapshot = context.snapshot;
    final label = upload.label.trim().isNotEmpty
        ? upload.label.trim()
        : snapshot.appName;

    final html = htmlBuilder.buildDriveLink(
      buildNumber: snapshot.buildNumber,
      fileNames: upload.fileNames,
      theme: context.emailTheme,
      version: snapshot.version,
      link: upload.link,
      label: label,
    );
    final text = htmlBuilder.buildDriveLinkText(
      buildNumber: snapshot.buildNumber,
      fileNames: upload.fileNames,
      version: snapshot.version,
      link: upload.link,
      label: label,
    );

    final versionTag =
        snapshot.version.isNotEmpty && snapshot.buildNumber.isNotEmpty
        ? ' v${snapshot.version}+${snapshot.buildNumber}'
        : '';
    // Plain words only: an emoji plus "Download Link" reads as phishing.
    final subject = '$label$versionTag build uploaded to Google Drive';

    try {
      await emailClient.send(
        EmailMessage(
          recipients: recipients,
          password: gmailPass,
          sender: gmailUser,
          subject: subject,
          html: html,
          text: text,
        ),
      );

      return DistributionResult.success(
        'Uploaded to Drive and emailed ${recipients.length} recipient(s).',
      );
    } catch (error) {
      return DistributionResult.failed(
        'Uploaded to ${upload.link} but email failed: $error',
      );
    }
  }

  Future<void> _notifySlack({
    required DistributionContext context,
    required DriveUploadOutcome upload,
  }) async {
    final slack = context.config.slackConfig;
    if (slack == null || !slack.enabled || !slack.canSend) return;

    final snapshot = context.snapshot;
    final config = context.config;
    final webhook = slack.webhookUrl?.trim() ?? '';
    if (webhook.isEmpty) return;

    try {
      await slackNotifier.send(
        webhookUrl: webhook,
        body: SlackNotifier.payload(
          buildNumber: snapshot.buildNumber,
          platform: snapshot.platforms,
          version: snapshot.version,
          artifacts: upload.link,
          app: snapshot.appName,
          status: SlackNotifier.statusLine(
            playStore:
                config.canSendToPlayStore &&
                config.playstore?.distribution != null,
            appStore:
                config.canSendToAppStore && config.appstore?.enabled == true,
          ),
        ),
      );
    } catch (_) {}
  }
}
