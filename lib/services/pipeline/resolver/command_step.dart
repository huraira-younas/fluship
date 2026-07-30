import 'package:equatable/equatable.dart';

import 'pipeline_step_id.dart';

final class CommandStep extends Equatable {
  const CommandStep({
    required this.description,
    required this.command,
    required this.name,
    this.dependsOn = const {},
    this.isCritical = false,
    this.alwaysRun = false,
    this.recoveryCommand,
    this.onExecute,
    this.id,
  });

  final Future<void> Function()? onExecute;

  /// Command retried once when [command] fails, before the step is failed.
  final String? recoveryCommand;

  /// Steps this one needs. When any of them fails or is removed, this step is
  /// skipped instead of running against stale output.
  final Set<PipelineStepId> dependsOn;

  /// Whether a failure here aborts the whole run instead of cascading.
  final bool isCritical;

  /// Whether the step still runs after an aborting failure. Used by the build
  /// report so a failed run is still reported.
  final bool alwaysRun;

  final PipelineStepId? id;
  final String description;
  final String command;
  final String name;

  bool get isInternal => onExecute != null;

  @override
  List<Object?> get props => [description, name, command];
}
