import 'dart:io';

import 'package:fluship/services/distribution/app_store/app_store_uploader.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';

import 'pipeline_picker/dist/dist_cli.dart';
import 'pipeline_picker/dist/dist_logger.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress_state.dart';

Future<void> main(List<String> args) async {
  await runDistMain(args: args, usage: _usage, run: _run);
}

Future<void> _run(Map<String, String> parsed) async {
  final agent = loadAgentJson(parsed);
  final ipa = resolveOneArtifact(
    explicit: parsed['ipa'],
    outputDir: parsed['output-dir'] ?? '',
    extension: '.ipa',
  );
  final failure = appStoreValidation(
    isMacOS: Platform.isMacOS,
    issuerId: secretString(agent.secrets, 'appStoreIssuerId'),
    apiKeyId: secretString(agent.secrets, 'appStoreApiKeyId'),
    apiKeyPath: secretString(agent.secrets, 'appStoreApiKeyPath'),
    ipaPath: ipa ?? '',
  );
  if (failure != null) {
    stderr.writeln(failure.message);
    exitCode = failure.code;
    return;
  }

  final progressPath = parsed.containsKey('progress')
      ? resolveAgentPath(parsed['progress'], 'progress.json')
      : '';
  final gate = ProgressWriteGate();
  final ipaName = fileNameOf(ipa!);

  final uploaded = await const ITmsTransporterUploader().upload(
    ipaPath: ipa,
    appstore: IosConfig(
      enabled: true,
      issuerId: secretString(agent.secrets, 'appStoreIssuerId'),
      apiKeyId: secretString(agent.secrets, 'appStoreApiKeyId'),
      apiKeyPath: secretString(agent.secrets, 'appStoreApiKeyPath'),
    ),
    logger: const StdoutDistributionLogger(),
    onLine: (line, percent) {
      if (percent == null || !gate.allow(percent, DateTime.now())) return;
      stdout.writeln('[appstore] $percent%  $ipaName');
      if (progressPath.isEmpty) return;
      patchUploadProgress(
        path: progressPath,
        upload: UploadProgressInfo(
          id: 'distAppStore',
          file: ipaName,
          percent: percent,
          fileIndex: 1,
          fileCount: 1,
        ),
        note: line,
      );
    },
  );

  stdout.writeln('Uploaded to App Store: $uploaded');
}

const _usage = '''
Upload a collected IPA to App Store Connect.

  dart run tool/dist_app_store.dart --ipa <file.ipa>

Reads App Store issuer, key id, and .p8 path from secrets.json. macOS only.
''';
