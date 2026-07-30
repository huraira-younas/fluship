import 'dart:io' show Platform, Process;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/services/distribution/distribution_handler_log.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/models/post_build_config.dart';

import '../artifacts/pipeline_run_artifacts.dart';
import '../paths/fluship_workspace_paths.dart';
import '../artifacts/artifact_collector.dart';
import 'distribution_step_kind.dart';
import 'config_state_context.dart';
import 'pipeline_step_id.dart';
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
      id: .bumpVersion,
      isCritical: true,
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
        id: .preCommit,
        message: state.resolveCommitMessage(
          fallback: '{version} cleanup',
          state.preGit.commitMessage,
        ),
      ),
    if (state.preGit.prePull)
      GitStepBuilder.pull(
        branch: state.gitBranch,
        name: 'Pre-Pull',
        id: .prePull,
      ),
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
        isCritical: true,
        name: 'Clean',
        id: .clean,
      ),
    if (commonCmd.type == .get)
      const CommandStep(
        description: 'Download and resolve package dependencies',
        command: 'flutter pub get',
        isCritical: true,
        id: .pubGet,
        name: 'Get',
      ),
    if (commonCmd.type == .upgrade)
      const CommandStep(
        description: 'Upgrade packages to the latest compatible versions',
        command: 'flutter pub upgrade',
        id: .pubUpgrade,
        isCritical: true,
        name: 'Upgrade',
      ),
  ];
}

List<CommandStep> resolveAndroid(
  ConfigState state, {
  required PipelineRunArtifacts artifacts,
}) {
  if (!state.android.enabled) return const [];

  final android = state.android;
  final isSplits = android.buildType == .splits;

  return [
    if (android.buildAab) ...[
      const CommandStep(
        description: 'Compile a signed release Android App Bundle (.aab)',
        command: 'flutter build aab --release',
        name: 'Build App Bundle',
        id: .buildAab,
      ),
      _collectArtifactStep(
        description:
            'Copy the release App Bundle to your Fluship output folder',
        collector: _artifactCollector.collectAab,
        name: 'Collect App Bundle',
        dependsOn: const {.buildAab},
        command: 'collect: aab',
        artifacts: artifacts,
        id: .collectAab,
        state,
      ),
    ],
    if (android.buildType != null) ...[
      CommandStep(
        description: isSplits
            ? 'Build separate release APKs for each CPU architecture'
            : 'Compile a signed release APK',
        command: isSplits
            ? 'flutter build apk --split-per-abi'
            : 'flutter build apk --release',
        name: isSplits ? 'Build Splits APKs' : 'Build APK',
        id: .buildApk,
      ),
      _collectArtifactStep(
        description: isSplits
            ? 'Copy the split APK files to your Fluship output folder'
            : 'Copy the release APK to your Fluship output folder',
        name: isSplits ? 'Collect Split APKs' : 'Collect APK',
        collector: _artifactCollector.collectApks,
        dependsOn: const {.buildApk},
        command: 'collect: apk',
        artifacts: artifacts,
        id: .collectApk,
        state,
      ),
    ],
  ];
}

List<CommandStep> resolveIos(
  ConfigState state, {
  required PipelineRunArtifacts artifacts,
}) {
  if (!Platform.isMacOS || !state.ios.enabled) return const [];

  final ios = state.ios;
  return [
    if (ios.podClean)
      const CommandStep(
        description: 'Install and update iOS CocoaPods dependencies',
        command: '(cd ios && pod install --repo-update)',
        recoveryCommand:
            '(cd ios && pod deintegrate && pod repo update && sleep 3 && pod install)',
        name: 'Pod Install',
        id: .podInstall,
      ),
    if (ios.buildIpa) ...[
      CommandStep(
        description: 'Compile a signed release IPA for iOS',
        dependsOn: ios.podClean ? const {.podInstall} : const {},
        command: 'flutter build ipa',
        name: 'Build IPA',
        id: .buildIpa,
      ),
      _collectArtifactStep(
        description: 'Copy the release IPA to your Fluship output folder',
        collector: _artifactCollector.collectIpa,
        dependsOn: const {.buildIpa},
        command: 'collect: ipa',
        artifacts: artifacts,
        name: 'Collect IPA',
        id: .collectIpa,
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
        id: .postCommit,
        message: state.resolveCommitMessage(
          fallback: '{version} release',
          state.postGit.commitMessage,
        ),
      ),
    if (state.postGit.postPush)
      GitStepBuilder.push(
        branch: state.gitBranch,
        name: 'Post-Push',
        id: .postPush,
      ),
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
    alwaysRun: kind == .report,
    dependsOn: kind.dependsOn,
    command: kind.command,
    name: kind.command,
    id: kind.id,
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
        id: .openOutputs,
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
        id: .power,
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
    required DateTime notBefore,
    required String sourceRoot,
    required String outputDir,
  })
  collector,
  required PipelineRunArtifacts artifacts,
  required Set<PipelineStepId> dependsOn,
  required String description,
  required PipelineStepId id,
  required String command,
  required String name,
}) {
  return CommandStep(
    description: description,
    dependsOn: dependsOn,
    command: command,
    name: name,
    id: id,
    onExecute: () async {
      final outputDir = pipelineOutputDirectory(
        flushipRoot: state.appInfo.flushipWorkspacePath ?? '',
        projectName: state.appInfo.appName ?? 'unknown',
        buildNumber: state.buildNumber,
        version: state.version,
      );

      artifacts.addAll(
        await collector(
          notBefore: artifacts.startedAt,
          sourceRoot: state.projectRoot,
          outputDir: outputDir,
        ),
      );
    },
  );
}
