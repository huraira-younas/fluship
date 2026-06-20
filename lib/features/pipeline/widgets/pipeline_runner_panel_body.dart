import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/pipeline_bloc.dart';
import 'pipeline_progress_icon.dart';
import 'pipeline_status_style.dart';
import 'pipeline_step_row.dart';
import 'pipeline_elapsed.dart';

class PipelineRunnerPanelBody extends StatelessWidget {
  const PipelineRunnerPanelBody({required this.state, super.key});

  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PipelineBloc>();
    final isRunning = state.isRunning;
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final runStatus = state.runStatus;
    final statusColor = runStatus.color(colors);

    return AppCard(
      title: 'Pipeline',
      description:
          'Live progress for your configured build steps. '
          'Each step shows its status and duration here; full command output is logged in the Console tab.',
      children: [
        Row(
          crossAxisAlignment: .start,
          spacing: ft.spacing.sm,
          children: [
            PipelineProgressIcon(
              showSpinner: runStatus == .running,
              icon: runStatus.icon,
              color: statusColor,
            ),
            Column(
              crossAxisAlignment: .stretch,
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
                onPressed: () => bloc.add(const CancelPipeline()),
                label: 'Cancel',
                size: .sm,
              )
            else
              AppButton.ghost(
                onPressed: () => bloc.add(const DismissPipelinePanel()),
                label: 'Dismiss',
                size: .sm,
              ),
          ],
        ),
        if (state.steps.isNotEmpty) ...[
          Divider(height: 30, color: colors.consoleBorder),
          Column(
            spacing: ft.spacing.sm,
            children: [
              for (var i = 0; i < state.steps.length; i++)
                PipelineStepRow(
                  isActive: state.activeStepIndex == i,
                  step: state.steps[i],
                  index: i,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
