import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import '../models/pipeline_step_view.dart';
import 'pipeline_progress_icon.dart';
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
    final statusColor = step.status.color(colors);

    final background = isActive || isRunning
        ? colors.consoleInner
        : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: .symmetric(horizontal: ft.spacing.sm, vertical: ft.spacing.sm),
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.btn),
        border: isActive
            ? .all(color: colors.accent.withValues(alpha: 0.45))
            : null,
        color: background,
      ),
      child: Row(
        spacing: ft.spacing.sm,
        children: [
          _StepIndexBadge(color: statusColor, index: index + 1),
          Column(
            crossAxisAlignment: .stretch,
            spacing: 2,
            children: [
              AppText(
                step.name,
                weight: isActive ? .w600 : .w500,
                color: colors.text,
                variant: .custom,
                size: .caption,
              ),
              if (step.command.isNotEmpty)
                AppText(
                  color: colors.textDim,
                  overflow: .ellipsis,
                  variant: .custom,
                  size: .caption,
                  step.command,
                  maxLines: 1,
                ),
            ],
          ).expanded(),
          PipelineStepElapsedBadge(step: step),
          PipelineProgressIcon(
            showSpinner: isRunning || isActive,
            color: statusColor,
            icon: step.status.icon,
            size: 16,
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
      width: 22,
      height: 22,
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
