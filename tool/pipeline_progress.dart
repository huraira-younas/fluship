import 'dart:io';

import 'pipeline_picker/progress/progress.dart';
import 'pipeline_picker/progress/progress_state.dart';

/// Prints the live pipeline board. The agent must run this before the first
/// job and again after every job, then paste the stdout into chat.
void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final progressPath = _value(args, '--progress');
  final existing = progressPath.isEmpty
      ? const PipelineProgressState()
      : loadProgressState(progressPath);
  final state = applyBoardUpdate(
    existing: existing,
    now: DateTime.now().toUtc(),
    current: args.contains('--current') ? _value(args, '--current') : null,
    app: _value(args, '--app'),
    version: _value(args, '--version'),
    buildNumber: _value(args, '--build'),
    note: _value(args, '--note'),
    selected: _csv(args, '--selected'),
    done: _csv(args, '--done'),
    results: _map(args, '--results'),
    times: _map(args, '--times'),
  );

  if (progressPath.isNotEmpty) {
    saveProgressState(progressPath, state);
  }

  final logPath = _value(args, '--log');
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
    ),
  );
}

const _help = '''
Print the live Fluship pipeline progress board.

Usage:
  dart tool/pipeline_progress.dart --selected id1,id2 --current id2 --done id1 --results id1=ok --times id1=0.3s --app Reelstay --version 1.8.2 --build 8205 --progress .fluship-agent/progress.json --log logs.txt
''';

String _value(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index < 0 || index + 1 >= args.length) return '';
  return args[index + 1];
}

List<String> _csv(List<String> args, String flag) {
  return [
    for (final part in _value(args, flag).split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

Map<String, String> _map(List<String> args, String flag) {
  final out = <String, String>{};
  for (final part in _csv(args, flag)) {
    final split = part.indexOf('=');
    if (split <= 0) continue;
    out[normalizeStepId(part.substring(0, split))] = part
        .substring(split + 1)
        .trim();
  }
  return out;
}
