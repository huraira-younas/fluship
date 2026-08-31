import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';

class PipelineLogCopy {
  const PipelineLogCopy._();

  static String started({
    required String version,
    required String build,
    required String app,
  }) => 'Pipeline started for $app v$version+$build';

  static String stepStarting(String name) => '$name: starting';

  static String stepFinished(String name, String duration) =>
      '$name finished in $duration';

  static String stepFailed(String name, String duration, String? error) {
    final detail = (error ?? '').trim();
    if (detail.isEmpty) return '$name failed in $duration';
    return '$name failed in $duration. $detail';
  }

  static String stepCancelled(String name, String duration) =>
      '$name cancelled after $duration';

  static String stepRemoved(String name) => '$name removed from this run';

  static String stepRetry(String name) =>
      '$name failed, retrying with recovery';

  static String ended(PipelineRunStatus status, String duration) =>
      switch (status) {
        .failed => 'Pipeline finished with failed steps in $duration',
        .cancelled => 'Pipeline cancelled after $duration',
        .running || .idle => 'Pipeline ended in $duration',
        .completed => 'Pipeline completed in $duration',
      };

  static String logSaved(String path) => 'Log saved to $path';
}
