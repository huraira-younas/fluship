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
    .running => palette.accent,
    .failed => palette.danger,
    .skipped => palette.muted,
  };

  IconData get icon => switch (this) {
    .skipped => Icons.skip_next_rounded,
    .completed => Icons.check_rounded,
    .pending => Icons.circle_outlined,
    .failed => Icons.close_rounded,
    .running => Icons.autorenew,
  };
}

extension PipelineStateProgress on PipelineState {
  String get stepProgressLabel {
    final total = steps.length;
    if (isRunning) {
      final done = steps.where((step) => step.status == .completed).length;
      final current = (activeStepIndex ?? done) + 1;
      return 'Step $current of $total';
    }

    final completed = steps.where((step) => step.status == .completed).length;
    return '$completed of $total steps completed';
  }
}
