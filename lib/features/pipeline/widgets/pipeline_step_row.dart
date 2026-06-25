import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/services/pipeline/utils/pipeline_utils.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../models/pipeline_step_view.dart';
import 'pipeline_status_style.dart';
import 'pipeline_elapsed.dart';

class PipelineStepRow extends StatelessWidget {
  const PipelineStepRow({
    required this.isActive,
    required this.index,
    required this.step,
    super.key,
  });

  final PipelineStepView step;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final isRunning = step.status == .running;
    final isSkipped = step.status == .skipped;
    final isFailed = step.status == .failed;
    final statusColor = step.status.color(colors);

    final background = switch (step.status) {
      .running || .pending when isActive => colors.consoleInner,
      .failed => colors.danger.withValues(alpha: 0.06),
      .skipped => colors.muted.withValues(alpha: 0.04),
      _ => Colors.transparent,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: .symmetric(horizontal: ft.spacing.sm, vertical: ft.spacing.sm),
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.btn),
        border: .all(
          color: isActive
              ? colors.accent.withValues(alpha: 0.45)
              : isFailed
              ? colors.danger.withValues(alpha: 0.35)
              : colors.consoleBorder.withValues(alpha: 0.45),
        ),
        color: background,
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: ft.spacing.sm,
        children: [
          _StepIndexBadge(color: statusColor, index: index + 1),
          Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              AppText(
                weight: isActive || isRunning ? .w600 : .w500,
                color: isSkipped ? colors.textDim : colors.text,
                variant: .custom,
                size: .body,
                step.name,
              ),
              AppText(
                isSkipped
                    ? 'Skipped — not run in this pipeline'
                    : step.description,
                color: colors.textDim,
                overflow: .ellipsis,
                variant: .custom,
                size: .caption,
                maxLines: 2,
              ),
              if (isFailed)
                Row(
                  crossAxisAlignment: .start,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.danger,
                      size: 14,
                    ),
                    AppText(
                      PipelineUtils.formatStepError(step.errorMessage),
                      color: colors.danger,
                      variant: .custom,
                      size: .caption,
                      maxLines: 3,
                    ).expanded(),
                  ],
                ),
            ],
          ).expanded(),
          Column(
            crossAxisAlignment: .end,
            spacing: 6,
            children: [
              PipelineStepElapsedBadge(step: step),
              if (isRunning || isActive)
                SizedBox(
                  width: 60,
                  height: 10,
                  child: LinearProgressIndicator(
                    backgroundColor: colors.bg.withValues(alpha: 0.65),
                    borderRadius: .circular(10),
                    color: statusColor,
                  ),
                )
              else
                Icon(step.status.icon, size: 18, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndexBadge extends StatelessWidget {
  const _StepIndexBadge({required this.color, required this.index});

  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      alignment: .center,
      decoration: BoxDecoration(
        border: .all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.12),
        shape: .circle,
      ),
      child: AppText(
        variant: .custom,
        size: .caption,
        weight: .w600,
        color: color,
        '$index',
      ),
    );
  }
}
