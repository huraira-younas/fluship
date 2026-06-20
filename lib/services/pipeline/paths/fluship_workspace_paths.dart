import 'dart:io' show Directory, File, Platform;
import 'package:path/path.dart' as p;

import '../utils/pipeline_utils.dart';

class FlushipWorkspacePaths {
  const FlushipWorkspacePaths({this.overrideRoot});
  final String? overrideRoot;

  static const _flushipPackageName = 'fluship';

  Future<String> resolveRoot() async {
    final override = overrideRoot;
    if (override != null && override.isNotEmpty) return override;

    for (final start in _rootCandidates()) {
      final root = await _findFlushipRootFrom(start);
      if (root != null) return root;
    }

    return Directory.current.path;
  }

  Iterable<String> _rootCandidates() sync* {
    yield Directory.current.path;

    final executable = Platform.resolvedExecutable;
    yield File(executable).parent.path;
    yield p.dirname(executable);
  }

  Future<String?> _findFlushipRootFrom(String startPath) async {
    var directory = Directory(startPath);

    while (true) {
      final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
      if (await pubspec.exists()) {
        final content = await pubspec.readAsString();
        if (_isFlushipPubspec(content)) return directory.path;
      }

      final parent = directory.parent;
      if (parent.path == directory.path) return null;
      directory = parent;
    }
  }

  bool _isFlushipPubspec(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('name:')) {
        final name = trimmed.substring('name:'.length).trim();
        return name == _flushipPackageName;
      }
    }

    return false;
  }
}

String pipelineOutputDirectory({
  required String flushipRoot,
  required String projectName,
  required String buildNumber,
  required String version,
}) {
  return p.join(
    flushipRoot,
    'outputs',
    PipelineUtils.sanitizeProjectFolderName(projectName),
    'v${PipelineUtils.sanitizePathSegment(version)}',
    PipelineUtils.sanitizePathSegment(buildNumber),
  );
}
