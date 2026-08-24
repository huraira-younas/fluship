import 'dart:io';

import 'io_helpers.dart';

Future<bool> writeHtmlReportPdf({
  required String logPath,
  required String pdfPath,
  required String appName,
  required String version,
  required String buildNumber,
  required bool success,
  required String steps,
  String excerpt = '',
  List<String> files = const [],
}) async {
  final py = resolvePipelineReportPy();
  if (py == null) return false;
  final htmlPath = pdfPath.replaceAll(RegExp(r'\.pdf$'), '.html');
  final result = await Process.run('python3', [
    py,
    '--log',
    logPath,
    '--pdf',
    pdfPath,
    '--html',
    htmlPath,
    '--app',
    appName,
    '--version',
    version,
    '--build',
    buildNumber,
    '--success',
    success ? 'true' : 'false',
    '--steps',
    steps,
    if (excerpt.isNotEmpty) ...['--error', excerpt],
    if (files.isNotEmpty) ...['--files', files.join(',')],
  ]);
  stdout.write(result.stdout);
  if (result.stderr.toString().trim().isNotEmpty) {
    stderr.write(result.stderr);
  }
  return result.exitCode == 0 &&
      File(pdfPath).existsSync() &&
      File(pdfPath).lengthSync() >= 64;
}

String? resolvePipelineReportPy() {
  final scriptDir = File.fromUri(Platform.script).parent;
  final candidates = <String>[
    pathJoin(scriptDir.path, 'pipeline_report.py'),
    pathJoin(scriptDir.parent.path, 'pipeline_report.py'),
    pathJoin(Directory.current.path, 'tool', 'pipeline_report.py'),
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}
