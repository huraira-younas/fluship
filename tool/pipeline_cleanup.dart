import 'dart:io';

import 'pipeline_picker/host/cleanup.dart';
import 'pipeline_picker/host/host_actions.dart';
import 'pipeline_picker/host/open_page.dart';
import 'pipeline_picker/host/pipeline_reset.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress_state.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final parsed = _parse(args);
  final workspace = Directory(
    parsed.workspace ?? File.fromUri(Platform.script).parent.parent.path,
  ).absolute.path;
  final agentDir = pathJoin(workspace, '.fluship-agent');
  Directory(agentDir).createSync(recursive: true);
  final pidsPath = pathJoin(agentDir, 'run-pids.json');
  final lockPath = pathJoin(agentDir, 'picker.lock');

  if (parsed.reset) {
    final report = await runPipelineReset(
      workspace: workspace,
      selfPid: pid,
      dryRun: parsed.dryRun,
      fullProgressReset: true,
    );
    stdout.writeln(formatResetSummary(report));
    for (final item in report.killed) {
      stdout.writeln('  killed $item');
    }
    return;
  }

  if (parsed.prepare) {
    saveTrackedPids(
      path: pidsPath,
      pids: const [],
      projectPath: parsed.project,
    );
    deleteIfExists(pathJoin(agentDir, 'last-drive.json'));
    deleteIfExists(pathJoin(agentDir, 'whatsapp.lock'));
    resetProgressForRun(pathJoin(agentDir, 'progress.json'));
    stdout.writeln('Prepared $pidsPath');
    return;
  }

  if (parsed.trackPid != null) {
    trackPid(pidsPath, parsed.trackPid!, parsed.project);
    stdout.writeln('Tracked ${parsed.trackPid}');
    return;
  }

  final stored = readJsonFile(pidsPath);
  final project = parsed.project.isNotEmpty
      ? parsed.project
      : asString(stored['projectPath']);
  final tracked = loadTrackedPids(pidsPath);
  final extraExclude = <int>{pid};
  if (!parsed.closePicker) {
    final lockPid = asInt(readJsonFile(lockPath)['pid']);
    if (lockPid != null) extraExclude.add(lockPid);
  }

  final rows = await listProcesses();
  final plan = planCleanup(
    rows: rows,
    trackedPids: tracked,
    projectPath: project,
    selfPid: pid,
    extraExclude: extraExclude,
    includePicker: parsed.closePicker,
  );

  stdout.writeln('Cleanup ${plan.pidsToKill.length} process(es) for $project');
  for (final item in plan.pidsToKill) {
    stdout.writeln('  $item ${plan.reasons[item]}');
  }

  if (parsed.dryRun) return;

  final openedAt = pathJoin(agentDir, 'picker-open.json');
  final pickerUrl = parsed.closePicker
      ? asString(readJsonFile(openedAt)['url'])
      : '';

  try {
    final killed = await killPids(plan.pidsToKill);
    stdout.writeln('Killed ${killed.length} process(es).');
    final survivors = plan.pidsToKill.where(pidAlive).toList();
    if (survivors.isNotEmpty) {
      stderr.writeln('Still alive after cleanup: ${survivors.join(', ')}');
    }
  } finally {
    clearAgentState(
      agentDir: agentDir,
      fullProgressReset: parsed.closePicker,
      progressPath: pathJoin(agentDir, 'progress.json'),
      lockPath: lockPath,
    );
    saveTrackedPids(path: pidsPath, pids: const [], projectPath: project);
  }

  if (!parsed.closePicker) return;
  final closed = await closePickerTab(pickerUrl);
  if (closed > 0) stdout.writeln('Closed $closed Chrome picker tab(s).');
}

const _help = '''
Kill tracked pipeline children and project-linked build orphans.

Usage:
  dart tool/pipeline_cleanup.dart --project PATH [--workspace PATH]
  dart tool/pipeline_cleanup.dart --prepare --project PATH
  dart tool/pipeline_cleanup.dart --track PID --project PATH
  dart tool/pipeline_cleanup.dart --close-picker [--project PATH]
  dart tool/pipeline_cleanup.dart --reset [--workspace PATH]

--reset kills any live picker, heartbeat, and tracked builds, then clears
stale agent state. Warmup runs this before every new pipeline.

Always run cleanup after success, fail, cancel, timeout, or stop.
''';

class _Args {
  const _Args({
    required this.workspace,
    required this.project,
    required this.prepare,
    required this.trackPid,
    required this.closePicker,
    required this.reset,
    required this.dryRun,
  });

  final String? workspace;
  final String project;
  final bool prepare;
  final int? trackPid;
  final bool closePicker;
  final bool reset;
  final bool dryRun;
}

_Args _parse(List<String> args) {
  final flags = parseCliFlags(args);
  return _Args(
    workspace: flags['workspace'],
    project: flagString(flags, 'project'),
    prepare: flags.containsKey('prepare'),
    trackPid: int.tryParse(flagString(flags, 'track')),
    closePicker: flags.containsKey('close-picker'),
    reset: flags.containsKey('reset'),
    dryRun: flags.containsKey('dry-run'),
  );
}
