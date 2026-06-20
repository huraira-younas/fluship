import 'package:equatable/equatable.dart';

enum PipelineRunStatus { idle, running, completed, failed, cancelled }

enum PipelineStepStatus { pending, running, completed, failed, skipped }

class PipelineStepView extends Equatable {
  const PipelineStepView({
    required this.command,
    required this.status,
    required this.name,
    this.errorMessage,
    this.startedAt,
    this.exitCode,
    this.elapsed,
  });

  final PipelineStepStatus status;
  final String? errorMessage;
  final DateTime? startedAt;
  final Duration? elapsed;
  final String command;
  final int? exitCode;
  final String name;

  bool get isTimingActive => status == .running && startedAt != null;

  PipelineStepView copyWith({
    bool clearStartedAt = false,
    PipelineStepStatus? status,
    bool clearElapsed = false,
    String? errorMessage,
    DateTime? startedAt,
    Duration? elapsed,
    String? command,
    int? exitCode,
    String? name,
  }) {
    return PipelineStepView(
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      elapsed: clearElapsed ? null : (elapsed ?? this.elapsed),
      errorMessage: errorMessage ?? this.errorMessage,
      exitCode: exitCode ?? this.exitCode,
      command: command ?? this.command,
      status: status ?? this.status,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
    errorMessage,
    startedAt,
    exitCode,
    command,
    elapsed,
    status,
    name,
  ];
}
