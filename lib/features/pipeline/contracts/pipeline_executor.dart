import 'package:fluship/shared/pipeline/command_step.dart';

class PipelineStepResult {
  const PipelineStepResult({
    this.wasCancelled = false,
    this.errorMessage = '',
    required this.success,
    this.exitCode,
  });

  final String errorMessage;
  final bool wasCancelled;
  final int? exitCode;
  final bool success;
}

class PipelineExecutor {
  const PipelineExecutor();

  Future<PipelineStepResult> executeInternal(CommandStep step) async {
    final execute = step.onExecute;
    if (execute == null) {
      return const PipelineStepResult(
        errorMessage: 'Internal step has no handler.',
        success: false,
      );
    }

    try {
      await execute();
      return const PipelineStepResult(success: true);
    } catch (error) {
      return PipelineStepResult(success: false, errorMessage: error.toString());
    }
  }
}
