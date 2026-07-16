import 'dart:io' show Directory, File;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/project_service.dart/pubspec_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
    'bumpVersion inserts version when pubspec has name but no version line',
    () async {
      await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
description: Test
''');

      await service.bumpVersion(
        projectPath: tempDir.path,
        buildNumber: '1',
        version: '1.0.0',
      );

      final parsed = parser.parse(
        await File('${tempDir.path}/pubspec.yaml').readAsString(),
      );
      expect(parsed.version, '1.0.0');
      expect(parsed.buildNumber, '1');
    },
  );

  test('bumpVersion throws when pubspec.yaml has no name field', () async {
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
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
  });

  test('bumpVersion replaces indented version line', () async {
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
description: Test
  version: 1.0.0+1
''');

    await service.bumpVersion(
      projectPath: tempDir.path,
      buildNumber: '42',
      version: '3.0.0',
    );

    final parsed = parser.parse(
      await File('${tempDir.path}/pubspec.yaml').readAsString(),
    );
    expect(parsed.version, '3.0.0');
    expect(parsed.buildNumber, '42');
  });

  test('bumpVersion inserts version after name when line is missing', () async {
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
description: Test
environment:
  sdk: ^3.0.0
''');

    await service.bumpVersion(
      projectPath: tempDir.path,
      buildNumber: '5705',
      version: '1.5.7',
    );

    final parsed = parser.parse(
      await File('${tempDir.path}/pubspec.yaml').readAsString(),
    );
    expect(parsed.version, '1.5.7');
    expect(parsed.buildNumber, '5705');
  });

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

  test('extractAppInfo resolves the configured launcher icon', () async {
    final icon = File('${tempDir.path}/assets/branding/logo.png');
    await icon.parent.create(recursive: true);
    await icon.writeAsBytes(const [0, 1, 2]);
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
version: 1.0.0+1
flutter_launcher_icons:
  image_path: assets/branding/logo.png
''');

    final appInfo = await service.extractAppInfo(
      flutterProjectPath: tempDir.path,
    );

    expect(appInfo.appIconPath, p.normalize(icon.path));
  });

  test('extractAppInfo ignores a missing launcher icon', () async {
    await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: test_app
version: 1.0.0+1
flutter_launcher_icons:
  image_path: assets/missing.png
''');

    final appInfo = await service.extractAppInfo(
      flutterProjectPath: tempDir.path,
    );

    expect(appInfo.appIconPath, isNull);
  });
}
