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

  Future<void> importConfig(ConfigBloc bloc, Map<String, dynamic> data) async {
    final completer = Completer<void>();
    bloc.add(
      ImportConfig(
        data: data,
        onSuccess: (_) => completer.complete(),
        onError: (error) => completer.completeError(error.message),
      ),
    );
    await completer.future;
  }

  test('imports every legacy snake case config section', () async {
    final projectDir = Directory('${tempDir.path}/reelstay');
    await projectDir.create();
    await File('${projectDir.path}/pubspec.yaml').writeAsString('''
name: reelstay
version: 1.5.7+5795
''');

    final bloc = ConfigBloc(store);
    addTearDown(bloc.close);

    await importConfig(bloc, {
      'distribution': {
        'releaseNotes': 'Legacy release notes',
        'enabled': false,
      },
      'post_build': {'openOutputs': true, 'enabled': false},
      'common_cmd': {'type': 'upgrade', 'clean': true, 'enabled': false},
      'app_info': {
        'flutter_project_path': projectDir.path,
        'fluship_workspace_path': tempDir.path,
        'enabled': false,
      },
      'post_git': {
        'commit_message': 'Release {version}',
        'target_branch': 'main',
        'post_commit': true,
        'post_push': true,
        'enabled': false,
      },
      'pre_git': {
        'commit_message': 'Pre-release',
        'target_branch': 'main',
        'pre_commit': true,
        'pre_pull': true,
        'enabled': false,
      },
      'android': {'buildType': 'splits', 'buildAab': true, 'enabled': false},
      'ios': {'podClean': true, 'buildIpa': true, 'enabled': false},
    });

    expect(bloc.state.activeProject, 'reelstay');
    expect(bloc.state.distribution.releaseNotes, 'Legacy release notes');
    expect(bloc.state.distribution.enabled, isFalse);
    expect(bloc.state.postBuild.openOutputs, isTrue);
    expect(bloc.state.postBuild.enabled, isFalse);
    expect(bloc.state.commonCmd.type?.name, 'upgrade');
    expect(bloc.state.commonCmd.clean, isTrue);
    expect(bloc.state.commonCmd.enabled, isFalse);
    expect(bloc.state.appInfo.flutterProjectPath, projectDir.path);
    expect(bloc.state.appInfo.flushipWorkspacePath, tempDir.path);
    expect(bloc.state.appInfo.enabled, isFalse);
    expect(bloc.state.postGit.postCommit, isTrue);
    expect(bloc.state.postGit.postPush, isTrue);
    expect(bloc.state.postGit.enabled, isFalse);
    expect(bloc.state.preGit.preCommit, isTrue);
    expect(bloc.state.preGit.prePull, isTrue);
    expect(bloc.state.preGit.enabled, isFalse);
    expect(bloc.state.android.buildType?.name, 'splits');
    expect(bloc.state.android.buildAab, isTrue);
    expect(bloc.state.android.enabled, isFalse);
    expect(bloc.state.ios.podClean, isTrue);
    expect(bloc.state.ios.buildIpa, isTrue);
    expect(bloc.state.ios.enabled, isFalse);
  });

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
