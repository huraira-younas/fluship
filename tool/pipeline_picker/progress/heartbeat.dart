import 'progress_state.dart';
import 'progress.dart';

class HeartbeatDecision {
  const HeartbeatDecision({
    required this.shouldPing,
    required this.message,
    this.skipReason = '',
  });

  final String skipReason;
  final bool shouldPing;
  final String message;
}

class HeartbeatClock {
  const HeartbeatClock({
    required this.jobStartedAt,
    required this.lastPingAt,
    required this.sending,
    required this.nowId,
  });

  final DateTime? jobStartedAt;
  final DateTime? lastPingAt;
  final bool sending;
  final String nowId;

  HeartbeatClock resetJob(String nowId, DateTime startedAt) {
    return HeartbeatClock(
      jobStartedAt: startedAt,
      lastPingAt: null,
      sending: sending,
      nowId: nowId,
    );
  }

  HeartbeatClock markedPing(DateTime at) {
    return HeartbeatClock(
      jobStartedAt: jobStartedAt,
      sending: sending,
      lastPingAt: at,
      nowId: nowId,
    );
  }

  HeartbeatClock withSending(bool value) {
    return HeartbeatClock(
      jobStartedAt: jobStartedAt,
      lastPingAt: lastPingAt,
      sending: value,
      nowId: nowId,
    );
  }
}

HeartbeatClock syncHeartbeatClock({
  required PipelineProgressState state,
  required HeartbeatClock clock,
  required DateTime now,
}) {
  final current = state.now.trim();
  if (current.isEmpty) {
    return const HeartbeatClock(
      jobStartedAt: null,
      lastPingAt: null,
      sending: false,
      nowId: '',
    );
  }
  if (current != clock.nowId) {
    return HeartbeatClock(
      jobStartedAt: state.jobStartedAt ?? now.toUtc(),
      lastPingAt: null,
      nowId: current,
      sending: false,
    );
  }
  return HeartbeatClock(
    jobStartedAt: clock.jobStartedAt ?? state.jobStartedAt ?? now.toUtc(),
    lastPingAt: clock.lastPingAt,
    sending: clock.sending,
    nowId: clock.nowId,
  );
}

HeartbeatDecision decideHeartbeat({
  required PipelineProgressState state,
  required HeartbeatClock clock,
  required DateTime now,
  Duration interval = const Duration(minutes: 3),
}) {
  if (state.idle || state.now.isEmpty) {
    return const HeartbeatDecision(
      shouldPing: false,
      skipReason: 'idle',
      message: '',
    );
  }
  if (state.isShareBusy) {
    return const HeartbeatDecision(
      skipReason: 'share-busy',
      shouldPing: false,
      message: '',
    );
  }
  if (clock.sending) {
    return const HeartbeatDecision(
      skipReason: 'sending',
      shouldPing: false,
      message: '',
    );
  }
  final started = clock.jobStartedAt;
  if (started == null) {
    return const HeartbeatDecision(
      skipReason: 'no-start',
      shouldPing: false,
      message: '',
    );
  }
  final jobFor = now.toUtc().difference(started.toUtc());
  if (jobFor < interval) {
    return const HeartbeatDecision(
      skipReason: 'too-soon',
      shouldPing: false,
      message: '',
    );
  }
  final last = clock.lastPingAt;
  if (last != null && now.toUtc().difference(last.toUtc()) < interval) {
    return const HeartbeatDecision(
      skipReason: 'interval',
      shouldPing: false,
      message: '',
    );
  }
  return HeartbeatDecision(
    shouldPing: true,
    message: formatHeartbeatMessage(
      runElapsed: runElapsed(state: state, now: now),
      jobElapsed: jobFor,
      state: state,
    ),
  );
}

/// A ping is a status glance, not a report. The full board stays in the agent
/// chat and the PDF, so keep this to a few short lines.
const heartbeatNoteLimit = 70;

String formatHeartbeatMessage({
  required PipelineProgressState state,
  required Duration jobElapsed,
  Duration? runElapsed,
}) {
  final version = state.version.isEmpty
      ? ''
      : state.buildNumber.isEmpty
      ? ' v${state.version}'
      : ' v${state.version}+${state.buildNumber}';
  final app = state.app.isEmpty ? 'Fluship' : state.app;
  final step = state.now.isEmpty ? '-' : humanStepName(state.now);
  final progress = boardProgress(
    selected: state.selected,
    done: state.done,
    current: state.now,
  );
  final upload = state.upload?.label ?? '';
  final note = _oneLine(state.note, heartbeatNoteLimit);
  return [
    'Fluship $app$version',
    'NOW $step  ${formatElapsed(jobElapsed)}',
    [
      progress.label,
      '${progress.percent}%',
      if (runElapsed != null) 'run ${formatElapsed(runElapsed)}',
    ].join('  '),
    if (upload.isNotEmpty) 'upload: $upload',
    if (note.isNotEmpty) 'note: $note',
  ].join('\n');
}

String _oneLine(String raw, int limit) {
  final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= limit) return text;
  return '${text.substring(0, limit - 1)}.';
}
