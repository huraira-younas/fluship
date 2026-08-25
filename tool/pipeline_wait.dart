import 'dart:io';

import 'pipeline_picker/host/shell_wait.dart';
import 'pipeline_picker/io_helpers.dart';

/// Fixed-interval wait for long pipeline jobs. Polls every 30 seconds instead
/// of chaining Await calls with growing block_until_ms.
Future<void> main(List<String> args) async {
  final flags = parseCliFlags(args);
  if (flagBool(flags, 'help')) {
    stdout.writeln(_help);
    return;
  }

  final pollSeconds = flagInt(
    flags,
    'poll-seconds',
    defaultPollSeconds,
    min: 1,
  );
  final pollInterval = Duration(seconds: pollSeconds);
  void onPoll(Duration elapsed) {
    stdout.writeln(
      'pipeline_wait: still running (${formatWaitElapsed(elapsed)})',
    );
  }

  final pid = int.tryParse(flagString(flags, 'pid'));
  if (pid != null) {
    exit(
      await waitForPid(pid: pid, pollInterval: pollInterval, onPoll: onPoll),
    );
  }

  final terminal = flagString(flags, 'terminal');
  if (terminal.isNotEmpty) {
    exit(
      await waitForTerminal(
        terminalPath: terminal,
        pollInterval: pollInterval,
        onPoll: onPoll,
      ),
    );
  }

  final command = _commandArgs(args);
  if (command.isEmpty) {
    stderr.writeln(
      'pipeline_wait: pass --pid, --terminal, or a command after --',
    );
    exit(1);
  }

  final workingDirectory = flagString(flags, 'dir', Directory.current.path);
  exit(
    await runCommandWithPoll(
      workingDirectory: workingDirectory,
      command: command,
      pollInterval: pollInterval,
      onPoll: onPoll,
    ),
  );
}

List<String> _commandArgs(List<String> args) {
  final dash = args.indexOf('--');
  if (dash < 0) return const [];
  return args.sublist(dash + 1);
}

const _help = '''
Fixed-interval wait for long Fluship pipeline jobs.

Polls every 30 seconds by default. Never grows the interval.

Usage:
  dart tool/pipeline_wait.dart --dir PROJECT -- flutter build aab --release
  dart tool/pipeline_wait.dart --pid 12345
  dart tool/pipeline_wait.dart --terminal /path/to/terminals/1.txt

Options:
  --dir PATH           Working directory for a wrapped command
  --poll-seconds N     Poll interval in seconds (default 30)
  --pid N              Wait until process N exits
  --terminal PATH      Wait until a background shell footer shows exit_code
''';
