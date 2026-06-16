import 'package:fluship/services/project_service.dart/pubspec_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = PubspecParser();

  test('parse extracts name, version, and build number', () {
    const content = '''
name: fluship
description: "A new Flutter project."
version: 1.0.0+1
''';

    final result = parser.parse(content);

    expect(result.projectName, 'fluship');
    expect(result.version, '1.0.0');
    expect(result.buildNumber, '1');
  });

  test('parse supports version without build number', () {
    const content = '''
name: my_app
version: 2.3.4
''';

    final result = parser.parse(content);

    expect(result.projectName, 'my_app');
    expect(result.version, '2.3.4');
    expect(result.buildNumber, isNull);
  });
}
