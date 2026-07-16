import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigState serialization', () {
    test('preserves persisted active project metadata', () {
      final state = ConfigState.empty().copyWith(
        activeProject: 'reelstay',
        projectNames: const ['call_it', 'reelstay'],
        appInfo: const AppInfoModel(appIconPath: r'C:\apps\reelstay\icon.png'),
      );

      final json = state.toJson();
      final restored = ConfigState.fromJson(json);

      expect(restored.activeProject, 'reelstay');
      expect(restored.projectNames, const ['call_it', 'reelstay']);
      expect(
        (json['appInfo'] as Map<String, dynamic>).containsKey('app_icon_path'),
        isFalse,
      );
      expect(restored.appInfo.appIconPath, isNull);
    });

    test('defaults project metadata for legacy configs', () {
      final json = ConfigState.empty().toJson()
        ..remove('activeProject')
        ..remove('projectNames');
      (json['appInfo'] as Map<String, dynamic>)['app_icon_path'] =
          r'C:\stale\icon.png';

      final restored = ConfigState.fromJson(json);

      expect(restored.activeProject, isNull);
      expect(restored.projectNames, isEmpty);
      expect(restored.appInfo.appIconPath, isNull);
    });
  });
}
