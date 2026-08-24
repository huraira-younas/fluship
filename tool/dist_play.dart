import 'dart:io';

import 'package:fluship/services/distribution/play_store/play_store_uploader.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';

import 'pipeline_picker/dist/dist_cli.dart';
import 'pipeline_picker/dist/dist_logger.dart';
import 'pipeline_picker/dist/dist_progress.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress_state.dart';

Future<void> main(List<String> args) async {
  await runDistMain(args: args, usage: _usage, run: _run);
}

Future<void> _run(Map<String, String> parsed) async {
  final agent = loadAgentJson(parsed);
  final track = (parsed['track'] ?? asString(agent.cache['playTrack'])).trim();
  final aab = resolveOneArtifact(
    explicit: parsed['aab'],
    outputDir: parsed['output-dir'] ?? '',
    extension: '.aab',
  );
  final failure = playValidation(
    saJsonPath: secretString(agent.secrets, 'playSaJsonPath'),
    packageName: secretString(agent.secrets, 'playPackageName'),
    aabPath: aab ?? '',
    track: track,
  );
  if (failure != null) {
    stderr.writeln(failure.message);
    exitCode = failure.code;
    return;
  }

  final notes = parsed['notes'] ?? asString(agent.cache['releaseNotes']);
  final gate = ProgressWriteGate();
  final progressPath = parsed['progress'] ?? '';
  final id = track == 'internal' ? 'distPlayInternal' : 'distPlayProduction';

  final uploaded = await const GooglePlayPublisherUploader().upload(
    distribution: track == 'internal'
        ? PlayStoreDistribution.internal
        : PlayStoreDistribution.production,
    packageName: secretString(agent.secrets, 'playPackageName'),
    saJsonPath: secretString(agent.secrets, 'playSaJsonPath'),
    aabPath: aab!,
    releaseNotes: notes.trim().isEmpty ? null : notes.trim(),
    logger: const StdoutDistributionLogger(),
    onProgress: (bytes, total, fileName) => reportCliUpload(
      gate: gate,
      progressPath: progressPath,
      prefix: 'play',
      id: id,
      bytes: bytes,
      total: total,
      fileName: fileName,
      fileIndex: 1,
      fileCount: 1,
    ),
  );

  stdout.writeln('Uploaded to Play Store ($track): $uploaded');
}

const _usage = '''
Upload a collected AAB to Google Play.

  dart run tool/dist_play.dart --aab <file.aab> --track production|internal

Reads playSaJsonPath and playPackageName from .fluship-agent/secrets.json.
''';
