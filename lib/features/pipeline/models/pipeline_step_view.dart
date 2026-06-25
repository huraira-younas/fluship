import 'package:equatable/equatable.dart';

enum PipelineRunStatus { idle, running, completed, failed, cancelled }

enum PipelineStepStatus { pending, running, completed, failed, skipped }

class PipelineStepView extends Equatable {
  const PipelineStepView({
    required this.description,
    required this.status,
    required this.name,
    this.errorMessage,
    this.startedAt,
    this.elapsed,
  });

  final PipelineStepStatus status;
  final String? errorMessage;
  final DateTime? startedAt;
  final String description;
  final Duration? elapsed;
  final String name;

  bool get isTimingActive => status == .running && startedAt != null;

  PipelineStepView copyWith({
    bool clearStartedAt = false,
    PipelineStepStatus? status,
    bool clearElapsed = false,
    String? errorMessage,
    DateTime? startedAt,
    Duration? elapsed,
    String? name,
  }) {
    return PipelineStepView(
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      elapsed: clearElapsed ? null : (elapsed ?? this.elapsed),
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      description: description,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
    errorMessage,
    description,
    startedAt,
    elapsed,
    status,
    name,
  ];
}
