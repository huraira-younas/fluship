import 'dart:io';

import '../io_helpers.dart';
import '../progress/progress_state.dart';
import 'cleanup.dart';
import 'host_actions.dart';
import 'open_page.dart';

class PipelineResetReport {
  const PipelineResetReport({
    required this.killed,
    required this.survivors,
    required this.projectPath,
  });

  final List<int> killed;
  final List<int> survivors;
  final String projectPath;
}

/// Stops any in-flight picker, heartbeat, or build tracking and clears stale
/// agent state so the next `run pipeline` starts from a clean slate.
Future<PipelineResetReport> runPipelineReset({
  required String workspace,
  int selfPid = -1,
  bool dryRun = false,
  bool fullProgressReset = true,
}) async {
  final agentDir = pathJoin(workspace, '.fluship-agent');
  Directory(agentDir).createSync(recursive: true);
  final pidsPath = pathJoin(agentDir, 'run-pids.json');
  final lockPath = pathJoin(agentDir, 'picker.lock');
  final progressPath = pathJoin(agentDir, 'progress.json');
  final openedAt = pathJoin(agentDir, 'picker-open.json');
  final pickerUrl = asString(readJsonFile(openedAt)['url']);

  final stored = readJsonFile(pidsPath);
  final projectPath = asString(stored['projectPath']);
  final tracked = loadTrackedPids(pidsPath);
  final effectivePid = selfPid > 0 ? selfPid : pid;

  final rows = await listProcesses();
  final plan = planCleanup(
    rows: rows,
    trackedPids: tracked,
    projectPath: projectPath,
    selfPid: effectivePid,
    includePicker: true,
  );

  if (dryRun) {
    return PipelineResetReport(
      killed: const [],
      survivors: plan.pidsToKill,
      projectPath: projectPath,
    );
  }

  List<int> killed = const [];
  List<int> survivors = const [];
  try {
    killed = await killPids(plan.pidsToKill);
    survivors = plan.pidsToKill.where(pidAlive).toList();
  } finally {
    clearAgentState(
      agentDir: agentDir,
      fullProgressReset: fullProgressReset,
      progressPath: progressPath,
      lockPath: lockPath,
    );
    saveTrackedPids(path: pidsPath, pids: const [], projectPath: projectPath);
  }

  if (pickerUrl.isNotEmpty) {
    await closePickerTab(pickerUrl);
  }

  return PipelineResetReport(
    killed: killed,
    survivors: survivors,
    projectPath: projectPath,
  );
}

void clearAgentState({
  required String agentDir,
  required bool fullProgressReset,
  required String progressPath,
  required String lockPath,
}) {
  if (fullProgressReset) {
    resetProgressForRun(progressPath);
  } else {
    writeProgressIdle(progressPath);
  }
  deleteIfExists(lockPath);
  deleteIfExists(pathJoin(agentDir, 'picker-result.json'));
  deleteIfExists(pathJoin(agentDir, 'picker-open.json'));
  deleteIfExists(pathJoin(agentDir, 'whatsapp.lock'));
  deleteIfExists(pathJoin(agentDir, 'last-drive.json'));
}

String formatResetSummary(PipelineResetReport report) {
  final lines = <String>[
    'Fluship reset',
    'Stopped ${report.killed.length} process(es).',
  ];
  if (report.survivors.isNotEmpty) {
    lines.add('Still alive: ${report.survivors.join(', ')}');
  }
  if (report.projectPath.isNotEmpty) {
    lines.add('Project: ${report.projectPath}');
  }
  return lines.join('\n');
}
