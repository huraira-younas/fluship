import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/context_extensions.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/app_layout/navigator_cubit.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/pipeline_bloc.dart';
import 'pipeline_status_style.dart';
import 'pipeline_step_row.dart';
import 'pipeline_elapsed.dart';

class PipelineRunnerPanelBody extends StatelessWidget {
  const PipelineRunnerPanelBody({required this.state, super.key});

  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    final isRunning = state.isRunning;
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final steps = state.steps;
    return AppCard(
      border: .all(color: Colors.transparent),
      title: 'Pipeline',
      radius: .zero,
      description:
          'Track each build step here. Full command output stays in the Console tab.',
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isRunning || steps.isNotEmpty
              ? _PipelineRunStatus(state: state)
              : _PipelineRunActions(state: state),
        ),

        if (steps.isNotEmpty) ...[
          Divider(height: 30, color: colors.consoleBorder),
          Column(
            spacing: ft.spacing.sm,
            children: [
              for (var i = 0; i < steps.length; i++)
                PipelineStepRow(
                  isActive: state.activeStepIndex == i,
                  step: steps[i],
                  index: i,
                ),
            ],
          ),
        ] else
          const _PipelineIdlePlaceholder().center().padOnly(
            t: context.screenHeight * 0.3,
          ),
      ],
    );
  }
}

class _PipelineRunStatus extends StatelessWidget {
  const _PipelineRunStatus({required this.state});
  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final runStatus = state.runStatus;
    final isRunning = state.isRunning;
    final statusColor = runStatus.color(colors);

    return Container(
      padding: .symmetric(horizontal: ft.spacing.md, vertical: ft.spacing.sm),
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.btn),
        border: .all(color: statusColor.withValues(alpha: 0.25)),
        color: statusColor.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: ft.spacing.sm,
        children: [
          Icon(runStatus.icon, size: 20, color: statusColor),
          Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              AppText(
                state.summaryMessage.isEmpty
                    ? runStatus.defaultSummary
                    : state.summaryMessage,
                color: statusColor,
                variant: .custom,
                weight: .w600,
              ),
              if (state.steps.isNotEmpty)
                AppText(
                  state.stepProgressLabel,
                  color: colors.textDim,
                  variant: .custom,
                  size: .caption,
                ),
              if (state.startedAt != null)
                PipelineTotalElapsed(
                  finishedAt: state.finishedAt,
                  startedAt: state.startedAt!,
                  isRunning: isRunning,
                ),
            ],
          ).expanded(),
          if (isRunning)
            AppButton.danger(
              onPressed: () =>
                  context.read<PipelineBloc>().add(const CancelPipeline()),
              label: 'Cancel',
              size: .sm,
            ),
        ],
      ),
    );
  }
}

class _PipelineRunActions extends StatelessWidget {
  const _PipelineRunActions({required this.state});
  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      label: 'Run Pipeline',
      isExpanded: true,
      onPressed: () {
        context.read<PipelineBloc>().add(const RunPipeline());
        context.read<NavigatorCubit>().navigate(.console);
      },
    );
  }
}

class _PipelineIdlePlaceholder extends StatelessWidget {
  const _PipelineIdlePlaceholder();

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    return Column(
      mainAxisAlignment: .center,
      spacing: ft.spacing.md,
      children: [
        Container(
          padding: .all(ft.spacing.lg),
          decoration: BoxDecoration(
            border: .all(color: colors.accent.withValues(alpha: 0.18)),
            color: colors.accent.withValues(alpha: 0.08),
            shape: .circle,
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            color: colors.accent.withValues(alpha: 0.85),
            size: 36,
          ),
        ),
        AppText(
          'Ready when you are',
          color: colors.text,
          variant: .custom,
          weight: .w600,
          size: .body,
        ),
        AppText(
          'Configure your build steps in Config, then run the full pipeline from here.',
          color: colors.textDim,
          textAlign: .center,
          variant: .custom,
          size: .caption,
        ),
      ],
    );
  }
}
