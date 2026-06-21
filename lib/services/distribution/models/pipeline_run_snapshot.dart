import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:equatable/equatable.dart';

class PipelineRunSnapshot extends Equatable {
  const PipelineRunSnapshot({
    required this.totalElapsed,
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

  bool get success => runStatus == .completed;

  @override
  List<Object?> get props => [
    totalElapsed,
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
