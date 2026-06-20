import 'dart:async' show Timer;

import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../utils/pipeline_duration_format.dart';
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
      padding: .symmetric(horizontal: ft.spacing.md, vertical: ft.spacing.md),
      margin: .only(top: ft.spacing.sm),
      decoration: BoxDecoration(
        border: .all(color: colors.consoleBorder),
        borderRadius: .circular(ft.radius.btn),
        color: colors.consoleBg,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: ft.spacing.md,
        children: [
          Row(
            crossAxisAlignment: .start,
            spacing: ft.spacing.sm,
            children: [
              _PipelineStatusIcon(runStatus: state.runStatus),
              Column(
                crossAxisAlignment: .stretch,
                spacing: 4,
                children: [
                  AppText(
                    state.summaryMessage.isEmpty
                        ? _defaultSummary(state.runStatus)
                        : state.summaryMessage,
                    color: _summaryColor(state.runStatus, colors),
                    variant: .custom,
                    weight: .w600,
                  ),
                  if (state.steps.isNotEmpty)
                    AppText(
                      _stepProgressLabel(state),
                      color: colors.textDim,
                      variant: .custom,
                      size: .caption,
                    ),
                  if (state.startedAt != null)
                    _PipelineTotalElapsed(
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
            Divider(height: 1, color: colors.consoleBorder),
            Column(
              spacing: ft.spacing.sm,
              children: [
                for (var i = 0; i < state.steps.length; i++)
                  _PipelineStepRow(
                    isActive: state.activeStepIndex == i,
                    step: state.steps[i],
                    index: i,
                  ),
              ],
            ),
          ],
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

  String _stepProgressLabel(PipelineState state) {
    final total = state.steps.length;
    if (state.isRunning) {
      final done = state.steps
          .where((step) => step.status == .completed)
          .length;
      final current = (state.activeStepIndex ?? done) + 1;
      return 'Step $current of $total';
    }

    final completed = state.steps
        .where((step) => step.status == .completed)
        .length;
    return '$completed of $total steps completed';
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

class _PipelineStatusIcon extends StatelessWidget {
  const _PipelineStatusIcon({required this.runStatus});

  final PipelineRunStatus runStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    if (runStatus == PipelineRunStatus.running) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
      );
    }

    final icon = switch (runStatus) {
      .completed => Icons.check_circle_rounded,
      .cancelled => Icons.cancel_rounded,
      .failed => Icons.error_rounded,
      .running => Icons.autorenew,
      .idle => Icons.info_outline,
    };

    final color = switch (runStatus) {
      .completed => colors.success,
      .cancelled => colors.warn,
      .running => colors.accent,
      .failed => colors.danger,
      .idle => colors.textDim,
    };

    return Icon(icon, size: 20, color: color);
  }
}

class _PipelineTotalElapsed extends StatefulWidget {
  const _PipelineTotalElapsed({
    required this.startedAt,
    required this.isRunning,
    this.finishedAt,
  });

  final DateTime? finishedAt;
  final DateTime startedAt;
  final bool isRunning;

  @override
  State<_PipelineTotalElapsed> createState() => _PipelineTotalElapsedState();
}

class _PipelineTotalElapsedState extends State<_PipelineTotalElapsed> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _PipelineTotalElapsed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!widget.isRunning) {
      _timer = null;
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isRunning ? 'Elapsed' : 'Total time';
    final end = widget.finishedAt ?? DateTime.now();
    final elapsed = end.difference(widget.startedAt);

    return AppText(
      '$label: ${formatPipelineDuration(elapsed)}',
      color: context.flushipTheme.colors.textDim,
      variant: .custom,
      size: .caption,
    );
  }
}

class _PipelineStepRow extends StatelessWidget {
  const _PipelineStepRow({
    required this.isActive,
    required this.index,
    required this.step,
  });

  final PipelineStepView step;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;
    final isRunning = step.status == .running;

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
          _StepIndexBadge(index: index + 1, status: step.status),
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
          _StepElapsedBadge(step: step),
          _PipelineStepIcon(status: step.status, isActive: isActive),
        ],
      ),
    );
  }
}

class _StepIndexBadge extends StatelessWidget {
  const _StepIndexBadge({required this.index, required this.status});

  final PipelineStepStatus status;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;
    final color = switch (status) {
      .completed => colors.success,
      .pending => colors.textDim,
      .running => colors.accent,
      .failed => colors.danger,
      .skipped => colors.muted,
    };

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

class _StepElapsedBadge extends StatefulWidget {
  const _StepElapsedBadge({required this.step});

  final PipelineStepView step;

  @override
  State<_StepElapsedBadge> createState() => _StepElapsedBadgeState();
}

class _StepElapsedBadgeState extends State<_StepElapsedBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _StepElapsedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.isTimingActive != widget.step.isTimingActive ||
        oldWidget.step.elapsed != widget.step.elapsed) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!widget.step.isTimingActive) {
      _timer = null;
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

    final text = elapsed == null ? '…' : formatPipelineDuration(elapsed);
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

class _PipelineStepIcon extends StatelessWidget {
  const _PipelineStepIcon({required this.status, required this.isActive});

  final PipelineStepStatus status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    if (status == .running || isActive) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
      );
    }

    final icon = switch (status) {
      .skipped => Icons.skip_next_rounded,
      .completed => Icons.check_rounded,
      .pending => Icons.circle_outlined,
      .failed => Icons.close_rounded,
      .running => Icons.autorenew,
    };

    final color = switch (status) {
      .completed => colors.success,
      .pending => colors.textDim,
      .skipped => colors.muted,
      .running => colors.accent,
      .failed => colors.danger,
    };

    return Icon(icon, size: 16, color: color);
  }
}
