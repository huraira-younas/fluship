import 'package:fluship/services/distribution/upload/pipeline_upload_progress.dart';
import 'package:equatable/equatable.dart';

enum PipelineRunStatus { idle, running, completed, failed, cancelled }

enum PipelineStepStatus {
  completed,
  cancelled,
  pending,
  running,
  skipped,
  failed,
}

class const PipelineStepView({
  required final String description,
  required final PipelineStepStatus status,
  required final String name,
  final String? errorMessage,
  final DateTime? startedAt,
  final Duration? elapsed,
  final PipelineUploadProgress? upload,
}) extends Equatable {
  bool get isTimingActive => status == .running && startedAt != null;

  PipelineStepView copyWith({
    PipelineUploadProgress? upload,
    bool clearStartedAt = false,
    PipelineStepStatus? status,
    bool clearElapsed = false,
    bool clearUpload = false,
    String? errorMessage,
    DateTime? startedAt,
    Duration? elapsed,
    String? name,
  }) {
    return PipelineStepView(
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      elapsed: clearElapsed ? null : (elapsed ?? this.elapsed),
      upload: clearUpload ? null : (upload ?? this.upload),
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
    upload,
    status,
    name,
  ];
}
