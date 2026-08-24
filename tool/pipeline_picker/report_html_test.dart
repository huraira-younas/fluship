import 'dart:io';

void main() {
  final here = File.fromUri(Platform.script).parent.parent;
  final result = Process.runSync('python3', [
    'pipeline_report_test.py',
  ], workingDirectory: here.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw StateError('pipeline_report_test.py failed');
  }
}
