import 'package:fluship/services/pipeline/paths/fluship_workspace_paths.dart';
import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlushipWorkspacePaths.resolveRoot', () {
    test('uses overrideRoot when provided', () async {
      final paths = FlushipWorkspacePaths(
        overrideRoot: '/tmp/fluship',
        ProjectProfilesStore(),
      );

      expect(await paths.resolveRoot(), '/tmp/fluship');
    });
  });
}
