import 'dart:io';

import 'pipeline_picker/host/host_permissions.dart';
import 'pipeline_picker/host/pipeline_reset.dart';

/// First command of every agent pipeline run.
///
/// Run with full host permissions so Cursor shows Allow once, up front.
/// The user must stay until this prints warmup-status: ready.
///
/// Exit 0: ready to launch the picker.
/// Exit 4: user still needs to click Allow / enable Accessibility.
Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final toolDir = File.fromUri(Platform.script).parent;
  final workspace = toolDir.parent.absolute.path;
  final reset = await runPipelineReset(workspace: workspace, selfPid: pid);
  stdout.writeln(formatResetSummary(reset));

  final report = runWarmupProbes();
  stdout.writeln(formatWarmupBoard(report));

  if (report.ready) {
    stdout.writeln(
      'User can submit the picker next. Stay until it is on screen.',
    );
    return;
  }

  openAccessibilitySettings();
  stderr.writeln(
    'Cursor needs Accessibility. Enable Cursor, click Allow, run warmup again.',
  );
  exitCode = 4;
}

const _help = '''
Ask for Fluship host permissions at the start of a pipeline run.

Usage:
  dart tool/pipeline_warmup.dart

Resets any stale picker, heartbeat, or progress, then asks for host
permissions. The agent must run this with full host permissions before
the picker.
''';
