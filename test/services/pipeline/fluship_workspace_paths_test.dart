import 'package:fluship/services/pipeline/paths/fluship_workspace_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlushipWorkspacePaths.resolveRoot', () {
    test('uses overrideRoot when provided', () async {
      final paths = const FlushipWorkspacePaths(overrideRoot: '/tmp/fluship');

      expect(await paths.resolveRoot(), '/tmp/fluship');
    });
  });
}
