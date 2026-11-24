import 'dart:async' show unawaited;
import 'dart:io' show Directory, Platform;

import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/services/console/runners/sh_shell_runner.dart';
import 'package:fluship/services/process/process.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ShellRunResult> _run(
  ShShellRunner runner,
  String command, {
  StringBuffer? stdout,
}) {
  return runner.run(
    command,
    onStdout: (chunk) => stdout?.write(chunk),
    onCwdChanged: (_) {},
    onStderr: (_) {},
  );
}

Future<List<int>> _sleepPidsUnder(int shellPid) async {
  final rows = await const ProcessEnumerator().listProcesses();
  final below = ProcessTreeKiller.descendantsOf(rows, shellPid).toSet();
  return [
    for (final row in rows)
      if (below.contains(row.pid) && row.command.contains('sleep')) row.pid,
  ];
}

void main() {
  group('ShShellRunner cancel', () {
    late ShShellRunner runner;

    setUp(() async {
      runner = ShShellRunner();
      await runner.start(workingDirectory: Directory.systemTemp.path);
    });

    tearDown(() => runner.dispose());

    test('stops the running command instead of leaving it behind', () async {
      final pending = _run(runner, 'sleep 30');
      unawaited(pending.catchError((_) => const ShellRunResult(exitCode: -1)));

      final shellPid = runner.processId!;
      var sleeping = <int>[];
      for (var i = 0; i < 50 && sleeping.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        sleeping = await _sleepPidsUnder(shellPid);
      }
      expect(sleeping, isNotEmpty, reason: 'sleep never started');

      await runner.cancel();
      final result = await pending;

      expect(result.wasCancelled, isTrue);

      final alive = {
        for (final row in await const ProcessEnumerator().listProcesses())
          row.pid,
      };
      expect(alive.intersection(sleeping.toSet()), isEmpty);
    });

    test('runs the next command at once in a new shell', () async {
      final pending = _run(runner, 'sleep 30');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await runner.cancel();
      await pending;

      final stdout = StringBuffer();
      final result = await _run(
        runner,
        'echo ok',
        stdout: stdout,
      ).timeout(const Duration(seconds: 10));

      expect(result.wasCancelled, isFalse);
      expect(result.exitCode, 0);
      expect(stdout.toString().trim(), 'ok');
    });
  }, skip: Platform.isWindows ? 'sh is not available on Windows' : null);
}
