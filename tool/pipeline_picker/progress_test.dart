import 'dart:io';

import 'progress.dart';

void main() {
  _check(normalizeStepId('BumpVersion') == 'bumpVersion', 'normalize id');
  _check(humanStepName('clean') == 'Clean old build files', 'human clean');
  _check(humanStepName('buildAab') == 'Build Play bundle (AAB)', 'human aab');

  final lines = formatStepLines('Clean:ok:1s,BuildAab:fail:3m');
  _check(lines.contains('DONE  Clean old build files  1s'), 'ok line');
  _check(lines.contains('FAIL  Build Play bundle (AAB)  3m'), 'fail line');
  _check(!lines.contains('Clean:ok:1s,BuildAab'), 'no packed dump');

  final start = formatProgressBoard(
    selected: const ['bumpVersion', 'clean', 'pubUpgrade'],
    done: const [],
    current: 'bumpVersion',
    appName: 'Reelstay',
    version: '1.8.2',
    buildNumber: '8205',
  );
  _check(start.contains('FLUSHIP  Reelstay  v1.8.2+8205'), 'title');
  _check(RegExp(r'NOW\s+Set app version').hasMatch(start), 'now first');
  _check(RegExp(r'WAIT\s+Clean old build files').hasMatch(start), 'wait later');
  _check(RegExp(r'WAIT\s+Upgrade packages').hasMatch(start), 'wait last');
  _check(start.contains('now: Set app version'), 'now footer');

  final mid = formatProgressBoard(
    selected: const ['bumpVersion', 'clean'],
    done: const ['bumpVersion'],
    current: 'clean',
    results: const {'bumpVersion': 'ok'},
    times: const {'bumpVersion': '0.3s'},
  );
  _check(RegExp(r'DONE\s+Set app version').hasMatch(mid), 'done result');
  _check(mid.contains('0.3s'), 'time');
  _check(RegExp(r'NOW\s+Clean old build files').hasMatch(mid), 'now second');
  _check(mid.contains('1/2 done'), 'count');

  _check(
    !formatProgressBoard(
      selected: const ['clean'],
      done: const ['clean'],
      current: '',
    ).contains('\u2014'),
    'board em-dash',
  );

  stdout.writeln('progress tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
