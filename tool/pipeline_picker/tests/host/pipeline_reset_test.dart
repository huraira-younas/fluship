import 'dart:io';

import '../../host/pipeline_reset.dart';
import '../../io_helpers.dart';
import '../../progress/progress_state.dart';

Future<void> main() async {
  final dir = Directory.systemTemp.createTempSync('fluship-reset-');
  try {
    final agentDir = pathJoin(dir.path, '.fluship-agent');
    Directory(agentDir).createSync(recursive: true);
    final progressPath = pathJoin(agentDir, 'progress.json');
    saveProgressState(
      progressPath,
      loadProgressState(progressPath).copyWith(
        app: 'Old',
        done: const ['clean'],
        results: const {'clean': 'ok'},
      ),
    );
    writeJsonFile(pathJoin(agentDir, 'picker.lock'), {
      'pid': 99999,
      'url': 'x',
    });
    writeJsonFile(pathJoin(agentDir, 'picker-result.json'), {'exitCode': 0});
    writeJsonFile(pathJoin(agentDir, 'picker-open.json'), {
      'url': 'http://127.0.0.1:1/',
    });

    clearAgentState(
      agentDir: agentDir,
      fullProgressReset: true,
      progressPath: progressPath,
      lockPath: pathJoin(agentDir, 'picker.lock'),
    );

    _check(!File(pathJoin(agentDir, 'picker.lock')).existsSync(), 'lock gone');
    _check(
      !File(pathJoin(agentDir, 'picker-result.json')).existsSync(),
      'result gone',
    );
    _check(
      !File(pathJoin(agentDir, 'picker-open.json')).existsSync(),
      'open gone',
    );
    final state = loadProgressState(progressPath);
    _check(state.app.isEmpty && state.done.isEmpty, 'progress cleared');

    final report = await runPipelineReset(workspace: dir.path, dryRun: true);
    _check(report.killed.isEmpty, 'dry run kills nothing');
  } finally {
    dir.deleteSync(recursive: true);
  }

  stdout.writeln('pipeline reset tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
