import 'dart:io' show Directory, File;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/project_service.dart/pubspec_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FlutterProjectService();
  const parser = PubspecParser();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fluship_bump_test_');
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
description: Test
version: 1.0.0+1
''');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('bumpVersion updates version line in pubspec.yaml', () async {
    await service.bumpVersion(
      projectPath: tempDir.path,
      buildNumber: '99',
      version: '2.5.0',
    );

    final content = await File('${tempDir.path}/pubspec.yaml').readAsString();
    final parsed = parser.parse(content);

    expect(parsed.version, '2.5.0');
    expect(parsed.buildNumber, '99');
  });

  test(
    'bumpVersion throws when pubspec.yaml is missing version field',
    () async {
      await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
description: Test
''');

      expect(
        () => service.bumpVersion(
          projectPath: tempDir.path,
          buildNumber: '1',
          version: '1.0.0',
        ),
        throwsA(isA<FlutterProjectException>()),
      );
    },
  );

  test('bumpVersion throws when project path does not exist', () async {
    expect(
      () => service.bumpVersion(
        projectPath: '${tempDir.path}/missing',
        buildNumber: '1',
        version: '1.0.0',
      ),
      throwsA(isA<FlutterProjectException>()),
    );
  });
}
