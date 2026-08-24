import 'dart:io';

import 'io_helpers.dart';

const buildPatterns = <String>[
  'flutter',
  'gradle',
  'xcodebuild',
  'kotlinc',
  'kotlin',
  'aapt2',
  'pod',
];

const dartBuildHints = <String>[
  'flutter_tools',
  'frontend_server',
  'gen_dart_plugin_registrant',
  'kernel_worker',
];

const neverKillHints = <String>[
  'cursor',
  'whatsapp',
  'analysis_server',
  'language_server',
  'dart_tooling_daemon',
  'dtd_app',
];

class ProcessSnapshot {
  const ProcessSnapshot({
    required this.pid,
    required this.ppid,
    required this.command,
  });

  final int pid;
  final int ppid;
  final String command;
}

class CleanupPlan {
  const CleanupPlan({required this.pidsToKill, required this.reasons});

  final List<int> pidsToKill;
  final Map<int, String> reasons;
}

CleanupPlan planCleanup({
  required List<ProcessSnapshot> rows,
  required Iterable<int> trackedPids,
  required String projectPath,
  required int selfPid,
  Iterable<int> extraExclude = const [],
  bool includePicker = false,
}) {
  final tracked = trackedPids.toSet();
  final exclude = <int>{selfPid, ...extraExclude};
  final pidToPpid = {for (final row in rows) row.pid: row.ppid};
  final byPid = {for (final row in rows) row.pid: row};
  final kill = <int, String>{};

  bool excludedCommand(String command) {
    final lower = command.toLowerCase();
    if (lower.contains('pipeline_picker')) return !includePicker;
    return neverKillHints.any(lower.contains);
  }

  void mark(int pid, String reason) {
    if (exclude.contains(pid) || kill.containsKey(pid)) return;
    final row = byPid[pid];
    if (row != null && excludedCommand(row.command)) return;
    kill[pid] = reason;
  }

  for (final pid in tracked) {
    mark(pid, 'tracked');
  }

  for (final row in rows) {
    if (exclude.contains(row.pid)) continue;
    if (excludedCommand(row.command)) continue;
    if (includePicker &&
        row.command.toLowerCase().contains('pipeline_picker')) {
      mark(row.pid, 'picker');
      continue;
    }
    if (_hasTrackedAncestor(row.pid, tracked, pidToPpid)) {
      mark(row.pid, 'child of tracked');
      continue;
    }
    if (_isOrphanBuild(row, projectPath)) {
      mark(row.pid, 'project orphan');
    }
  }

  final pids = kill.keys.toList()..sort();
  return CleanupPlan(pidsToKill: pids, reasons: kill);
}

bool _hasTrackedAncestor(int pid, Set<int> tracked, Map<int, int> pidToPpid) {
  final seen = <int>{};
  var current = pid;
  while (seen.add(current)) {
    if (tracked.contains(current)) return true;
    final parent = pidToPpid[current];
    if (parent == null || parent <= 0) return false;
    current = parent;
  }
  return false;
}

bool _isOrphanBuild(ProcessSnapshot row, String projectPath) {
  final root = projectPath.trim();
  if (root.isEmpty) return false;
  final lower = row.command.toLowerCase();
  if (!row.command.contains(root)) return false;
  if (buildPatterns.any(lower.contains)) return true;
  if (lower.contains('dart') && dartBuildHints.any(lower.contains)) {
    return true;
  }
  return false;
}

List<int> loadTrackedPids(String path) {
  final json = readJsonFile(path);
  return [
    for (final item in asStringList(json['pids']))
      if (int.tryParse(item) != null) int.parse(item),
  ];
}

void saveTrackedPids({
  required String path,
  required Iterable<int> pids,
  required String projectPath,
}) {
  writeJsonFile(path, {
    'pids': [for (final pid in pids.toSet()) pid],
    'projectPath': projectPath,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  });
}

void trackPid(String path, int pid, String projectPath) {
  if (pid <= 0) return;
  final existing = loadTrackedPids(path);
  saveTrackedPids(
    path: path,
    pids: [...existing, pid],
    projectPath: projectPath,
  );
}

List<ProcessSnapshot> parsePsTable(String source) {
  final rows = <ProcessSnapshot>[];
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;
    final pid = int.tryParse(parts[0]);
    final ppid = int.tryParse(parts[1]);
    if (pid == null || ppid == null) continue;
    rows.add(
      ProcessSnapshot(
        pid: pid,
        ppid: ppid,
        command: parts.sublist(2).join(' '),
      ),
    );
  }
  return rows;
}

Future<List<ProcessSnapshot>> listProcesses() async {
  if (Platform.isWindows) {
    final result = await Process.run('wmic', [
      'process',
      'get',
      'ProcessId,ParentProcessId,CommandLine',
      '/FORMAT:CSV',
    ]);
    return _parseWmic(result.stdout.toString());
  }
  final result = await Process.run('ps', [
    '-ax',
    '-o',
    'pid=',
    '-o',
    'ppid=',
    '-o',
    'command=',
  ]);
  return parsePsTable(result.stdout.toString());
}

List<ProcessSnapshot> _parseWmic(String source) {
  final rows = <ProcessSnapshot>[];
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.toLowerCase().contains('processid')) continue;
    final cols = line.split(',');
    if (cols.length < 3) continue;
    final ppid = int.tryParse(cols[cols.length - 2].trim());
    final pid = int.tryParse(cols[cols.length - 1].trim());
    if (pid == null || ppid == null) continue;
    final command = cols.sublist(1, cols.length - 2).join(',');
    rows.add(ProcessSnapshot(pid: pid, ppid: ppid, command: command));
  }
  return rows;
}

Future<List<int>> killPids(Iterable<int> pids) async {
  final killed = <int>[];
  for (final pid in pids) {
    Process.killPid(pid, ProcessSignal.sigterm);
  }
  await Future<void>.delayed(const Duration(milliseconds: 250));
  for (final pid in pids) {
    Process.killPid(pid, ProcessSignal.sigkill);
    killed.add(pid);
  }
  return killed;
}
