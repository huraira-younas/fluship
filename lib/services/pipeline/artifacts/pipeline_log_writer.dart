import 'dart:io' show Directory, File;

import 'package:fluship/features/console/models/console_line.dart';
import 'package:path/path.dart' as p;

import '../paths/fluship_workspace_paths.dart';
import '../utils/pipeline_utils.dart';

abstract interface class PipelineLogWriter {
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectName,
    required String buildNumber,
    required String version,
  });
}

class FilePipelineLogWriter implements PipelineLogWriter {
  FilePipelineLogWriter(this._workspacePaths);

  static const pipelineLogFileName = 'logs.txt';

  final FlushipWorkspacePaths _workspacePaths;

  @override
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectName,
    required String buildNumber,
    required String version,
  }) async {
    final flushipRoot = await _workspacePaths.resolveRoot();
    final outputDir = Directory(
      pipelineOutputDirectory(
        flushipRoot: flushipRoot,
        projectName: projectName,
        buildNumber: buildNumber,
        version: version,
      ),
    );
    await outputDir.create(recursive: true);

    final file = File(p.join(outputDir.path, pipelineLogFileName));
    await file.writeAsString(PipelineUtils.formatPipelineLogLines(lines));

    return file.path;
  }
}

String pipelineLogRelativePath({
  required String projectName,
  required String buildNumber,
  required String version,
}) {
  return p.posix.join(
    pipelineOutputRelativePath(
      projectName: projectName,
      buildNumber: buildNumber,
      version: version,
    ),
    FilePipelineLogWriter.pipelineLogFileName,
  );
}
