import 'dart:async';
import 'dart:io';

import '../io_helpers.dart';
import 'host_actions.dart';

/// Build, compile, and store upload steps polled every 30 seconds.
const pipelineLongPollStepIds = <String>{
  'buildAab',
  'buildApk',
  'buildSplits',
  'podInstall',
  'buildIpa',
  'distPlayProduction',
  'distPlayInternal',
  'distAppStore',
  'distDrive',
};

const defaultPollSeconds = 30;

final _terminalExitCode = RegExp(r'^exit_code:\s*(\d+)\s*$', multiLine: true);

bool isLongPollStep(String id) => pipelineLongPollStepIds.contains(id);

bool terminalHasExitCode(String content) => _terminalExitCode.hasMatch(content);

int? terminalExitCode(String content) {
  final match = _terminalExitCode.firstMatch(content);
  if (match == null) return null;
  return int.tryParse(match.group(1) ?? '');
}

Future<int> waitForPid({
  required int pid,
  Duration pollInterval = const Duration(seconds: defaultPollSeconds),
  void Function(Duration elapsed)? onPoll,
}) async {
  if (pid <= 0) return 1;
  final started = DateTime.now();
  while (pidAlive(pid)) {
    onPoll?.call(DateTime.now().difference(started));
    await Future<void>.delayed(pollInterval);
  }
  return 0;
}

Future<int> waitForTerminal({
  required String terminalPath,
  Duration pollInterval = const Duration(seconds: defaultPollSeconds),
  void Function(Duration elapsed)? onPoll,
}) async {
  final path = absolutePath(terminalPath);
  if (path.isEmpty || !fileExists(path)) return 1;
  final started = DateTime.now();
  while (true) {
    final content = File(path).readAsStringSync();
    final code = terminalExitCode(content);
    if (code != null) return code;
    onPoll?.call(DateTime.now().difference(started));
    await Future<void>.delayed(pollInterval);
  }
}

Future<int> runCommandWithPoll({
  required String workingDirectory,
  required List<String> command,
  Duration pollInterval = const Duration(seconds: defaultPollSeconds),
  void Function(Duration elapsed)? onPoll,
}) async {
  if (command.isEmpty) return 1;
  final dir = absolutePath(workingDirectory);
  if (!dirExists(dir)) return 1;

  final process = await Process.start(
    command.first,
    command.sublist(1),
    workingDirectory: dir,
    mode: ProcessStartMode.inheritStdio,
  );
  final started = DateTime.now();
  while (pidAlive(process.pid)) {
    onPoll?.call(DateTime.now().difference(started));
    await Future<void>.delayed(pollInterval);
  }
  return await process.exitCode;
}

String formatWaitElapsed(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final rem = seconds % 60;
  if (rem == 0) return '${minutes}m';
  return '${minutes}m${rem}s';
}
