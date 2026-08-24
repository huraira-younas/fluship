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
    now: start.add(const Duration(seconds: 119)),
  );
  _check(!early.shouldPing, 'no send before 120s');
  _check(early.skipReason == 'too-soon', 'too soon');

  final ready = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(seconds: 120)),
  );
  _check(ready.shouldPing, 'send at 120s');
  _check(ready.message.contains('Reelstay'), 'app');
  _check(ready.message.contains('v1.8.2+8206'), 'version');
  _check(ready.message.contains('NOW'), 'now');
  _check(ready.message.contains('upload: 30% app.apk'), 'upload');

  // The ping carries the same board the agent pastes in chat.
  _check(ready.message.split('```').length == 3, 'one monospace block');
  _check(
    ready.message.contains('FLUSHIP  Reelstay  v1.8.2+8206'),
    'board title',
  );
  _check(RegExp(r'DONE\s+Set app version').hasMatch(ready.message), 'done row');
  _check(RegExp(r'WAIT\s+Send PDF').hasMatch(ready.message), 'wait row');
  _check(ready.message.contains('1/3 done'), 'board count');
  _check(ready.message.contains('run 2m'), 'run elapsed');
  _check(ready.message.contains('note: Compiling dart'), 'note');
  _check(!ready.message.contains('\u2014'), 'no em-dash');

  final justBefore = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(milliseconds: 119999)),
  );
  _check(!justBefore.shouldPing, 'no send one ms before 120s');

  // The interval restarts when the previous send finished, not when it began.
  final afterSlowSend = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 140)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 259)),
  );
  _check(!afterSlowSend.shouldPing, 'second ping waits a full interval');

  final secondPing = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 140)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 260)),
  );
  _check(secondPing.shouldPing, 'second ping at 120s after the last send');

  final again = decideHeartbeat(
    state: state,
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: start.add(const Duration(seconds: 120)),
      sending: false,
    ),
    now: start.add(const Duration(seconds: 200)),
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

  final fenced = decideHeartbeat(
    state: state.copyWith(note: 'gradle said ``` boom'),
    clock: HeartbeatClock(
      nowId: 'buildSplits',
      jobStartedAt: start,
      lastPingAt: null,
      sending: false,
    ),
    now: start.add(const Duration(minutes: 2)),
  );
  _check(fenced.shouldPing, 'fenced note still pings');
  _check(
    fenced.message.split('```').length == 3,
    'a fence inside the note cannot split the block',
  );
  _check(fenced.message.contains("''' boom"), 'note survives escaped');

  stdout.writeln('heartbeat tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
