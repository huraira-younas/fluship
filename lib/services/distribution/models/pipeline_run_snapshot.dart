import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:equatable/equatable.dart';

class const PipelineRunSnapshot({
  /// Artifacts collected by this run only. Distribution uses these instead of
  /// listing [artifactsDir], which also holds output from earlier runs of the
  /// same version and build number.
  final List<String> collectedArtifacts = const [],
  required final Duration totalElapsed,

  /// Download links published earlier in this run, by label.
  final Map<String, String> links = const {},
  required final String artifactsDir,
  required final String buildNumber,
  required final String logFilePath,
  required final DateTime finishedAt,
  required final String platforms,
  required final PipelineRunStatus runStatus,
  required final DateTime startedAt,
  required final String appName,
  required final String version,
  required final List<PipelineStepView> steps,
}) extends Equatable {
  bool get success => runStatus == .completed;

  List<String> artifactsWithExtension(String extension) => [
    for (final path in collectedArtifacts)
      if (path.endsWith(extension)) path,
  ]..sort();

  String? artifactWithExtension(String extension) =>
      artifactsWithExtension(extension).firstOrNull;

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
    links,
  ];
}
