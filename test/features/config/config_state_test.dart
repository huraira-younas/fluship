import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigState serialization', () {
    test('preserves active project metadata', () {
      final state = ConfigState.empty().copyWith(
        activeProject: 'reelstay',
        projectNames: const ['call_it', 'reelstay'],
        appInfo: const AppInfoModel(appIconPath: r'C:\apps\reelstay\icon.png'),
      );

      final restored = ConfigState.fromJson(state.toJson());

      expect(restored.activeProject, 'reelstay');
      expect(restored.projectNames, const ['call_it', 'reelstay']);
      expect(restored.appInfo.appIconPath, r'C:\apps\reelstay\icon.png');
    });

    test('defaults project metadata for legacy configs', () {
      final json = ConfigState.empty().toJson()
        ..remove('activeProject')
        ..remove('projectNames');
      (json['appInfo'] as Map<String, dynamic>).remove('app_icon_path');

      final restored = ConfigState.fromJson(json);

      expect(restored.activeProject, isNull);
      expect(restored.projectNames, isEmpty);
      expect(restored.appInfo.appIconPath, isNull);
    });
  });
}
