import 'package:equatable/equatable.dart';

import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';

class PipelineRunSnapshot extends Equatable {
  const PipelineRunSnapshot({
    required this.steps,
    required this.runStatus,
    required this.startedAt,
    required this.finishedAt,
    required this.platforms,
    required this.buildNumber,
    required this.totalElapsed,
    required this.logFilePath,
    required this.appName,
    required this.version,
  });

  final List<PipelineStepView> steps;
  final PipelineRunStatus runStatus;
  final Duration totalElapsed;
  final DateTime finishedAt;
  final DateTime startedAt;
  final String buildNumber;
  final String logFilePath;
  final String platforms;
  final String appName;
  final String version;

  bool get success => runStatus == PipelineRunStatus.completed;

  @override
  List<Object?> get props => [
    runStatus,
    totalElapsed,
    logFilePath,
    buildNumber,
    finishedAt,
    platforms,
    startedAt,
    appName,
    version,
    steps,
  ];
}
