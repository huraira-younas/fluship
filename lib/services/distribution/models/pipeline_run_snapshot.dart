import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:equatable/equatable.dart';

class PipelineRunSnapshot extends Equatable {
  const PipelineRunSnapshot({
    this.collectedArtifacts = const [],
    required this.totalElapsed,
    required this.artifactsDir,
    required this.buildNumber,
    required this.logFilePath,
    required this.finishedAt,
    required this.platforms,
    required this.runStatus,
    required this.startedAt,
    required this.appName,
    required this.version,
    required this.steps,
  });

  /// Artifacts collected by this run only. Distribution uses these instead of
  /// listing [artifactsDir], which also holds output from earlier runs of the
  /// same version and build number.
  final List<String> collectedArtifacts;

  final List<PipelineStepView> steps;
  final PipelineRunStatus runStatus;
  final Duration totalElapsed;
  final String artifactsDir;
  final DateTime finishedAt;
  final DateTime startedAt;
  final String buildNumber;
  final String logFilePath;
  final String platforms;
  final String appName;
  final String version;

  bool get success => runStatus == .completed;

  String? artifactWithExtension(String extension) {
    final matches = [
      for (final path in collectedArtifacts)
        if (path.endsWith(extension)) path,
    ]..sort();

    return matches.isEmpty ? null : matches.first;
  }

  @override
  List<Object?> get props => [
    collectedArtifacts,
    totalElapsed,
    artifactsDir,
    logFilePath,
    buildNumber,
    finishedAt,
    platforms,
    runStatus,
    startedAt,
    appName,
    version,
    steps,
  ];
}
