import 'package:fluship/services/pipeline/pipeline.dart' show CommandStep;

class const PipelineStepResult({
  final bool wasCancelled = false,
  final String errorMessage = '',
  required final bool success,
  final int? exitCode,
});

class const PipelineExecutor() {
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
