import 'package:equatable/equatable.dart';

import 'pipeline_step_id.dart';

final class const CommandStep({
  required final String description,
  required final String command,
  required final String name,

  /// Steps this one needs. When any of them fails or is removed, this step is
  /// skipped instead of running against stale output.
  final Set<PipelineStepId> dependsOn = const {},

  /// Whether a failure here aborts the whole run instead of cascading.
  final bool isCritical = false,

  /// Whether the step still runs after an aborting failure. Used by the build
  /// report so a failed run is still reported.
  final bool alwaysRun = false,

  /// Command retried once when [command] fails, before the step is failed.
  final String? recoveryCommand,
  final Future<void> Function()? onExecute,
  final PipelineStepId? id,
}) extends Equatable {
  bool get isInternal => onExecute != null;

  @override
  List<Object?> get props => [description, name, command];
}
