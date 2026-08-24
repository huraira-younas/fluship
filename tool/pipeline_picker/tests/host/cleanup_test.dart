import 'dart:io';

import '../../host/cleanup.dart';
import '../../io_helpers.dart';

void main() {
  const project = '/Users/me/apps/shop';
  final rows = [
    const ProcessSnapshot(pid: 10, ppid: 1, command: 'cursor helper'),
    const ProcessSnapshot(pid: 11, ppid: 1, command: 'WhatsApp'),
    const ProcessSnapshot(
      pid: 20,
      ppid: 1,
      command: 'flutter build apk --release /Users/me/apps/shop',
    ),
    const ProcessSnapshot(
      pid: 21,
      ppid: 20,
      command: 'java gradle /Users/me/apps/shop',
    ),
    const ProcessSnapshot(
      pid: 30,
      ppid: 1,
      command: 'dart analysis_server /Users/me/apps/shop',
    ),
    const ProcessSnapshot(
      pid: 40,
      ppid: 1,
      command: 'dart tool/pipeline_picker.dart',
    ),
    const ProcessSnapshot(pid: 50, ppid: 1, command: 'tracked shell'),
    const ProcessSnapshot(
      pid: 60,
      ppid: 1,
      command: 'dart tool/pipeline_heartbeat.dart --progress x',
    ),
    const ProcessSnapshot(
      pid: 61,
      ppid: 62,
      command: 'python3 tool/whatsapp_send.py --number 1',
    ),
    const ProcessSnapshot(
      pid: 62,
      ppid: 1,
      command: 'dart tool/whatsapp_share.dart --log x',
    ),
  ];

  final plan = planCleanup(
    rows: rows,
    trackedPids: const [50],
    projectPath: project,
    selfPid: 99,
    extraExclude: const [99],
  );
  _check(plan.pidsToKill.contains(50), 'tracked');
  _check(plan.pidsToKill.contains(20), 'flutter orphan');
  _check(plan.pidsToKill.contains(21), 'gradle child/orphan');
  _check(!plan.pidsToKill.contains(10), 'skip cursor');
  _check(!plan.pidsToKill.contains(11), 'skip whatsapp');
  _check(!plan.pidsToKill.contains(30), 'skip analysis server');
  _check(!plan.pidsToKill.contains(40), 'skip live picker');
  _check(!plan.pidsToKill.contains(99), 'skip self');
  _check(plan.pidsToKill.contains(60), 'kill untracked heartbeat');
  _check(plan.pidsToKill.contains(61), 'kill leftover send script');
  _check(plan.pidsToKill.contains(62), 'kill leftover share script');

  final sharePlan = planCleanup(
    rows: rows,
    trackedPids: const [62],
    projectPath: project,
    selfPid: 99,
  );
  _check(sharePlan.pidsToKill.contains(62), 'kill tracked share');
  _check(sharePlan.pidsToKill.contains(61), 'kill send child');
  _check(sharePlan.pidsToKill.contains(60), 'still kill heartbeat');

  final closePlan = planCleanup(
    rows: rows,
    trackedPids: const [],
    projectPath: project,
    selfPid: 99,
    includePicker: true,
  );
  _check(closePlan.pidsToKill.contains(40), 'close picker');

  // A sibling folder that merely starts with the project path is not ours.
  _check(
    commandTouchesProject('flutter build /Users/me/apps/shop', project),
    'exact project match',
  );
  _check(
    commandTouchesProject('flutter build /Users/me/apps/shop/android', project),
    'match inside project',
  );
  _check(
    !commandTouchesProject('flutter build /Users/me/apps/shop-v2', project),
    'no sibling prefix match',
  );
  _check(
    !commandTouchesProject('flutter build /Users/me/apps/shopping', project),
    'no longer name match',
  );
  _check(
    commandTouchesProject(
      'cd /Users/me/apps/shop/ && pod install',
      '$project/',
    ),
    'trailing slash project',
  );
  _check(!commandTouchesProject('flutter build', ''), 'empty project');

  final siblingPlan = planCleanup(
    rows: const [
      ProcessSnapshot(
        pid: 70,
        ppid: 1,
        command: 'flutter build apk /Users/me/apps/shop-v2',
      ),
    ],
    trackedPids: const [],
    projectPath: project,
    selfPid: 99,
  );
  _check(siblingPlan.pidsToKill.isEmpty, 'never kill a sibling project build');

  final parsed = parsePsTable(' 20  1 flutter build\n21 20 java gradle\n');
  _check(parsed.length == 2, 'parse ps');
  _check(parsed.first.pid == 20 && parsed.first.ppid == 1, 'parse fields');

  final dir = Directory.systemTemp.createTempSync('fluship-pids-');
  try {
    final path = pathJoin(dir.path, 'run-pids.json');
    saveTrackedPids(path: path, pids: const [7, 8], projectPath: project);
    trackPid(path, 9, project);
    final loaded = loadTrackedPids(path);
    _check(loaded.contains(7) && loaded.contains(9), 'track persist');
  } finally {
    dir.deleteSync(recursive: true);
  }

  stdout.writeln('cleanup tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
