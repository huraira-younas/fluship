import 'dart:io' show File;

import 'package:fluship/services/pipeline/resolver/distribution_step_kind.dart';
import 'package:path/path.dart' as p;

import '../whatsapp/whatsapp_message_builder.dart';
import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';
import '../whatsapp/whatsapp_client.dart';

/// Sends the run summary and the pipeline log to the owner of the agent key.
///
/// Build files are not attached: the Agent Platform caps a file at 16 MB,
/// so they are listed by name and reached through the published links.
class const WhatsAppHandler({
  final WhatsAppMessageBuilder messageBuilder = const WhatsAppMessageBuilder(),
  required final WhatsAppClient client,
}) implements DistributionHandler {
  static final _unsafeFileChars = RegExp(r'[^A-Za-z0-9._+-]+');

  @override
  String get name => 'WhatsApp';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final config = context.config.whatsappConfig;
    if (config == null || !config.enabled) {
      return DistributionResult.skipped('WhatsApp summary is disabled.');
    }

    final token = config.apiKey?.trim() ?? '';
    if (token.isEmpty) {
      return DistributionResult.skipped('Agent API key is not set.');
    }

    final recipient = config.recipientId?.trim() ?? '';
    if (recipient.isEmpty) {
      return DistributionResult.skipped(
        'Agent is not connected. Press Connect in Settings.',
      );
    }

    final snapshot = context.snapshot;
    final summary = messageBuilder.build(
      ownStepName: DistributionStepKind.whatsapp.command,
      files: await _fileEntries(snapshot.collectedArtifacts),
      snapshot,
    );

    try {
      await client.sendText(token: token, to: recipient, body: summary);
    } catch (error) {
      return DistributionResult.failed('Could not send the summary: $error');
    }

    final logPath = snapshot.logFilePath.trim();
    final log = logPath.isEmpty ? null : File(logPath);
    if (log == null || !await log.exists()) {
      return DistributionResult.success(
        'Summary sent to WhatsApp. No log file was available to attach.',
      );
    }

    if (await log.length() > WhatsAppLimits.maxDocumentBytes) {
      return DistributionResult.success(
        'Summary sent to WhatsApp. The log is over 16 MB and was not attached.',
      );
    }

    final tag =
        '${snapshot.appName} v${snapshot.version}+${snapshot.buildNumber}';

    try {
      final mediaId = await client.uploadDocument(
        mimeType: 'text/plain',
        path: logPath,
        token: token,
      );

      await client.sendDocument(
        fileName: '${tag.replaceAll(_unsafeFileChars, '_')}-logs.txt',
        caption: 'Pipeline log · $tag',
        mediaId: mediaId,
        to: recipient,
        token: token,
      );
    } catch (error) {
      return DistributionResult.failed(
        'Summary sent, but the log could not be attached: $error',
      );
    }

    return DistributionResult.success('Summary and log sent to WhatsApp.');
  }

  Future<List<WhatsAppFileEntry>> _fileEntries(List<String> paths) async {
    final entries = <WhatsAppFileEntry>[];
    for (final path in [...paths]..sort()) {
      var bytes = 0;
      try {
        bytes = await File(path).length();
      } catch (_) {}
      entries.add((name: p.basename(path), bytes: bytes));
    }
    return entries;
  }
}
