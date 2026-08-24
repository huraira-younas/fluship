import 'dart:io';

import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/heartbeat.dart';
import 'pipeline_picker/progress/progress_state.dart';
import 'pipeline_picker/share/whatsapp.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final parsed = _parse(args);
  if (!isValidWhatsAppNumber(parsed.number)) {
    stderr.writeln('WhatsApp number is not valid.');
    exitCode = 64;
    return;
  }

  var clock = const HeartbeatClock(
    jobStartedAt: null,
    lastPingAt: null,
    sending: false,
    nowId: '',
  );

  Future<void> tick() async {
    final state = loadProgressState(parsed.progress);
    final now = DateTime.now().toUtc();
    clock = syncHeartbeatClock(clock: clock, state: state, now: now);
    final decision = decideHeartbeat(
      state: state,
      clock: clock,
      now: now,
      interval: Duration(seconds: parsed.intervalSeconds),
    );
    if (!decision.shouldPing) return;
    clock = clock.withSending(true);
    var attempted = true;
    try {
      final result = await sendWhatsAppText(
        number: parsed.number,
        text: decision.message,
      );
      // Another sender owns the composer. Retry on the next poll rather than
      // spending the whole interval on a ping that never left.
      attempted = result != 'busy';
      stdout.writeln('Heartbeat: $result');
      if (attempted && result != 'sent' && result != 'attached') {
        stderr.writeln('Heartbeat ping failed: $result');
      }
    } catch (error) {
      stderr.writeln('Heartbeat ping failed: $error');
    } finally {
      // Stamp after the send, not before. The WhatsApp UI work takes seconds,
      // and counting it inside the interval makes the next ping fire early.
      clock = attempted
          ? clock.markedPing(DateTime.now().toUtc()).withSending(false)
          : clock.withSending(false);
    }
  }

  if (loadProgressState(parsed.progress).idle) return;
  await tick();
  if (parsed.once) return;

  while (true) {
    await Future<void>.delayed(Duration(seconds: parsed.pollSeconds));
    if (loadProgressState(parsed.progress).idle) return;
    await tick();
  }
}

const _help = '''
Ping WhatsApp every 2 minutes while a pipeline job is still running.

Usage:
  dart tool/pipeline_heartbeat.dart --progress .fluship-agent/progress.json --number +923096547269 --interval-seconds 120
''';

class _Args {
  const _Args({
    required this.progress,
    required this.number,
    required this.intervalSeconds,
    required this.pollSeconds,
    required this.once,
  });

  final String progress;
  final String number;
  final int intervalSeconds;
  final int pollSeconds;
  final bool once;
}

_Args _parse(List<String> args) {
  final flags = parseCliFlags(args);
  return _Args(
    progress: resolveAgentPath(flags['progress'], 'progress.json'),
    number: flagString(flags, 'number'),
    intervalSeconds: flagInt(flags, 'interval-seconds', 120, min: 1),
    // Tight poll so the first ping lands within seconds of the 2 minute mark.
    pollSeconds: flagInt(flags, 'poll-seconds', 2, min: 1),
    once: flags.containsKey('once'),
  );
}
