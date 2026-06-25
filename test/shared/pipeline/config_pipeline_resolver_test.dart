import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/models/distribution_result.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/pre_git.dart';
import 'package:flutter_test/flutter_test.dart';

ConfigState _state({
  AppInfoModel? appInfo,
  PreGitModel? preGit,
  CommonCmdModel? commonCmd,
  AndroidConfigModel? android,
  PostGitModel? postGit,
  PostBuildConfigModel? postBuild,
  DistributionConfigModel? distribution,
}) {
  final base = ConfigState.empty();
  return base.copyWith(
    distribution: distribution ?? base.distribution,
    postBuild: postBuild ?? base.postBuild,
    commonCmd: commonCmd ?? base.commonCmd,
    appInfo: appInfo ?? base.appInfo,
    android: android ?? base.android,
    postGit: postGit ?? base.postGit,
    preGit: preGit ?? base.preGit,
  );
}

class _FakeDistributionHandler implements DistributionHandler {
  const _FakeDistributionHandler(this.stepKind);

  final DistributionStepKind stepKind;

  @override
  String get name => stepKind.label;

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    return DistributionResult.success('ok');
  }
}

List<CommandStep> _resolve(ConfigState state) => ConfigPipelineResolver.resolve(
  state,
  contextProvider: () => throw UnimplementedError(),
  reportContextProvider: () => throw UnimplementedError(),
  handlers: const {},
);

void main() {
  group('ConfigPipelineResolver', () {
    test('returns empty list for default empty state', () {
      expect(_resolve(ConfigState.empty()), isEmpty);
    });

    test('resolves app info bump step when version and build number set', () {
      final state = _state(
        appInfo: const AppInfoModel(
          flutterProjectPath: '/project',
          buildNumber: '42',
          version: '2.0.0',
        ),
      );

      final steps = _resolve(state);

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

      final steps = _resolve(state);
      final names = steps.map((step) => step.name).toList();

      expect(names, ['Bump Version', 'Pre-Commit', 'Pre-Pull']);
      expect(steps[1].command, contains('git commit'));
      expect(steps[2].command, '(git pull origin develop) || true');
    });

    test('skips disabled sections', () {
      final state = _state(
        commonCmd: const CommonCmdModel(enabled: false, clean: true),
        android: const AndroidConfigModel(enabled: false, buildAab: true),
      );

      expect(_resolve(state), isEmpty);
    });

    test('resolves common and android steps', () {
      final state = _state(
        commonCmd: const CommonCmdModel(clean: true, type: FlutterGetType.get),
        android: const AndroidConfigModel(
          buildAab: true,
          buildType: AndroidBuildType.apk,
        ),
      );

      final names = _resolve(state).map((step) => step.name).toList();

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

      final steps = _resolve(state);
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

      final names = _resolve(state).map((step) => step.name).toList();

      expect(names, ['Open Outputs', 'Power']);
    });

    test('includes distribution steps when handlers are provided', () {
      final state = _state(
        distribution: const DistributionConfigModel(
          reportRecipient: ReportRecipientConfig(
            reportRecipient: 'dev@example.com',
            gmailAddress: 'sender@gmail.com',
            buildReport: true,
            appPassword: 'secret',
          ),
        ),
      );

      final steps = ConfigPipelineResolver.resolve(
        state,
        handlers: {
          DistributionStepKind.report: const _FakeDistributionHandler(
            DistributionStepKind.report,
          ),
        },
        contextProvider: () => throw UnimplementedError(),
        reportContextProvider: () => throw UnimplementedError(),
      );

      final names = steps.map((step) => step.name).toList();

      expect(names, contains('Send Build Report'));
      expect(
        steps.firstWhere((step) => step.name == 'Send Build Report').isInternal,
        isTrue,
      );
    });

    test('places report step after post-build steps', () {
      final state = _state(
        postBuild: const PostBuildConfigModel(
          openOutputs: true,
          powerConfig: PowerConfig(),
        ),
        distribution: const DistributionConfigModel(
          reportRecipient: ReportRecipientConfig(
            reportRecipient: 'dev@example.com',
            gmailAddress: 'sender@gmail.com',
            buildReport: true,
            appPassword: 'secret',
          ),
        ),
      );

      final steps = ConfigPipelineResolver.resolve(
        state,
        handlers: {
          DistributionStepKind.report: const _FakeDistributionHandler(
            DistributionStepKind.report,
          ),
        },
        contextProvider: () => throw UnimplementedError(),
        reportContextProvider: () => throw UnimplementedError(),
      );

      final names = steps.map((step) => step.name).toList();

      expect(
        names.indexOf('Send Build Report'),
        greaterThan(names.indexOf('Power')),
      );
      expect(names.last, 'Send Build Report');
    });

    test('skips distribution steps when no handlers match', () {
      final state = _state(
        distribution: const DistributionConfigModel(
          reportRecipient: ReportRecipientConfig(
            reportRecipient: 'dev@example.com',
            gmailAddress: 'sender@gmail.com',
            buildReport: true,
            appPassword: 'secret',
          ),
        ),
      );

      final names = _resolve(state).map((step) => step.name).toList();

      expect(names, isNot(contains('Send Build Report')));
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
