import 'dart:io';

import '../../io_helpers.dart';
import '../../progress/progress_state.dart';

void main() {
  final root = Directory.systemTemp.createTempSync('fluship-progress-');
  try {
    final path = pathJoin(root.path, 'progress.json');
    final started = DateTime.utc(2026, 8, 25, 1, 0, 0);
    saveProgressState(
      path,
      PipelineProgressState(
        app: 'Reelstay',
        version: '1.8.2',
        buildNumber: '8206',
        now: 'buildSplits',
        jobStartedAt: started,
        runStartedAt: started,
      ),
    );
    final loaded = loadProgressState(path);
    _check(loaded.app == 'Reelstay', 'app');
    _check(loaded.now == 'buildSplits', 'now');
    _check(loaded.jobStartedAt == started, 'job start');

    patchUploadProgress(
      path: path,
      upload: const UploadProgressInfo(
        id: 'distDrive',
        file: 'app.apk',
        bytes: 50,
        total: 100,
        percent: 50,
      ),
    );
    final withUpload = loadProgressState(path);
    _check(withUpload.upload?.percent == 50, 'percent');
    _check(withUpload.upload?.label == '50% app.apk', 'label');

    writeProgressIdle(path);
    final idle = loadProgressState(path);
    _check(idle.idle, 'idle');
    _check(idle.now.isEmpty, 'cleared now');
    _check(idle.upload == null, 'cleared upload');

    final kept = applyBoardUpdate(
      existing: withUpload.copyWith(now: 'distDrive'),
      now: started.add(const Duration(minutes: 1)),
    );
    _check(kept.now == 'distDrive', 'omit current keeps now');
    _check(kept.upload?.percent == 50, 'keep upload');

    final cleared = applyBoardUpdate(
      existing: kept,
      now: started.add(const Duration(minutes: 2)),
      current: 'slackNotify',
    );
    _check(cleared.now == 'slackNotify', 'new current');
    _check(cleared.upload == null, 'clear upload on step change');

    // A new run must not inherit the previous run's rows or run clock.
    saveProgressState(
      path,
      PipelineProgressState(
        app: 'Reelstay',
        now: 'buildSplits',
        selected: const ['clean', 'buildSplits'],
        done: const ['clean'],
        results: const {'clean': 'ok', 'buildSplits': 'fail'},
        times: const {'clean': '1.2s'},
        runStartedAt: started,
      ),
    );
    resetProgressForRun(path);
    final fresh = loadProgressState(path);
    _check(fresh.done.isEmpty, 'reset done');
    _check(fresh.results.isEmpty, 'reset results');
    _check(fresh.times.isEmpty, 'reset times');
    _check(fresh.selected.isEmpty, 'reset selected');
    _check(fresh.runStartedAt == null, 'reset run clock');
    _check(fresh.now.isEmpty, 'reset now');

    final firstBoard = applyBoardUpdate(
      existing: fresh,
      now: started.add(const Duration(hours: 3)),
      selected: const ['clean', 'buildAab'],
      current: 'clean',
    );
    _check(firstBoard.results.isEmpty, 'first board has no stale results');
    _check(firstBoard.elapsedRun == '0s', 'first board run clock starts now');

    _check(formatElapsed(const Duration(seconds: 9)) == '9s', 'seconds');
    _check(formatElapsed(const Duration(seconds: 125)) == '2m5s', 'minutes');
    _check(uploadGateChanges(), 'gate');
  } finally {
    root.deleteSync(recursive: true);
  }
  stdout.writeln('progress state tests: ok');
}

bool uploadGateChanges() {
  final gate = ProgressWriteGate(minGap: const Duration(milliseconds: 250));
  final t0 = DateTime.utc(2026, 1, 1);
  if (!gate.allow(10, t0)) return false;
  if (gate.allow(10, t0.add(const Duration(milliseconds: 10)))) return false;
  if (!gate.allow(11, t0.add(const Duration(milliseconds: 10)))) return false;
  return gate.allow(11, t0.add(const Duration(milliseconds: 300)));
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
