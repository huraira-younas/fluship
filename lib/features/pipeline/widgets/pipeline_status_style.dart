import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/material.dart';

import '../models/pipeline_step_view.dart';
import '../bloc/pipeline_bloc.dart';

extension PipelineRunStatusStyle on PipelineRunStatus {
  Color color(ThemePalette palette) => switch (this) {
    .completed => palette.success,
    .cancelled => palette.warn,
    .running => palette.accent,
    .failed => palette.danger,
    .idle => palette.textDim,
  };

  IconData get icon => switch (this) {
    .completed => Icons.check_circle_rounded,
    .cancelled => Icons.cancel_rounded,
    .failed => Icons.error_rounded,
    .running => Icons.autorenew,
    .idle => Icons.info_outline,
  };

  String get defaultSummary => switch (this) {
    .completed => 'Pipeline completed.',
    .cancelled => 'Pipeline cancelled.',
    .running => 'Running pipeline…',
    .failed => 'Pipeline failed.',
    .idle => '',
  };
}

extension PipelineStepStatusStyle on PipelineStepStatus {
  Color color(ThemePalette palette) => switch (this) {
    .completed => palette.success,
    .pending => palette.textDim,
    .cancelled => palette.warn,
    .running => palette.accent,
    .failed => palette.danger,
    .skipped => palette.muted,
  };

  IconData get icon => switch (this) {
    .skipped => Icons.skip_next_rounded,
    .cancelled => Icons.cancel_rounded,
    .completed => Icons.check_rounded,
    .pending => Icons.circle_outlined,
    .failed => Icons.close_rounded,
    .running => Icons.autorenew,
  };
}

extension PipelineStateProgress on PipelineState {
  PipelineStepView? get activeStep {
    final index = activeStepIndex;
    if (index == null || index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  String get runButtonLabel {
    if (!isRunning) return 'Run Pipeline';
    final step = activeStep;
    if (step == null) return 'Running pipeline';
    return step.upload?.headerLabel ?? 'Running: ${step.name}';
  }

  String get stepProgressLabel {
    final total = steps.length;
    var completed = 0;
    var skipped = 0;
    var cancelled = 0;
    var failed = 0;
    for (final step in steps) {
      switch (step.status) {
        case .completed:
          completed++;
        case .skipped:
          skipped++;
        case .cancelled:
          cancelled++;
        case .failed:
          failed++;
        case .pending || .running:
          break;
      }
    }

    if (isRunning) {
      final current = (activeStepIndex ?? completed) + 1;
      return 'Step $current of $total';
    }

    final parts = <String>[
      if (cancelled > 0) '$cancelled cancelled',
      if (completed > 0) '$completed completed',
      if (skipped > 0) '$skipped skipped',
      if (failed > 0) '$failed failed',
    ];

    if (parts.isEmpty) return '$total steps';
    return '${parts.join(' · ')} of $total';
  }
}
