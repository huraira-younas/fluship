import 'dart:io' show Platform;

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';

import '../artifacts/artifact_collector.dart';
import '../paths/fluship_workspace_paths.dart';
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
      _collectAabStep(state),
    ],
    if (android.buildType != null)
      ...switch (android.buildType) {
        .apk => [
          const CommandStep(
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectApksStep(state, name: 'Collect APK'),
        ],
        .arbs => [
          const CommandStep(
            command: 'flutter build apk --split-per-abi',
            name: 'Build AAR',
          ),
          _collectApksStep(state, name: 'Collect Split APKs'),
        ],
        _ => [
          const CommandStep(
            command: 'flutter build apk --release',
            name: 'Build APK',
          ),
          _collectApksStep(state, name: 'Collect APK'),
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
      _collectIpaStep(state),
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

List<CommandStep> resolveDistribution(ConfigState state) {
  // Phase 2+: Google Drive + drive link email via DistributionService handlers
  // wired as CommandStep.onExecute once upload steps need mid-pipeline execution.
  return const [];
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

Future<String> _resolveOutputDirectory(ConfigState state) async {
  final flushipRoot = await _workspacePaths.resolveRoot();

  return pipelineOutputDirectory(
    projectName: state.appInfo.appName ?? 'unknown',
    buildNumber: state.buildNumber,
    flushipRoot: flushipRoot,
    version: state.version,
  );
}

CommandStep _collectApksStep(ConfigState state, {required String name}) {
  return CommandStep(
    command: 'collect: apk',
    name: name,
    onExecute: () async {
      final outputDir = await _resolveOutputDirectory(state);
      await _artifactCollector.collectApks(
        sourceRoot: state.projectRoot,
        outputDir: outputDir,
      );
    },
  );
}

CommandStep _collectAabStep(ConfigState state) {
  return CommandStep(
    name: 'Collect App Bundle',
    command: 'collect: aab',
    onExecute: () async {
      final outputDir = await _resolveOutputDirectory(state);
      await _artifactCollector.collectAab(
        sourceRoot: state.projectRoot,
        outputDir: outputDir,
      );
    },
  );
}

CommandStep _collectIpaStep(ConfigState state) {
  return CommandStep(
    command: 'collect: ipa',
    name: 'Collect IPA',
    onExecute: () async {
      final outputDir = await _resolveOutputDirectory(state);
      await _artifactCollector.collectIpa(
        sourceRoot: state.projectRoot,
        outputDir: outputDir,
      );
    },
  );
}
