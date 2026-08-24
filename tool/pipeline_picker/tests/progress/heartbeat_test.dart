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
  _check(ready.message.contains('Upload 30% app.apk'), 'upload');

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

  stdout.writeln('heartbeat tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
