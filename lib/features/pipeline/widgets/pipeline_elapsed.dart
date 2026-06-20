import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../models/pipeline_step_view.dart';
import 'pipeline_live_timer_mixin.dart';

class PipelineTotalElapsed extends StatefulWidget {
  const PipelineTotalElapsed({
    required this.startedAt,
    required this.isRunning,
    this.finishedAt,
    super.key,
  });

  final DateTime? finishedAt;
  final DateTime startedAt;
  final bool isRunning;

  @override
  State<PipelineTotalElapsed> createState() => _PipelineTotalElapsedState();
}

class _PipelineTotalElapsedState extends State<PipelineTotalElapsed>
    with PipelineLiveTimerMixin {
  @override
  void initState() {
    super.initState();
    syncLiveTimer(isActive: widget.isRunning);
  }

  @override
  void didUpdateWidget(covariant PipelineTotalElapsed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      syncLiveTimer(isActive: widget.isRunning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isRunning ? 'Elapsed' : 'Total time';
    final end = widget.finishedAt ?? DateTime.now();
    final elapsed = end.difference(widget.startedAt);

    return AppText(
      '$label: ${PipelineUtils.formatPipelineDuration(elapsed)}',
      color: context.flushipTheme.colors.textDim,
      variant: .custom,
      size: .caption,
    );
  }
}

class PipelineStepElapsedBadge extends StatefulWidget {
  const PipelineStepElapsedBadge({required this.step, super.key});
  final PipelineStepView step;

  @override
  State<PipelineStepElapsedBadge> createState() =>
      _PipelineStepElapsedBadgeState();
}

class _PipelineStepElapsedBadgeState extends State<PipelineStepElapsedBadge>
    with PipelineLiveTimerMixin {
  @override
  void initState() {
    super.initState();
    syncLiveTimer(isActive: widget.step.isTimingActive);
  }

  @override
  void didUpdateWidget(covariant PipelineStepElapsedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.isTimingActive != widget.step.isTimingActive ||
        oldWidget.step.elapsed != widget.step.elapsed) {
      syncLiveTimer(isActive: widget.step.isTimingActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;
    final step = widget.step;
    final elapsed =
        step.elapsed ??
        (step.startedAt != null
            ? DateTime.now().difference(step.startedAt!)
            : null);

    if (elapsed == null &&
        step.status != .completed &&
        step.status != .running &&
        step.status != .failed) {
      return AppText(
        color: colors.muted,
        variant: .custom,
        size: .caption,
        '—',
      );
    }

    final text = elapsed == null
        ? '…'
        : PipelineUtils.formatPipelineDuration(elapsed);
    final color = step.status == .running ? colors.accent : colors.textDim;

    return Container(
      padding: const .symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: .circular(999),
        color: colors.bg.withValues(alpha: 0.65),
      ),
      child: AppText(
        weight: step.isTimingActive ? .w600 : .w500,
        variant: .custom,
        size: .caption,
        color: color,
        text,
      ),
    );
  }
}
