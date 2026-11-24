part of 'pipeline_bloc.dart';

class const PipelineState({
  required final int? activeStepIndex,
  required final String summaryMessage,
  required final PipelineRunStatus runStatus,
  super.loading = false,
  required final List<PipelineStepView> steps,
  final DateTime? finishedAt,
  final DateTime? startedAt,
  super.error,
}) extends BaseBlocState {
  factory idle() => const PipelineState(
    summaryMessage: 'Pipeline is ready to run.',
    activeStepIndex: null,
    runStatus: .idle,
    steps: [],
  );

  bool get isPanelVisible => runStatus != .idle;
  bool get isRunning => runStatus == .running;

  @override
  List<Object?> get props => [
    activeStepIndex,
    summaryMessage,
    finishedAt,
    startedAt,
    runStatus,
    loading,
    steps,
    error,
  ];

  @override
  PipelineState copyWith({
    bool clearActiveStepIndex = false,
    List<PipelineStepView>? steps,
    PipelineRunStatus? runStatus,
    bool clearFinishedAt = false,
    bool clearStartedAt = false,
    String? summaryMessage,
    int? activeStepIndex,
    DateTime? finishedAt,
    DateTime? startedAt,
    CustomState? error,
    bool? loading,
  }) {
    return PipelineState(
      activeStepIndex: clearActiveStepIndex
          ? null
          : (activeStepIndex ?? this.activeStepIndex),
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      summaryMessage: summaryMessage ?? this.summaryMessage,
      runStatus: runStatus ?? this.runStatus,
      loading: loading ?? this.loading,
      steps: steps ?? this.steps,
      error: error,
    );
  }
}
