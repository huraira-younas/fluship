import 'dart:io';

void main() {
  final here = File.fromUri(Platform.script).parent.parent;
  final result = Process.runSync('python3', [
    'whatsapp_send_test.py',
  ], workingDirectory: here.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw StateError('whatsapp_send_test.py failed');
  }
}
