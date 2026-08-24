import 'dart:io';

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
    try {
      final result = await sendWhatsAppText(
        number: parsed.number,
        text: decision.message,
      );
      stdout.writeln('Heartbeat: $result');
      if (result != 'sent' && result != 'attached') {
        stderr.writeln('Heartbeat ping failed: $result');
      }
    } catch (error) {
      stderr.writeln('Heartbeat ping failed: $error');
    } finally {
      clock = clock.markedPing(now).withSending(false);
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
  var progress = '.fluship-agent/progress.json';
  var number = '';
  var intervalSeconds = 120;
  var pollSeconds = 5;
  var once = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--once') once = true;
    if (arg == '--progress' && i + 1 < args.length) progress = args[++i];
    if (arg == '--number' && i + 1 < args.length) number = args[++i];
    if (arg == '--interval-seconds' && i + 1 < args.length) {
      intervalSeconds = clampSeconds(int.tryParse(args[++i]), intervalSeconds);
    }
    if (arg == '--poll-seconds' && i + 1 < args.length) {
      pollSeconds = clampSeconds(int.tryParse(args[++i]), pollSeconds);
    }
  }
  return _Args(
    progress: progress,
    number: number,
    intervalSeconds: intervalSeconds,
    pollSeconds: pollSeconds,
    once: once,
  );
}

int clampSeconds(int? value, int fallback) {
  final n = value ?? fallback;
  return n < 1 ? 1 : n;
}
