import 'dart:io' show Platform, Process, ProcessResult;

import 'models/process_entry.dart';

class ProcessEnumerator {
  const ProcessEnumerator();

  bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Future<List<RawProcessRow>> listProcesses() async {
    if (!isSupported) return const [];

    final result = Platform.isWindows
        ? await _listWindows()
        : await _listUnix();

    if (result.exitCode != 0) return const [];

    return Platform.isWindows
        ? parseWindowsOutput(result.stdout as String)
        : parseUnixOutput(result.stdout as String);
  }

  Future<ProcessResult> _listUnix() {
    return Process.run('ps', ['-axo', 'pid=,ppid=,command=']);
  }

  Future<ProcessResult> _listWindows() {
    return Process.run('wmic', [
      'process',
      'get',
      'ProcessId,ParentProcessId,CommandLine',
      '/FORMAT:CSV',
    ]);
  }

  static List<RawProcessRow> parseUnixOutput(String output) {
    final rows = <RawProcessRow>[];

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = RegExp(r'^(\d+)\s+(\d+)\s+(.*)$').firstMatch(trimmed);
      if (match == null) continue;

      final pid = int.tryParse(match.group(1)!);
      final ppid = int.tryParse(match.group(2)!);
      final command = match.group(3)?.trim() ?? '';
      if (pid == null || ppid == null || command.isEmpty) continue;

      rows.add(RawProcessRow(command: command, ppid: ppid, pid: pid));
    }

    return rows;
  }

  static List<RawProcessRow> parseWindowsOutput(String output) {
    final rows = <RawProcessRow>[];

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('node,')) {
        continue;
      }

      final parts = trimmed.split(',');
      if (parts.length < 4) continue;

      final pid = int.tryParse(parts.last.trim());
      final ppid = int.tryParse(parts[parts.length - 2].trim());
      final command = parts.sublist(1, parts.length - 2).join(',').trim();
      if (pid == null || ppid == null || command.isEmpty) continue;

      rows.add(RawProcessRow(command: command, ppid: ppid, pid: pid));
    }

    return rows;
  }
}
