import 'dart:io' show Directory, File;
import 'package:path/path.dart' as p;

class FileArtifactCollector {
  const FileArtifactCollector();

  /// Filesystem timestamps can lag slightly behind the clock, and a build can
  /// start writing just before the run is registered.
  static const _staleTolerance = Duration(seconds: 5);

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
    required DateTime notBefore,
  }) => _collectByExtension(
    sourceRelative: _apkSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    notBefore: notBefore,
    extension: '.apk',
  );

  Future<List<String>> collectAab({
    required String sourceRoot,
    required String outputDir,
    required DateTime notBefore,
  }) => _collectByExtension(
    sourceRelative: _aabSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    notBefore: notBefore,
    extension: '.aab',
  );

  Future<List<String>> collectIpa({
    required String sourceRoot,
    required String outputDir,
    required DateTime notBefore,
  }) => _collectByExtension(
    sourceRelative: _ipaSourceRelative,
    sourceRoot: sourceRoot,
    outputDir: outputDir,
    notBefore: notBefore,
    extension: '.ipa',
  );

  Future<List<String>> _collectByExtension({
    required String sourceRelative,
    required String sourceRoot,
    required DateTime notBefore,
    required String extension,
    required String outputDir,
  }) async {
    final sourceDir = Directory(p.join(sourceRoot, sourceRelative));
    if (!await sourceDir.exists()) {
      throw StateError('No artifacts found at ${sourceDir.path}');
    }

    final cutoff = notBefore.subtract(_staleTolerance);
    final stale = <String>[];
    final files = <File>[];

    await for (final entity in sourceDir.list()) {
      if (entity is! File || !entity.path.endsWith(extension)) continue;

      if ((await entity.lastModified()).isBefore(cutoff)) {
        stale.add(p.basename(entity.path));
      } else {
        files.add(entity);
      }
    }

    if (files.isEmpty) {
      throw StateError(
        stale.isEmpty
            ? 'No *$extension artifacts found in ${sourceDir.path}'
            : 'Only artifacts from an earlier build were found in '
                  '${sourceDir.path}: ${stale.join(', ')}. '
                  'Nothing was produced by this run.',
      );
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
