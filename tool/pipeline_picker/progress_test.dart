import 'dart:io';

import 'progress.dart';

void main() {
  _check(normalizeStepId('BumpVersion') == 'bumpVersion', 'normalize id');
  _check(humanStepName('clean') == 'Clean old build files', 'human clean');
  _check(humanStepName('buildAab') == 'Build Play bundle (AAB)', 'human aab');

  final lines = formatStepLines('Clean:ok:1s,BuildAab:fail:3m');
  _check(lines.contains('OK Clean old build files (1s)'), 'ok line');
  _check(lines.contains('FAIL Build Play bundle (AAB) (3m)'), 'fail line');
  _check(!lines.contains('Clean:ok:1s,BuildAab'), 'no packed dump');

  final start = formatProgressBoard(
    selected: const ['bumpVersion', 'clean', 'pubUpgrade'],
    done: const [],
    current: 'bumpVersion',
  );
  _check(start.contains('1. [NOW] Set app version'), 'now first');
  _check(start.contains('2. [WAIT] Clean old build files'), 'wait later');
  _check(start.contains('3. [WAIT] Upgrade packages'), 'wait last');

  final mid = formatProgressBoard(
    selected: const ['bumpVersion', 'clean'],
    done: const ['bumpVersion'],
    current: 'clean',
    results: const {'bumpVersion': 'ok'},
  );
  _check(mid.contains('1. [OK] Set app version'), 'done result');
  _check(mid.contains('2. [NOW] Clean old build files'), 'now second');

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
