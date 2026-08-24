import 'dart:io';

/// Walks up from the running script until `pipeline_warmup.dart` is found.
String pipelineToolRoot() {
  var dir = File.fromUri(Platform.script).absolute.parent;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${dir.path}${Platform.pathSeparator}pipeline_warmup.dart',
    ).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Fluship tool/ root not found');
}
