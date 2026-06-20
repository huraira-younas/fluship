import 'dart:io' show Directory, File;

import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileArtifactCollector', () {
    const collector = FileArtifactCollector();
    late Directory projectRoot;
    late Directory outputDir;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fluship_artifact_');
      projectRoot = Directory(p.join(tempDir.path, 'project'));
      outputDir = Directory(p.join(tempDir.path, 'output'));
      await projectRoot.create(recursive: true);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> writeArtifact({
      required String relativePath,
      required String content,
    }) async {
      final file = File(p.join(projectRoot.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    test(
      'collectApks copies all apk files flat into output directory',
      () async {
        await writeArtifact(
          relativePath: p.join(
            'build',
            'app',
            'outputs',
            'flutter-apk',
            'app-release.apk',
          ),
          content: 'release',
        );
        await writeArtifact(
          relativePath: p.join(
            'build',
            'app',
            'outputs',
            'flutter-apk',
            'app-arm64-v8a-release.apk',
          ),
          content: 'arm64',
        );

        final copied = await collector.collectApks(
          sourceRoot: projectRoot.path,
          outputDir: outputDir.path,
        );

        expect(copied, hasLength(2));
        expect(
          await File(p.join(outputDir.path, 'app-release.apk')).readAsString(),
          'release',
        );
        expect(
          await File(
            p.join(outputDir.path, 'app-arm64-v8a-release.apk'),
          ).readAsString(),
          'arm64',
        );
      },
    );

    test('collectAab copies aab file into output directory', () async {
      await writeArtifact(
        relativePath: p.join(
          'build',
          'app',
          'outputs',
          'bundle',
          'release',
          'app-release.aab',
        ),
        content: 'aab',
      );

      final copied = await collector.collectAab(
        sourceRoot: projectRoot.path,
        outputDir: outputDir.path,
      );

      expect(copied, hasLength(1));
      expect(
        await File(p.join(outputDir.path, 'app-release.aab')).readAsString(),
        'aab',
      );
    });

    test('collectIpa copies ipa file into output directory', () async {
      await writeArtifact(
        relativePath: p.join('build', 'ios', 'ipa', 'MyApp.ipa'),
        content: 'ipa',
      );

      final copied = await collector.collectIpa(
        sourceRoot: projectRoot.path,
        outputDir: outputDir.path,
      );

      expect(copied, hasLength(1));
      expect(
        await File(p.join(outputDir.path, 'MyApp.ipa')).readAsString(),
        'ipa',
      );
    });

    test('overwrites existing artifact with same filename', () async {
      await writeArtifact(
        relativePath: p.join(
          'build',
          'app',
          'outputs',
          'flutter-apk',
          'app-release.apk',
        ),
        content: 'new',
      );

      final d = await File(
        p.join(outputDir.path, 'app-release.apk'),
      ).create(recursive: true);

      d.writeAsStringSync('old');

      await collector.collectApks(
        sourceRoot: projectRoot.path,
        outputDir: outputDir.path,
      );

      expect(
        await File(p.join(outputDir.path, 'app-release.apk')).readAsString(),
        'new',
      );
    });

    test('throws when no artifacts are found', () async {
      await expectLater(
        collector.collectApks(
          sourceRoot: projectRoot.path,
          outputDir: outputDir.path,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
