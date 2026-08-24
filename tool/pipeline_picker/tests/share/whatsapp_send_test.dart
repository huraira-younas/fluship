import 'dart:io';

import '../support/tool_root.dart';

void main() {
  final result = Process.runSync('python3', [
    'pipeline_picker/tests/share/whatsapp_send_test.py',
  ], workingDirectory: pipelineToolRoot());
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw StateError('whatsapp_send_test.py failed');
  }
}
