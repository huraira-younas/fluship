import 'dart:io';

import 'pipeline_picker/cleanup.dart';
import 'pipeline_picker/io_helpers.dart';

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

  if (parsed.prepare) {
    saveTrackedPids(
      path: pidsPath,
      pids: const [],
      projectPath: parsed.project,
    );
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

  final killed = await killPids(plan.pidsToKill);
  saveTrackedPids(path: pidsPath, pids: const [], projectPath: project);
  if (parsed.closePicker) {
    final lock = File(lockPath);
    if (lock.existsSync()) lock.deleteSync();
  }
  stdout.writeln('Killed ${killed.length} process(es).');
}

const _help = '''
Kill tracked pipeline children and project-linked build orphans.

Usage:
  dart tool/pipeline_cleanup.dart --project PATH [--workspace PATH]
  dart tool/pipeline_cleanup.dart --prepare --project PATH
  dart tool/pipeline_cleanup.dart --track PID --project PATH
  dart tool/pipeline_cleanup.dart --close-picker --project PATH

Always run this after success, fail, cancel, timeout, or close.
''';

class _Args {
  const _Args({
    required this.workspace,
    required this.project,
    required this.prepare,
    required this.trackPid,
    required this.closePicker,
    required this.dryRun,
  });

  final String? workspace;
  final String project;
  final bool prepare;
  final int? trackPid;
  final bool closePicker;
  final bool dryRun;
}

_Args _parse(List<String> args) {
  String? workspace;
  var project = '';
  var prepare = false;
  int? trackPid;
  var closePicker = false;
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--prepare') prepare = true;
    if (arg == '--close-picker') closePicker = true;
    if (arg == '--dry-run') dryRun = true;
    if (arg == '--workspace' && i + 1 < args.length) workspace = args[++i];
    if (arg == '--project' && i + 1 < args.length) project = args[++i];
    if (arg == '--track' && i + 1 < args.length) {
      trackPid = int.tryParse(args[++i]);
    }
  }
  return _Args(
    workspace: workspace,
    project: project,
    prepare: prepare,
    trackPid: trackPid,
    closePicker: closePicker,
    dryRun: dryRun,
  );
}
