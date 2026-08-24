import 'dart:io';

import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress.dart';
import 'pipeline_picker/progress/progress_state.dart';

/// Prints the live pipeline board. The agent must run this before the first
/// job and again after every job, then paste the stdout into chat.
void main(List<String> args) {
  final flags = parseCliFlags(args);
  if (flags.containsKey('help')) {
    stdout.writeln(_help);
    return;
  }

  final progressPath = flags.containsKey('progress')
      ? resolveAgentPath(flags['progress'], 'progress.json')
      : '';
  final existing = progressPath.isEmpty
      ? const PipelineProgressState()
      : loadProgressState(progressPath);
  final state = applyBoardUpdate(
    existing: existing,
    now: DateTime.now().toUtc(),
    // An absent --current keeps the existing job. An empty one clears it.
    current: flags.containsKey('current') ? flagString(flags, 'current') : null,
    app: flagString(flags, 'app'),
    version: flagString(flags, 'version'),
    buildNumber: flagString(flags, 'build'),
    note: flagString(flags, 'note'),
    selected: csvValues(flagString(flags, 'selected')),
    done: csvValues(flagString(flags, 'done')),
    results: _pairs(flagString(flags, 'results')),
    times: _pairs(flagString(flags, 'times')),
  );

  if (progressPath.isNotEmpty) {
    saveProgressState(progressPath, state);
  }

  final logPath = flagString(flags, 'log');
  if (logPath.isNotEmpty) {
    File(logPath).writeAsStringSync(
      '${progressSnapshotLine(state)}\n',
      mode: FileMode.append,
    );
  }

  stdout.writeln(
    formatProgressBoard(
      selected: state.selected,
      done: state.done,
      current: state.now,
      results: state.results,
      times: state.times,
      appName: state.app,
      version: state.version,
      buildNumber: state.buildNumber,
      uploadLabel: state.upload?.label ?? '',
      note: state.note,
      runElapsed: state.elapsedRun,
    ),
  );
}

const _help = '''
Print the live Fluship pipeline progress board.

Usage:
  dart tool/pipeline_progress.dart --selected id1,id2 --current id2 --done id1 --results id1=ok --times id1=0.3s --app Reelstay --version 1.8.2 --build 8205 --progress .fluship-agent/progress.json --log logs.txt
''';

Map<String, String> _pairs(String raw) {
  final out = <String, String>{};
  for (final part in csvValues(raw)) {
    final split = part.indexOf('=');
    if (split <= 0) continue;
    out[normalizeStepId(part.substring(0, split))] = part
        .substring(split + 1)
        .trim();
  }
  return out;
}
