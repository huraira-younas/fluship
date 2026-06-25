import 'dart:io' show Directory, File;
import 'package:path/path.dart' as p;

class FileArtifactCollector {
  const FileArtifactCollector();

  static final _apkSourceRelative = p.join(
    'build',
    'app',
    'outputs',
    'flutter-apk',
  );
  static final _aabSourceRelative = p.join(
    'build',
    'app',
    'outputs',
    'bundle',
    'release',
  );
  static final _ipaSourceRelative = p.join('build', 'ios', 'ipa');

  Future<List<String>> collectApks({
    required String sourceRoot,
    required String outputDir,
  }) => _collectByExtension(
    sourceRelative: _apkSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    extension: '.apk',
  );

  Future<List<String>> collectAab({
    required String sourceRoot,
    required String outputDir,
  }) => _collectByExtension(
    sourceRelative: _aabSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    extension: '.aab',
  );

  Future<List<String>> collectIpa({
    required String sourceRoot,
    required String outputDir,
  }) => _collectByExtension(
    sourceRelative: _ipaSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    extension: '.ipa',
  );

  Future<List<String>> _collectByExtension({
    required String sourceRelative,
    required String sourceRoot,
    required String extension,
    required String outputDir,
  }) async {
    final sourceDir = Directory(p.join(sourceRoot, sourceRelative));
    if (!await sourceDir.exists()) {
      throw StateError('No artifacts found at ${sourceDir.path}');
    }

    final files = <File>[];
    await for (final entity in sourceDir.list()) {
      if (entity is File && entity.path.endsWith(extension)) {
        files.add(entity);
      }
    }

    if (files.isEmpty) {
      throw StateError('No *$extension artifacts found in ${sourceDir.path}');
    }

    final destDir = Directory(outputDir);
    await destDir.create(recursive: true);

    final copied = <String>[];
    for (final file in files) {
      final destPath = p.join(outputDir, p.basename(file.path));
      await file.copy(destPath);
      copied.add(destPath);
    }

    return copied;
  }
}
