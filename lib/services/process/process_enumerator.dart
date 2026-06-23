import 'dart:io' show Platform, Process, ProcessException, ProcessResult;

import 'models/process_entry.dart';

class ProcessEnumerator {
  const ProcessEnumerator();

  bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Future<List<RawProcessRow>> listProcesses() async {
    if (!isSupported) return const [];

    try {
      final result = Platform.isWindows
          ? await _listWindows()
          : await _listUnix();

      if (result.exitCode != 0) return const [];

      return Platform.isWindows
          ? parseWindowsOutput(result.stdout as String)
          : parseUnixOutput(result.stdout as String);
    } on ProcessException {
      return const [];
    }
  }

  Future<ProcessResult> _listUnix() {
    return Process.run('ps', ['-axo', 'pid=,ppid=,command=']);
  }

  Future<ProcessResult> _listWindows() {
    return Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Get-CimInstance Win32_Process | '
          'Select-Object ProcessId, ParentProcessId, CommandLine | '
          'ConvertTo-Csv -NoTypeInformation',
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
    final lines = output.split('\n');
    if (lines.isEmpty) return rows;

    final h = lines.first.trim().toLowerCase();
    final isPS = h.startsWith('"processid"') || h.startsWith('processid,');

    for (var i = 1; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      final String command;
      final int? ppid;
      final int? pid;

      if (isPS) {
        final fields = _parseCsvFields(trimmed);
        if (fields.length < 3) continue;

        pid = int.tryParse(fields[0].trim());
        ppid = int.tryParse(fields[1].trim());
        command = fields[2].trim();
      } else {
        final parts = trimmed.split(',');
        if (parts.length < 4) continue;

        pid = int.tryParse(parts.last.trim());
        ppid = int.tryParse(parts[parts.length - 2].trim());
        command = parts.sublist(1, parts.length - 2).join(',').trim();
      }

      if (pid == null || ppid == null || command.isEmpty) continue;

      rows.add(RawProcessRow(command: command, ppid: ppid, pid: pid));
    }

    return rows;
  }

  static List<String> _parseCsvFields(String line) {
    final fields = <String>[];
    var index = 0;

    while (index < line.length) {
      if (line[index] == '"') {
        final buffer = StringBuffer();
        index++;

        while (index < line.length) {
          if (line[index] == '"') {
            if (index + 1 < line.length && line[index + 1] == '"') {
              buffer.write('"');
              index += 2;
              continue;
            }
            index++;
            break;
          }

          buffer.write(line[index]);
          index++;
        }

        fields.add(buffer.toString());
        if (index < line.length && line[index] == ',') index++;
        continue;
      }

      final comma = line.indexOf(',', index);
      if (comma == -1) {
        fields.add(line.substring(index).trim());
        break;
      }

      fields.add(line.substring(index, comma).trim());
      index = comma + 1;
    }

    return fields;
  }
}
