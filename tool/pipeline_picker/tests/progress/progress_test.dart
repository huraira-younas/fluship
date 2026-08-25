import 'dart:io';

import '../../progress/progress.dart';

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

  final uploadBoard = formatProgressBoard(
    selected: const ['distDrive'],
    done: const [],
    current: 'distDrive',
    uploadLabel: '30% app.apk',
    note: 'uploading',
  );
  _check(uploadBoard.contains('upload: 30% app.apk'), 'upload line');
  _check(uploadBoard.contains('note: uploading'), 'note line');

  _check(
    !formatProgressBoard(
      selected: const ['clean'],
      done: const ['clean'],
      current: '',
    ).contains('\u2014'),
    'board em-dash',
  );

  final framed = formatProgressBoard(
    selected: const ['bumpVersion', 'buildSplits'],
    done: const ['bumpVersion'],
    current: 'buildSplits',
    times: const {'bumpVersion': '0.6s'},
    runElapsed: '2m30s',
  );
  final frameLines = framed.split('\n');
  final widest = frameLines.fold(0, (w, l) => l.length > w ? l.length : w);
  _check(frameLines.every((l) => l.length == widest), 'every line is boxed');
  _check(frameLines.first.startsWith('\u250c'), 'top corner');
  _check(frameLines.last.startsWith('\u2514'), 'bottom corner');
  _check(
    frameLines.where((l) => l.startsWith('\u251c')).length == 2,
    'title and footer dividers',
  );
  _check(framed.contains('run 2m30s'), 'run elapsed');
  _check(framed.contains('1/2 done  50%  run 2m30s'), 'footer order');
  _check(framed.contains(progressBar(50)), 'progress bar');

  _check(progressBar(0) == '\u2591' * 14, 'empty bar');
  _check(progressBar(100) == '\u2588' * 14, 'full bar');
  _check(
    boardProgress(
          selected: const ['a', 'b', 'c', 'd'],
          done: const ['a', 'b', 'c'],
          current: 'c',
        ).done ==
        2,
    'current job is not counted done',
  );

  final wide = formatProgressBoard(
    selected: const ['bumpVersion', 'buildSplits'],
    done: const ['bumpVersion', 'buildSplits'],
    current: '',
    times: const {'bumpVersion': '0.6s', 'buildSplits': '2m26s'},
  );
  _check(wide.contains('  0.6s'), 'short time is right aligned');
  _check(wide.contains(' 2m26s'), 'long time sets the column');

  final capped = formatProgressBoard(
    selected: const ['bumpVersion', 'clean', 'pubGet', 'format', 'analyze'],
    done: const ['bumpVersion', 'clean', 'pubGet'],
    current: 'format',
    maxRows: 3,
  );
  _check(capped.contains('+2 more'), 'hidden count');
  _check(RegExp(r'NOW\s+Format Dart').hasMatch(capped), 'window keeps now');
  _check(!capped.contains('Set app version'), 'oldest row dropped');
  _check(capped.contains('3/5 done'), 'count stays full');

  final live = formatProgressBoard(
    selected: const ['bumpVersion', 'buildSplits'],
    done: const ['bumpVersion'],
    current: 'buildSplits',
    nowElapsed: '3m34s',
  );
  _check(live.contains('now: Build split APKs  3m34s'), 'current job clock');

  final noisy = formatProgressBoard(
    selected: const ['clean'],
    done: const [],
    current: 'clean',
    note: 'gradle said\n${'boom ' * 40}',
  );
  final noisyNote = _noteText(noisy);
  _check(noisyNote.startsWith('gradle said boom'), 'note newlines join');
  _check(noisyNote.endsWith('.'), 'note is clipped');
  _check(noisyNote.length <= 70, 'a note cannot widen the board');

  const long = [
    'preCommit',
    'prePull',
    'pubUpgrade',
    'format',
    'analyze',
    'test',
    'postCommit',
    'postPush',
    'whatsappShare',
  ];
  final ping = formatPingBoard(
    selected: long,
    done: const ['preCommit', 'prePull', 'pubUpgrade', 'format', 'analyze'],
    current: 'test',
    results: const {'preCommit': 'ok', 'prePull': 'ok'},
    times: const {'prePull': '3.7s'},
    appName: 'Reelstay',
    version: '2.0.1',
    buildNumber: '2001',
    runElapsed: '7m26s',
    nowElapsed: '3m52s',
    note: 'compiling',
  );
  // WhatsApp markdown, never a monospace block: that renders large and wide on
  // a phone, so it wraps whatever we do to the width.
  _check(!ping.contains('```'), 'no monospace block');
  _check(!ping.contains('\u2502'), 'no frame');
  _check(ping.startsWith('*FLUSHIP  Reelstay  v2.0.1+2001*'), 'bold title');
  _check(ping.contains('- DONE  Pull latest from git  3.7s'), 'done row');
  _check(ping.contains('- *NOW  Run tests  3m52s*'), 'now row is bold');
  _check(ping.contains('- WAIT  Push to git'), 'waiting row');
  _check(ping.contains('- WAIT  Send PDF and APKs on WhatsApp'), 'full name');
  _check(ping.contains('_5/9 done  56%  run 7m26s_'), 'italic summary');
  _check(ping.contains('note: compiling'), 'note line');

  final pingCapped = formatPingBoard(
    selected: List.generate(20, (i) => 'format'),
    done: const [],
    current: '',
  );
  _check(pingCapped.contains('- +8 more'), 'long run is capped');

  stdout.writeln('progress tests: ok');
}

String _noteText(String board) {
  final line = board.split('\n').firstWhere((l) => l.contains('note: '));
  final start = line.indexOf('note: ') + 'note: '.length;
  return line.substring(start, line.lastIndexOf('\u2502')).trim();
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
