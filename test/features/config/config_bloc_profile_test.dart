import 'dart:async' show Completer;
import 'dart:io' show Directory, File;

import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProjectProfilesStore store;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs.i.init();
    store = ProjectProfilesStore();
    tempDir = await Directory.systemTemp.createTemp('fluship_profiles_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> saveProfile(String projectName) async {
    final projectDir = Directory('${tempDir.path}/$projectName');
    await projectDir.create();
    final appIcon = File('${projectDir.path}/assets/app_logo.png');
    await appIcon.parent.create();
    await appIcon.writeAsBytes(const [0, 1, 2]);
    await File('${projectDir.path}/pubspec.yaml').writeAsString('''
name: $projectName
version: 1.0.0+1
''');

    final config = ConfigState.empty().copyWith(
      activeProject: projectName,
      appInfo: AppInfoModel(
        flutterProjectPath: projectDir.path,
        projectName: projectName,
      ),
    );
    await store.saveProfile(projectName, config.toJson());
  }

  Future<void> loadConfig(ConfigBloc bloc) async {
    final completer = Completer<void>();
    bloc.add(
      LoadConfig(
        onSuccess: (_) => completer.complete(),
        onError: (error) => completer.completeError(error.message),
      ),
    );
    await completer.future;
  }

  Future<void> deleteProfile(ConfigBloc bloc, String projectName) async {
    final completer = Completer<void>();
    bloc.add(
      DeleteProjectProfile(
        projectName: projectName,
        onSuccess: (_) => completer.complete(),
        onError: (error) => completer.completeError(error.message),
      ),
    );
    await completer.future;
  }

  test('deleting active profile selects first remaining profile', () async {
    await saveProfile('call_it');
    await saveProfile('reelstay');
    final bloc = ConfigBloc(store);
    addTearDown(bloc.close);
    await loadConfig(bloc);

    await deleteProfile(bloc, 'reelstay');

    expect(bloc.state.activeProject, 'call_it');
    expect(bloc.state.projectNames, ['call_it']);
    expect(store.activeProject, 'call_it');
  });

  test('resolves runtime icon metadata for every profile', () async {
    await saveProfile('call_it');
    await saveProfile('reelstay');
    final bloc = ConfigBloc(store);
    addTearDown(bloc.close);

    final appInfo = await bloc.resolveProjectAppInfo();

    expect(appInfo.keys, containsAll(['call_it', 'reelstay']));
    expect(appInfo['call_it']?.appIconPath, isNotNull);
    expect(appInfo['reelstay']?.appIconPath, isNotNull);
  });

  test('deleting last active profile emits empty state', () async {
    await saveProfile('reelstay');
    final bloc = ConfigBloc(store);
    addTearDown(bloc.close);
    await loadConfig(bloc);

    await deleteProfile(bloc, 'reelstay');

    expect(bloc.state.activeProject, isNull);
    expect(bloc.state.projectNames, isEmpty);
    expect(store.activeProject, isNull);
  });
}
