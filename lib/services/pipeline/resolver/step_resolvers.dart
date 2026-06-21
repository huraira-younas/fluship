import 'dart:io' show Platform;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/services/distribution/distribution_service.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';

import '../paths/fluship_workspace_paths.dart';
import '../artifacts/artifact_collector.dart';
import 'distribution_step_kind.dart';
import 'config_state_context.dart';
import 'git_step_builder.dart';
import 'command_step.dart';

const _artifactCollector = FileArtifactCollector();
const _workspacePaths = FlushipWorkspacePaths();
const _projectService = FlutterProjectService();

List<CommandStep> resolveAppInfo(ConfigState state) {
  if (state.version.isEmpty || state.buildNumber.isEmpty) return const [];

  final projectPath = state.projectRoot;
  final buildNumber = state.buildNumber;
  final version = state.version;

  return [
    CommandStep(
      name: 'Bump Version',
      command: 'pubspec: $version+$buildNumber',
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
      const CommandStep(name: 'Clean', command: 'flutter clean'),
    if (commonCmd.type == .get)
      const CommandStep(name: 'Get', command: 'flutter pub get'),
    if (commonCmd.type == .upgrade)
      const CommandStep(name: 'Upgrade', command: 'flutter pub upgrade'),
  ];
}

List<CommandStep> resolveAndroid(ConfigState state) {
  if (!state.android.enabled) return const [];

  final android = state.android;
  return [
    if (android.buildAab) ...[
      const CommandStep(
        command: 'flutter build aab --release',
        name: 'Build App Bundle',
      ),
      _collectArtifactStep(
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
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectArtifactStep(
            collector: _artifactCollector.collectApks,
            command: 'collect: apk',
            name: 'Collect APK',
            state,
          ),
        ],
        .arbs => [
          const CommandStep(
            command: 'flutter build apk --split-per-abi',
            name: 'Build AAR',
          ),
          _collectArtifactStep(
            collector: _artifactCollector.collectApks,
            name: 'Collect Split APKs',
            command: 'collect: apk',
            state,
          ),
        ],
        _ => [
          const CommandStep(
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectArtifactStep(
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
  if (!Platform.isIOS || !state.ios.enabled) return const [];

  final ios = state.ios;
  return [
    if (ios.podClean)
      const CommandStep(
        command: 'pod deintegrate && pod update && pod install',
        name: 'Pod Clean',
      ),
    if (ios.buildIpa) ...[
      const CommandStep(name: 'Build IPA', command: 'flutter build ipa'),
      _collectArtifactStep(
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

List<CommandStep> resolveDistribution(
  ConfigState state, {
  required Map<DistributionStepKind, DistributionHandler> handlers,
  required Future<DistributionContext> Function() contextProvider,
}) {
  final distribution = state.distribution;
  if (!distribution.enabled) return const [];

  CommandStep distributionStep(DistributionStepKind kind) {
    final handler = handlers[kind]!;
    return CommandStep(
      command: kind.command,
      name: kind.label,
      onExecute: () async {
        final context = await contextProvider();
        final result = await handler.run(context);
        await logDistributionHandlerResult(
          result,
          context.logger,
          handler.name,
        );
        if (result.isFailed) {
          throw Exception(result.message);
        }
      },
    );
  }

  return [
    for (final kind in <DistributionStepKind>[
      if (distribution.canSendToDrive) .drive,
      if (distribution.canSendToAppStore) .appStore,
      if (distribution.canSendToPlayStore) .playStore,
      if (distribution.canSendBuildReport) .report,
    ])
      if (handlers.containsKey(kind)) distributionStep(kind),
  ];
}

List<CommandStep> resolvePostBuild(ConfigState state) {
  if (!state.postBuild.enabled) return const [];

  final postBuild = state.postBuild;
  return [
    if (postBuild.openOutputs)
      const CommandStep(command: 'open build/outputs', name: 'Open Outputs'),
    if (postBuild.powerConfig != null)
      CommandStep(
        command: 'power ${postBuild.powerConfig!.action.name}',
        name: 'Power',
      ),
  ];
}

CommandStep _collectArtifactStep(
  ConfigState state, {
  required Future<List<String>> Function({
    required String sourceRoot,
    required String outputDir,
  })
  collector,

  required String command,
  required String name,
}) {
  return CommandStep(
    command: command,
    name: name,
    onExecute: () async {
      final flushipRoot = await _workspacePaths.resolveRoot();
      final outputDir = pipelineOutputDirectory(
        projectName: state.appInfo.appName ?? 'unknown',
        buildNumber: state.buildNumber,
        flushipRoot: flushipRoot,
        version: state.version,
      );
      await collector(sourceRoot: state.projectRoot, outputDir: outputDir);
    },
  );
}
