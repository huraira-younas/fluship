import 'dart:io' show Platform, Process;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/services/distribution/distribution_handler_log.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/post_build_config.dart';

import '../paths/fluship_workspace_paths.dart';
import '../artifacts/artifact_collector.dart';
import 'distribution_step_kind.dart';
import 'config_state_context.dart';
import 'git_step_builder.dart';
import 'command_step.dart';

const _artifactCollector = FileArtifactCollector();
const _projectService = FlutterProjectService();

List<CommandStep> resolveAppInfo(ConfigState state) {
  if (state.version.isEmpty || state.buildNumber.isEmpty) return const [];

  final projectPath = state.projectRoot;
  final buildNumber = state.buildNumber;
  final version = state.version;

  return [
    CommandStep(
      description:
          'Set version $version and build number $buildNumber in pubspec.yaml',
      command: 'pubspec: $version+$buildNumber',
      name: 'Bump Version',
      onExecute: () => _projectService.bumpVersion(
        projectPath: projectPath,
        buildNumber: buildNumber,
        version: version,
      ),
    ),
  ];
}

List<CommandStep> resolvePreGit(ConfigState state) {
  if (!state.preGit.enabled) return const [];

  return [
    if (state.preGit.preCommit)
      GitStepBuilder.commit(
        name: 'Pre-Commit',
        message: state.resolveCommitMessage(
          fallback: '{version} cleanup',
          state.preGit.commitMessage,
        ),
      ),
    if (state.preGit.prePull)
      GitStepBuilder.pull(branch: state.gitBranch, name: 'Pre-Pull'),
  ];
}

List<CommandStep> resolveCommonCmd(ConfigState state) {
  if (!state.commonCmd.enabled) return const [];

  final commonCmd = state.commonCmd;
  return [
    if (commonCmd.clean)
      const CommandStep(
        description: 'Remove build cache and temporary Flutter files',
        command: 'flutter clean',
        name: 'Clean',
      ),
    if (commonCmd.type == .get)
      const CommandStep(
        description: 'Download and resolve package dependencies',
        command: 'flutter pub get',
        name: 'Get',
      ),
    if (commonCmd.type == .upgrade)
      const CommandStep(
        description: 'Upgrade packages to the latest compatible versions',
        command: 'flutter pub upgrade',
        name: 'Upgrade',
      ),
  ];
}

List<CommandStep> resolveAndroid(ConfigState state) {
  if (!state.android.enabled) return const [];

  final android = state.android;
  return [
    if (android.buildAab) ...[
      const CommandStep(
        description: 'Compile a signed release Android App Bundle (.aab)',
        command: 'flutter build aab --release',
        name: 'Build App Bundle',
      ),
      _collectArtifactStep(
        description:
            'Copy the release App Bundle to your Fluship output folder',
        collector: _artifactCollector.collectAab,
        name: 'Collect App Bundle',
        command: 'collect: aab',
        state,
      ),
    ],
    if (android.buildType != null)
      ...switch (android.buildType) {
        .apk => [
          const CommandStep(
            description: 'Compile a signed release APK',
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectArtifactStep(
            description: 'Copy the release APK to your Fluship output folder',
            collector: _artifactCollector.collectApks,
            command: 'collect: apk',
            name: 'Collect APK',
            state,
          ),
        ],
        .arbs => [
          const CommandStep(
            description:
                'Build separate release APKs for each CPU architecture',
            command: 'flutter build apk --split-per-abi',
            name: 'Build AAR',
          ),
          _collectArtifactStep(
            description:
                'Copy the split APK files to your Fluship output folder',
            collector: _artifactCollector.collectApks,
            name: 'Collect Split APKs',
            command: 'collect: apk',
            state,
          ),
        ],
        _ => [
          const CommandStep(
            description: 'Compile a signed release APK',
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectArtifactStep(
            description: 'Copy the release APK to your Fluship output folder',
            collector: _artifactCollector.collectApks,
            command: 'collect: apk',
            name: 'Collect APK',
            state,
          ),
        ],
      },
  ];
}

List<CommandStep> resolveIos(ConfigState state) {
  if (!Platform.isMacOS || !state.ios.enabled) return const [];

  final ios = state.ios;
  return [
    if (ios.podClean)
      const CommandStep(
        description: 'Install and update iOS CocoaPods dependencies',
        command: '(cd ios && pod install --repo-update)',
        name: 'Pod Install',
      ),
    if (ios.buildIpa) ...[
      const CommandStep(
        description: 'Compile a signed release IPA for iOS',
        command: 'flutter build ipa',
        name: 'Build IPA',
      ),
      _collectArtifactStep(
        description: 'Copy the release IPA to your Fluship output folder',
        collector: _artifactCollector.collectIpa,
        command: 'collect: ipa',
        name: 'Collect IPA',
        state,
      ),
    ],
  ];
}

List<CommandStep> resolvePostGit(ConfigState state) {
  if (!state.postGit.enabled) return const [];

  return [
    if (state.postGit.postCommit)
      GitStepBuilder.commit(
        name: 'Post-Commit',
        message: state.resolveCommitMessage(
          fallback: '{version} release',
          state.postGit.commitMessage,
        ),
      ),
    if (state.postGit.postPush)
      GitStepBuilder.push(branch: state.gitBranch, name: 'Post-Push'),
  ];
}

CommandStep _distributionStep(
  DistributionStepKind kind, {
  required Map<DistributionStepKind, DistributionHandler> handlers,
  required Future<DistributionContext> Function() contextProvider,
}) {
  final handler = handlers[kind]!;
  return CommandStep(
    description: kind.description,
    command: kind.command,
    name: kind.name,
    onExecute: () async {
      final context = await contextProvider();
      final result = await handler.run(context);
      await logDistributionHandlerResult(result, context.logger, handler.name);
      if (result.isFailed) throw Exception(result.message);
    },
  );
}

bool _distributionFlag(bool? value) => value ?? false;

List<CommandStep> resolveDistribution(
  ConfigState state, {
  required Map<DistributionStepKind, DistributionHandler> handlers,
  required Future<DistributionContext> Function() contextProvider,
}) {
  final dist = state.distribution;
  if (!dist.enabled) return const [];

  return [
    for (final kind in <DistributionStepKind>[
      if (dist.canSendToAppStore && _distributionFlag(dist.appstore?.enabled))
        .appStore,
      if (dist.canSendToDrive && _distributionFlag(dist.driveConfig?.enabled))
        .drive,
      if (dist.canSendToPlayStore &&
          _distributionFlag(dist.playstore?.distribution != null))
        .playStore,
    ])
      if (handlers.containsKey(kind))
        _distributionStep(
          contextProvider: contextProvider,
          handlers: handlers,
          kind,
        ),
  ];
}

List<CommandStep> resolveReport(
  ConfigState state, {
  required Map<DistributionStepKind, DistributionHandler> handlers,
  required Future<DistributionContext> Function() contextProvider,
}) {
  final dist = state.distribution;
  if (!dist.enabled) return const [];
  if (!dist.canSendBuildReport) return const [];
  if (!_distributionFlag(dist.reportRecipient?.buildReport)) return const [];

  const kind = DistributionStepKind.report;
  if (!handlers.containsKey(kind)) return const [];

  return [
    _distributionStep(
      contextProvider: contextProvider,
      handlers: handlers,
      kind,
    ),
  ];
}

List<CommandStep> resolvePostBuild(ConfigState state) {
  if (!state.postBuild.enabled) return const [];

  final postBuild = state.postBuild;
  return [
    if (postBuild.openOutputs)
      CommandStep(
        description: 'Open this build\'s output folder in your file manager',
        command: 'open: fluship outputs',
        name: 'Open Outputs',
        onExecute: () async {
          final outputDir = pipelineOutputDirectory(
            flushipRoot: state.appInfo.flushipWorkspacePath ?? '',
            projectName: state.appInfo.appName ?? 'unknown',
            buildNumber: state.buildNumber,
            version: state.version,
          );

          if (Platform.isMacOS) {
            await Process.run('open', [outputDir]);
            return;
          }

          if (Platform.isWindows) {
            await Process.run('explorer', [outputDir]);
            return;
          }

          await Process.run('xdg-open', [outputDir]);
        },
      ),
    if (postBuild.powerConfig != null)
      CommandStep(
        description: _powerStepDescription(postBuild.powerConfig!.action),
        command: 'power ${postBuild.powerConfig!.action.name}',
        name: 'Power',
      ),
  ];
}

String _powerStepDescription(PowerAction action) => switch (action) {
  .shutdown => 'Shut down the computer after the pipeline finishes',
  .sleep => 'Put the computer to sleep after the pipeline finishes',
  .lock => 'Lock the screen after the pipeline finishes',
};

CommandStep _collectArtifactStep(
  ConfigState state, {
  required Future<List<String>> Function({
    required String sourceRoot,
    required String outputDir,
  })
  collector,
  required String description,
  required String command,
  required String name,
}) {
  return CommandStep(
    description: description,
    command: command,
    name: name,
    onExecute: () async {
      final outputDir = pipelineOutputDirectory(
        flushipRoot: state.appInfo.flushipWorkspacePath ?? '',
        projectName: state.appInfo.appName ?? 'unknown',
        buildNumber: state.buildNumber,
        version: state.version,
      );
      await collector(sourceRoot: state.projectRoot, outputDir: outputDir);
    },
  );
}
