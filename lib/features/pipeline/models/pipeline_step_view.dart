import 'package:equatable/equatable.dart';

enum PipelineRunStatus { idle, running, completed, failed, cancelled }

enum PipelineStepStatus { pending, running, completed, failed, skipped }

class PipelineStepView extends Equatable {
  const PipelineStepView({
    required this.command,
    required this.status,
    required this.name,
    this.errorMessage,
    this.exitCode,
  });

  final PipelineStepStatus status;
  final String? errorMessage;
  final String command;
  final int? exitCode;
  final String name;

  PipelineStepView copyWith({
    PipelineStepStatus? status,
    String? errorMessage,
    String? command,
    int? exitCode,
    String? name,
  }) {
    return PipelineStepView(
      errorMessage: errorMessage ?? this.errorMessage,
      exitCode: exitCode ?? this.exitCode,
      command: command ?? this.command,
      status: status ?? this.status,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, command, exitCode, name];
}
