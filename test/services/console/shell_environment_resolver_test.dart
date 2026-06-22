import 'package:fluship/services/console/shell_environment_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellEnvironmentResolver.parseFlutterRootFromConfig', () {
    test('reads FLUTTER_ROOT from xcconfig', () {
      expect(
        ShellEnvironmentResolver.parseFlutterRootFromConfig('''
// generated
FLUTTER_ROOT=/Users/dev/flutter
FLUTTER_APPLICATION_PATH=/app
'''),
        '/Users/dev/flutter',
      );
    });

    test('reads flutter.sdk from local.properties', () {
      expect(
        ShellEnvironmentResolver.parseFlutterRootFromConfig('''
sdk.dir=/android/sdk
flutter.sdk=/Users/dev/flutter
'''),
        '/Users/dev/flutter',
      );
    });

    test('returns null when no flutter root is present', () {
      expect(
        ShellEnvironmentResolver.parseFlutterRootFromConfig(
          'sdk.dir=/android/sdk',
        ),
        isNull,
      );
    });
  });

  group('ShellEnvironmentResolver.prependPathSegment', () {
    test('prepends flutter bin when missing', () {
      expect(
        ShellEnvironmentResolver.prependPathSegment(
          segment: '/Users/dev/flutter/bin',
          path: '/usr/bin:/bin',
        ),
        '/Users/dev/flutter/bin:/usr/bin:/bin',
      );
    });

    test('does not duplicate an existing segment', () {
      expect(
        ShellEnvironmentResolver.prependPathSegment(
          segment: '/Users/dev/flutter/bin',
          path: '/Users/dev/flutter/bin:/usr/bin',
        ),
        '/Users/dev/flutter/bin:/usr/bin',
      );
    });
  });
}
