import 'dart:io' show Directory, File;

import 'package:fluship/features/console/models/console_line.dart';
import 'package:path/path.dart' as p;

import '../utils/pipeline_log_file_name.dart';
import '../utils/pipeline_log_formatter.dart';

abstract interface class PipelineLogWriter {
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectRoot,
    required String buildNumber,
    required String version,
  });
}

class FilePipelineLogWriter implements PipelineLogWriter {
  const FilePipelineLogWriter();

  @override
  Future<String> save({
    required List<ConsoleLine> lines,
    required String projectRoot,
    required String buildNumber,
    required String version,
  }) async {
    final fileName = buildPipelineLogFileName(
      buildNumber: buildNumber,
      version: version,
    );

    final logsDir = Directory(p.join(projectRoot, 'logs'));
    await logsDir.create(recursive: true);

    final file = File(p.join(logsDir.path, fileName));
    await file.writeAsString(formatPipelineLogLines(lines));

    return file.path;
  }
}

String pipelineLogRelativePath({
  required String buildNumber,
  required String version,
}) {
  return p.join(
    'logs',
    buildPipelineLogFileName(buildNumber: buildNumber, version: version),
  );
}
