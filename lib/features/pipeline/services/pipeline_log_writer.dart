import 'dart:io' show Directory, File;

import 'package:fluship/features/console/models/console_line.dart';
import 'package:path/path.dart' as p;

import '../utils/pipeline_project_folder_name.dart';
import '../utils/fluship_workspace_paths.dart';
import '../utils/pipeline_log_file_name.dart';
import '../utils/pipeline_log_formatter.dart';

abstract interface class PipelineLogWriter {
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectName,
    required String buildNumber,
    required String version,
  });
}

class FilePipelineLogWriter implements PipelineLogWriter {
  const FilePipelineLogWriter({FlushipWorkspacePaths? workspacePaths})
    : _workspacePaths = workspacePaths ?? const FlushipWorkspacePaths();

  final FlushipWorkspacePaths _workspacePaths;

  @override
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectName,
    required String buildNumber,
    required String version,
  }) async {
    final fileName = buildPipelineLogFileName(
      buildNumber: buildNumber,
      version: version,
    );
    final flushipRoot = await _workspacePaths.resolveRoot();
    final logsDir = Directory(
      flushipPipelineLogsDirectory(
        flushipRoot: flushipRoot,
        projectName: projectName,
      ),
    );
    await logsDir.create(recursive: true);

    final file = File(p.join(logsDir.path, fileName));
    await file.writeAsString(formatPipelineLogLines(lines));

    return file.path;
  }
}

String pipelineLogRelativePath({
  required String projectName,
  required String buildNumber,
  required String version,
}) {
  return p.posix.join(
    'lib',
    'logs',
    sanitizeProjectFolderName(projectName),
    buildPipelineLogFileName(buildNumber: buildNumber, version: version),
  );
}
