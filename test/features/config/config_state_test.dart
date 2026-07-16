import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigState serialization', () {
    test('preserves active project metadata', () {
      final state = ConfigState.empty().copyWith(
        activeProject: 'reelstay',
        projectNames: const ['call_it', 'reelstay'],
      );

      final restored = ConfigState.fromJson(state.toJson());

      expect(restored.activeProject, 'reelstay');
      expect(restored.projectNames, const ['call_it', 'reelstay']);
    });

    test('defaults project metadata for legacy configs', () {
      final json = ConfigState.empty().toJson()
        ..remove('activeProject')
        ..remove('projectNames');

      final restored = ConfigState.fromJson(json);

      expect(restored.activeProject, isNull);
      expect(restored.projectNames, isEmpty);
    });
  });
}
