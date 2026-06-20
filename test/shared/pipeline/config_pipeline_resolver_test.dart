import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:fluship/shared/models/pre_git.dart';
import 'package:fluship/shared/pipeline/config_pipeline_resolver.dart';
import 'package:fluship/shared/pipeline/config_state_context.dart';
import 'package:flutter_test/flutter_test.dart';

ConfigState _state({
  AppInfoModel? appInfo,
  PreGitModel? preGit,
  CommonCmdModel? commonCmd,
  AndroidConfigModel? android,
  PostGitModel? postGit,
  PostBuildConfigModel? postBuild,
}) {
  final base = ConfigState.empty();
  return base.copyWith(
    appInfo: appInfo ?? base.appInfo,
    preGit: preGit ?? base.preGit,
    commonCmd: commonCmd ?? base.commonCmd,
    android: android ?? base.android,
    postGit: postGit ?? base.postGit,
    postBuild: postBuild ?? base.postBuild,
  );
}

void main() {
  group('ConfigPipelineResolver', () {
    test('returns empty list for default empty state', () {
      expect(ConfigPipelineResolver.resolve(ConfigState.empty()), isEmpty);
    });

    test('resolves app info bump step when version and build number set', () {
      final state = _state(
        appInfo: const AppInfoModel(
          flutterProjectPath: '/project',
          buildNumber: '42',
          version: '2.0.0',
        ),
      );

      final steps = ConfigPipelineResolver.resolve(state);

      expect(steps, hasLength(1));
      expect(steps.first.name, 'Bump Version');
      expect(steps.first.command, 'pubspec: 2.0.0+42');
      expect(steps.first.isInternal, isTrue);
    });

    test('resolves pre-git steps in order after app info', () {
      final state = _state(
        appInfo: const AppInfoModel(
          flutterProjectPath: '/project',
          buildNumber: '1',
          version: '1.0.0',
        ),
        preGit: const PreGitModel(
          preCommit: true,
          prePull: true,
          targetBranch: 'develop',
        ),
      );

      final steps = ConfigPipelineResolver.resolve(state);
      final names = steps.map((step) => step.name).toList();

      expect(names, ['Bump Version', 'Pre-Commit', 'Pre-Pull']);
      expect(steps[1].command, contains('git commit'));
      expect(steps[2].command, 'git pull origin develop');
    });

    test('skips disabled sections', () {
      final state = _state(
        commonCmd: const CommonCmdModel(enabled: false, clean: true),
        android: const AndroidConfigModel(enabled: false, buildAab: true),
      );

      expect(ConfigPipelineResolver.resolve(state), isEmpty);
    });

    test('resolves common and android steps', () {
      final state = _state(
        commonCmd: const CommonCmdModel(clean: true, type: FlutterGetType.get),
        android: const AndroidConfigModel(
          buildAab: true,
          buildType: AndroidBuildType.apk,
        ),
      );

      final names = ConfigPipelineResolver.resolve(
        state,
      ).map((step) => step.name).toList();

      expect(names, [
        'Clean',
        'Get',
        'Build App Bundle',
        'Collect App Bundle',
        'Build APK',
        'Collect APK',
      ]);
    });

    test('resolves post-git with version placeholder in commit message', () {
      final state = _state(
        appInfo: const AppInfoModel(version: '3.1.4'),
        postGit: const PostGitModel(postCommit: true, targetBranch: 'main'),
      );

      final steps = ConfigPipelineResolver.resolve(state);
      final commitStep = steps.firstWhere((step) => step.name == 'Post-Commit');

      expect(commitStep.command, contains('3.1.4 release'));
    });

    test('resolves post-build steps', () {
      final state = _state(
        postBuild: const PostBuildConfigModel(
          openOutputs: true,
          powerConfig: PowerConfig(),
        ),
      );

      final names = ConfigPipelineResolver.resolve(
        state,
      ).map((step) => step.name).toList();

      expect(names, ['Open Outputs', 'Power']);
    });

    test('pipelineSteps getter matches resolver', () {
      final state = _state(
        appInfo: const AppInfoModel(buildNumber: '5', version: '1.0.0'),
      );

      expect(state.pipelineSteps, ConfigPipelineResolver.resolve(state));
    });
  });

  group('ConfigStateContext', () {
    test('resolveCommitMessage replaces version placeholder', () {
      final state = _state(appInfo: const AppInfoModel(version: '9.9.9'));

      expect(
        state.resolveCommitMessage(null, fallback: '{version} cleanup'),
        '9.9.9 cleanup',
      );
    });

    test('gitBranch falls back through preGit, postGit, then master', () {
      expect(_state().gitBranch, 'master');
      expect(
        _state(preGit: const PreGitModel(targetBranch: 'dev')).gitBranch,
        'dev',
      );
    });
  });
}
