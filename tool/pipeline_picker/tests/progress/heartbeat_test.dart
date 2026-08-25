import 'dart:io';

import '../../progress/heartbeat.dart';
import '../../progress/progress_state.dart';

void main() {
  final start = DateTime.utc(2026, 8, 25, 1, 0, 0);
  final state = PipelineProgressState(
    app: 'Reelstay',
    version: '1.8.2',
    buildNumber: '8206',
    now: 'buildSplits',
    note: 'Compiling dart',
    selected: const ['bumpVersion', 'buildSplits', 'whatsappShare'],
    done: const ['bumpVersion'],
    results: const {'bumpVersion': 'ok'},
    times: const {'bumpVersion': '0.6s'},
    upload: const UploadProgressInfo(
      id: 'buildSplits',
      file: 'app.apk',
      percent: 30,
    ),
    jobStartedAt: start,
    runStartedAt: start,
  );

  final early = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(seconds: 179)),
  );
  _check(!early.shouldPing, 'no send before 180s');
  _check(early.skipReason == 'too-soon', 'too soon');

  final ready = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(seconds: 180)),
  );
  _check(ready.shouldPing, 'send at 180s');
  _check(ready.message.startsWith('*FLUSHIP  Reelstay  v1.8.2+8206*'), 'title');
  _check(ready.message.contains('- DONE  Set app version  0.6s'), 'done row');
  _check(ready.message.contains('- *NOW  Build split APKs  3m*'), 'now row');
  _check(ready.message.contains('- WAIT  Send PDF and APKs'), 'waiting row');
  _check(ready.message.contains('_1/3 done  33%  run 3m_'), 'summary');
  _check(ready.message.contains('upload: 30% app.apk'), 'upload');
  _check(ready.message.contains('note: Compiling dart'), 'note');
  _check(!ready.message.contains('\u2014'), 'no em-dash');

  // A monospace block renders large and wide on a phone, so it always wraps.
  _check(!ready.message.contains('```'), 'never a monospace block');

  final justBefore = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(milliseconds: 179999)),
  );
  _check(!justBefore.shouldPing, 'no send one ms before 180s');

  // The interval restarts when the previous send finished, not when it began.
  final afterSlowSend = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 200)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 379)),
  );
  _check(!afterSlowSend.shouldPing, 'second ping waits a full interval');

  final secondPing = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 200)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 380)),
  );
  _check(secondPing.shouldPing, 'second ping at 180s after the last send');

  final again = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 180)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 300)),
  );
  _check(!again.shouldPing, 'wait for next interval');

  final cleared = decideHeartbeat(
    state: const PipelineProgressState(now: '', idle: true),
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(minutes: 5)),
  );
  _check(!cleared.shouldPing, 'no send after now clears');

  final sending = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: true,
    ),
    now: start.add(const Duration(minutes: 5)),
  );
  _check(!sending.shouldPing, 'skip while sending');

  final share = decideHeartbeat(
    state: const PipelineProgressState(now: 'whatsappShare'),
    clock: HeartbeatClock(
      nowId: 'whatsappShare',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(minutes: 5)),
  );
  _check(!share.shouldPing, 'skip final share');

  final synced = syncHeartbeatClock(
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start,
      sending: false,
    ),
    state: const PipelineProgressState(now: 'distDrive'),
    now: start.add(const Duration(minutes: 1)),
  );
  _check(synced.nowId == 'distDrive', 'reset now');
  _check(synced.lastPingAt == null, 'reset ping clock');

  final longNote = decideHeartbeat(
    state: state.copyWith(note: 'gradle said\n${'boom ' * 40}'),
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(minutes: 3)),
  );
  _check(longNote.shouldPing, 'long note still pings');
  _check(longNote.message.contains('note: gradle said boom'), 'newlines join');
  final noteLine = longNote.message
      .split('\n')
      .firstWhere((line) => line.startsWith('note: '));
  _check(noteLine.length <= 'note: '.length + 70, 'note clipped');
  _check(noteLine.endsWith('.'), 'clip marker');

  stdout.writeln('heartbeat tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
