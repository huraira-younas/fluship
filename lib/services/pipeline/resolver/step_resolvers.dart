import 'dart:io' show Platform, Process;

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
  if (!Platform.isMacOS || !state.ios.enabled) return const [];

  final ios = state.ios;
  return [
    if (ios.podClean)
      const CommandStep(
        command: '(cd ios && pod install --repo-update)',
        name: 'Pod Install',
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
  final dist = state.distribution;
  if (!dist.enabled) return const [];

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

  bool vl(bool? v) => v ?? false;

  return [
    for (final kind in <DistributionStepKind>[
      if (dist.canSendToAppStore && vl(dist.appstore?.enabled)) .appStore,
      if (dist.canSendToDrive && vl(dist.driveConfig?.enabled)) .drive,

      if (dist.canSendToPlayStore && vl(dist.playstore?.distribution != null))
        .playStore,
      if (dist.canSendBuildReport && vl(dist.reportRecipient?.buildReport))
        .report,
    ])
      if (handlers.containsKey(kind)) distributionStep(kind),
  ];
}

List<CommandStep> resolvePostBuild(ConfigState state) {
  if (!state.postBuild.enabled) return const [];

  final postBuild = state.postBuild;
  return [
    if (postBuild.openOutputs)
      CommandStep(
        name: 'Open Outputs',
        command: 'open: fluship outputs',
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
