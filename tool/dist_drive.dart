import 'dart:io';

import 'package:fluship/services/distribution/drive/drive_uploader.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';

import 'pipeline_picker/dist/dist_cli.dart';
import 'pipeline_picker/dist/dist_progress.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress_state.dart';

Future<void> main(List<String> args) async {
  await runDistMain(args: args, usage: _usage, run: _run);
}

Future<void> _run(Map<String, String> parsed) async {
  final agent = loadAgentJson(parsed);
  final files = resolveApks(
    explicit: csvValues(parsed['files'] ?? ''),
    outputDir: parsed['output-dir'] ?? '',
  );
  final failure = driveValidation(
    oauthJson: secretString(agent.secrets, 'driveOauthJson'),
    tokenJson: secretString(agent.secrets, 'driveTokenJson'),
    files: files,
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
  var fileIndex = 1;
  final fileCount = files.length;

  final outcome = await const GoogleDriveUploader().upload(
    files: files,
    buildNumber:
        parsed['build-number'] ?? asString(agent.cache['buildNumber'], '0'),
    appName: parsed['app-name'] ?? asString(agent.cache['appName'], 'Fluship'),
    version: parsed['version'] ?? asString(agent.cache['version'], '0.0.0'),
    driveConfig: GoogleDriveConfig(
      enabled: true,
      oauthJson: secretString(agent.secrets, 'driveOauthJson'),
      tokenJson: secretString(agent.secrets, 'driveTokenJson'),
      folderId: secretString(agent.secrets, 'driveFolderId'),
    ),
    onFileUploaded: (name) async {
      final idx = files.indexWhere((path) => fileNameOf(path) == name);
      if (idx >= 0) fileIndex = idx + 1;
      stdout.writeln('[drive] uploading: $name');
    },
    onProgress: (bytes, total, fileName) => reportCliUpload(
      gate: gate,
      progressPath: progressPath,
      prefix: 'drive',
      id: 'distDrive',
      bytes: bytes,
      total: total,
      fileName: fileName,
      fileIndex: fileIndex,
      fileCount: fileCount,
    ),
  );

  writeLastDrive(
    path: resolveAgentPath(parsed['last-drive'], 'last-drive.json'),
    link: outcome.link,
    fileNames: outcome.fileNames,
  );
  stdout.writeln('link: ${outcome.link}');
  stdout.writeln('Uploaded to Drive: ${outcome.link}');
}

const _usage = '''
Upload collected APKs to Google Drive.

  dart run tool/dist_drive.dart --output-dir <outputs>

Reads driveOauthJson, driveTokenJson, and driveFolderId from secrets.json.
''';
