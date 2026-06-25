import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../drive/drive_upload_outcome.dart';
import '../models/distribution_result.dart';
import '../email/report_html_builder.dart';
import '../contracts/email_client.dart';
import '../drive/drive_uploader.dart';
import 'dart:io' show Directory, File;

class GoogleDriveHandler implements DistributionHandler {
  const GoogleDriveHandler({
    required this.emailClient,
    required this.htmlBuilder,
    required this.uploader,
  });

  final ReportHtmlBuilder htmlBuilder;
  final EmailClient emailClient;
  final DriveUploader uploader;

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

    final artifactsDir = context.snapshot.artifactsDir.trim();
    if (artifactsDir.isEmpty) {
      return DistributionResult.skipped(
        'Artifact output directory is unavailable.',
      );
    }

    if (!await _hasArtifacts(artifactsDir)) {
      return DistributionResult.skipped('No artifact files found to upload.');
    }

    final snapshot = context.snapshot;
    DriveUploadOutcome upload;

    try {
      upload = await uploader.upload(
        buildNumber: snapshot.buildNumber,
        artifactsDir: artifactsDir,
        appName: snapshot.appName,
        version: snapshot.version,
        driveConfig: drive,
        onFileUploaded: (name) => context.logger.logLine(
          DistributionResult.success('[drive] uploading: $name\n'),
        ),
      );
    } catch (error) {
      return DistributionResult.failed('Google Drive upload failed: $error');
    }

    final emailResult = await _sendDriveLinkEmail(
      context: context,
      upload: upload,
    );

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

    final versionTag =
        snapshot.version.isNotEmpty && snapshot.buildNumber.isNotEmpty
        ? ' v${snapshot.version}+${snapshot.buildNumber}'
        : '';
    final subject = '📦 $label Build Ready$versionTag — Download Link';

    try {
      await emailClient.send(
        EmailMessage(
          recipients: recipients,
          password: gmailPass,
          sender: gmailUser,
          subject: subject,
          html: html,
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

  Future<bool> _hasArtifacts(String artifactsDir) async {
    final dir = Directory(artifactsDir);
    if (!await dir.exists()) return false;

    await for (final entity in dir.list()) {
      if (entity is File) return true;
    }

    return false;
  }
}
