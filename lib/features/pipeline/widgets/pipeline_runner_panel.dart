import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../models/pipeline_step_view.dart';
import '../bloc/pipeline_bloc.dart';

class PipelineRunnerPanel extends StatelessWidget {
  const PipelineRunnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PipelineBloc, PipelineState, PipelineState>(
      selector: (state) => state,
      builder: (context, state) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: .topCenter,
          child: state.isPanelVisible
              ? _PipelineRunnerPanelBody(state: state)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _PipelineRunnerPanelBody extends StatelessWidget {
  const _PipelineRunnerPanelBody({required this.state});
  final PipelineState state;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final bloc = context.read<PipelineBloc>();
    final isRunning = state.isRunning;

    return Container(
      padding: .symmetric(horizontal: ft.spacing.md, vertical: ft.spacing.sm),
      margin: .only(top: ft.spacing.sm),
      decoration: BoxDecoration(
        border: .all(color: colors.consoleBorder),
        borderRadius: .circular(ft.radius.btn),
        color: colors.consoleBg,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: ft.spacing.sm,
        children: [
          Row(
            children: <Widget>[
              AppText(
                state.summaryMessage.isEmpty
                    ? _defaultSummary(state.runStatus)
                    : state.summaryMessage,
                color: _summaryColor(state.runStatus, colors),
                variant: .custom,
                weight: .w600,
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
          if (state.steps.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: .horizontal,
              child: Row(
                spacing: ft.spacing.sm,
                children: [
                  for (var i = 0; i < state.steps.length; i++)
                    _PipelineStepChip(
                      isActive: state.activeStepIndex == i,
                      step: state.steps[i],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _defaultSummary(PipelineRunStatus status) {
    return switch (status) {
      .completed => 'Pipeline completed.',
      .cancelled => 'Pipeline cancelled.',
      .running => 'Running pipeline…',
      .failed => 'Pipeline failed.',
      .idle => '',
    };
  }

  Color _summaryColor(PipelineRunStatus status, ThemePalette colors) {
    return switch (status) {
      .completed => colors.success,
      .cancelled => colors.warn,
      .running => colors.accent,
      .failed => colors.danger,
      .idle => colors.textDim,
    };
  }
}

class _PipelineStepChip extends StatelessWidget {
  const _PipelineStepChip({required this.isActive, required this.step});

  final PipelineStepView step;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    final borderColor = isActive
        ? colors.accent
        : _statusColor(step.status, colors);

    return Tooltip(
      message: step.command,
      child: Container(
        padding: .symmetric(
          horizontal: ft.spacing.sm + 4,
          vertical: ft.spacing.sm,
        ),
        decoration: BoxDecoration(
          border: .all(color: borderColor, width: isActive ? 1.5 : 1),
          color: isActive ? colors.consoleInner : colors.bg,
          borderRadius: .circular(ft.radius.btn),
        ),
        child: Row(
          mainAxisSize: .min,
          spacing: 6,
          children: <Widget>[
            _PipelineStepIcon(status: step.status, isActive: isActive),
            AppText(
              weight: isActive ? .w600 : .w500,
              color: colors.text,
              variant: .custom,
              size: .caption,
              step.name,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PipelineStepStatus status, ThemePalette colors) {
    return switch (status) {
      .completed => colors.success.withValues(alpha: 0.6),
      .running => colors.accent.withValues(alpha: 0.6),
      .failed => colors.danger.withValues(alpha: 0.6),
      .skipped => colors.muted.withValues(alpha: 0.5),
      .pending => colors.consoleBorder,
    };
  }
}

class _PipelineStepIcon extends StatelessWidget {
  const _PipelineStepIcon({required this.status, required this.isActive});

  final PipelineStepStatus status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    if (status == .running || isActive) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
      );
    }

    final icon = switch (status) {
      .completed => Icons.check_circle_outline,
      .pending => Icons.circle_outlined,
      .failed => Icons.error_outline,
      .skipped => Icons.skip_next,
      .running => Icons.autorenew,
    };

    final color = switch (status) {
      .completed => colors.success,
      .pending => colors.textDim,
      .skipped => colors.muted,
      .running => colors.accent,
      .failed => colors.danger,
    };

    return Icon(icon, size: 14, color: color);
  }
}
