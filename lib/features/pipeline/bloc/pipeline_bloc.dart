import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/shared/pipeline/config_pipeline_resolver.dart';
import 'package:fluship/shared/pipeline/config_state_context.dart';
import 'package:fluship/shared/pipeline/command_step.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/pipeline_config_source.dart';
import '../contracts/pipeline_console_port.dart';
import '../utils/pipeline_duration_format.dart';
import '../contracts/pipeline_executor.dart';
import '../models/pipeline_step_view.dart';

part 'pipeline_event.dart';
part 'pipeline_state.dart';

class PipelineBloc extends BaseBloc<PipelineEvent, PipelineState> {
  PipelineBloc({
    required this._configSource,
    required this._consolePort,
    PipelineExecutor? executor,
  }) : _executor = executor ?? const PipelineExecutor(),
       super(PipelineState.idle()) {
    on<DismissPipelinePanel>(handler(_onDismissPipelinePanel));
    on<CancelPipeline>(handler(_onCancelPipeline));
    on<RunPipeline>(handler(_onRunPipeline));
  }

  final PipelineConfigSource _configSource;
  final PipelineConsolePort _consolePort;
  final PipelineExecutor _executor;

  var _cancelRequested = false;
  String? _sessionId;

  @override
  Future<void> close() async {
    _cancelRequested = true;
    await _closeConsoleSession();
    return super.close();
  }

  Future<void> _onRunPipeline(
    Emitter<PipelineState> emit,
    RunPipeline event,
  ) async {
    if (state.isRunning) return;

    _cancelRequested = false;

    await _configSource.persistCurrentConfig();

    final configState = _configSource.state;
    final projectRoot = configState.projectRoot.trim();

    if (projectRoot.isEmpty) {
      emit(
        PipelineState(
          summaryMessage: 'Set Flutter project path in Settings first.',
          finishedAt: DateTime.now(),
          startedAt: DateTime.now(),
          activeStepIndex: null,
          runStatus: .failed,
          steps: const [],
        ),
      );
      return;
    }

    final commandSteps = ConfigPipelineResolver.resolve(configState);
    if (commandSteps.isEmpty) {
      emit(
        PipelineState(
          summaryMessage:
              'No pipeline steps configured. Enable sections in Config.',
          activeStepIndex: null,
          finishedAt: DateTime.now(),
          startedAt: DateTime.now(),
          runStatus: .failed,
          steps: const [],
        ),
      );
      return;
    }

    final startedAt = DateTime.now();
    final stepViews = commandSteps
        .map(
          (step) => PipelineStepView(
            command: step.command,
            status: .pending,
            name: step.name,
          ),
        )
        .toList();

    emit(
      PipelineState(
        summaryMessage: 'Running pipeline…',
        activeStepIndex: null,
        startedAt: startedAt,
        runStatus: .running,
        steps: stepViews,
      ),
    );

    _sessionId = await _consolePort.createSession(projectRoot: projectRoot);
    await _consolePort.logLine(
      text: '[pipeline started]',
      sessionId: _sessionId!,
      stream: .system,
    );

    var runStatus = PipelineRunStatus.completed;
    var summaryMessage = 'Pipeline completed successfully.';
    String? failureMessage;

    for (var index = 0; index < commandSteps.length; index++) {
      if (_cancelRequested || isClosed) {
        runStatus = PipelineRunStatus.cancelled;
        summaryMessage = 'Pipeline cancelled.';
        _markRemainingSkipped(stepViews, index);
        break;
      }

      final step = commandSteps[index];
      _emitStepRunning(emit, index: index, steps: stepViews);

      final result = step.isInternal
          ? await _runInternalStep(step)
          : await _runShellStep(step);

      if (_cancelRequested || result.wasCancelled) {
        stepViews[index] = _finalizeStepTiming(stepViews[index]).copyWith(
          status: PipelineStepStatus.failed,
          errorMessage: 'Cancelled',
        );
        await _logStepTiming(
          errorMessage: 'Cancelled',
          view: stepViews[index],
          stepName: step.name,
          success: false,
        );
        runStatus = PipelineRunStatus.cancelled;
        summaryMessage = 'Pipeline cancelled.';

        _markRemainingSkipped(stepViews, index + 1);
        _emitSteps(emit, steps: stepViews, activeStepIndex: null);
        break;
      }

      if (!result.success) {
        stepViews[index] = _finalizeStepTiming(stepViews[index]).copyWith(
          status: PipelineStepStatus.failed,
          errorMessage: result.errorMessage,
          exitCode: result.exitCode,
        );
        await _logStepTiming(
          errorMessage: result.errorMessage,
          view: stepViews[index],
          stepName: step.name,
          success: false,
        );
        summaryMessage = '${step.name} failed.';
        runStatus = PipelineRunStatus.failed;
        failureMessage = result.errorMessage;

        _markRemainingSkipped(stepViews, index + 1);
        _emitSteps(emit, steps: stepViews, activeStepIndex: null);
        break;
      }

      stepViews[index] = _finalizeStepTiming(stepViews[index]).copyWith(
        status: PipelineStepStatus.completed,
        exitCode: result.exitCode,
      );
      await _logStepTiming(
        view: stepViews[index],
        stepName: step.name,
        success: true,
      );

      _emitSteps(emit, steps: stepViews, activeStepIndex: null);
    }

    final finishedAt = DateTime.now();
    final totalElapsed = finishedAt.difference(startedAt);
    final totalFormatted = formatPipelineDuration(totalElapsed);

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: '[pipeline ${runStatus.name} in $totalFormatted]',
        sessionId: sessionId,
        stream: .system,
      );
    }

    if (isClosed) return;

    summaryMessage = _summaryWithTotal(
      totalFormatted: totalFormatted,
      fallback: summaryMessage,
      runStatus: runStatus,
    );

    emit(
      state.copyWith(
        summaryMessage: summaryMessage,
        clearActiveStepIndex: true,
        finishedAt: finishedAt,
        runStatus: runStatus,
        steps: stepViews,
        error: failureMessage == null
            ? null
            : CustomState(message: failureMessage, title: 'Pipeline'),
      ),
    );
  }

  String _summaryWithTotal({
    required PipelineRunStatus runStatus,
    required String totalFormatted,
    required String fallback,
  }) {
    return switch (runStatus) {
      .completed => 'Pipeline completed successfully in $totalFormatted.',
      .cancelled => 'Pipeline cancelled after $totalFormatted.',
      .running => fallback,
      .failed => fallback,
      .idle => fallback,
    };
  }

  PipelineStepView _finalizeStepTiming(PipelineStepView view) {
    final started = view.startedAt;
    if (started == null) return view;
    return view.copyWith(
      elapsed: DateTime.now().difference(started),
      clearStartedAt: true,
    );
  }

  Future<void> _logStepTiming({
    required PipelineStepView view,
    required String stepName,
    required bool success,
    String? errorMessage,
  }) async {
    final sessionId = _sessionId;
    final elapsed = view.elapsed;
    if (sessionId == null || elapsed == null) return;

    final formatted = formatPipelineDuration(elapsed);
    final text = success
        ? '[$stepName completed in $formatted]'
        : '[$stepName failed in $formatted${errorMessage != null ? ' — $errorMessage' : ''}]';

    await _consolePort.logLine(
      sessionId: sessionId,
      stream: .system,
      text: text,
    );
  }

  Future<PipelineStepResult> _runShellStep(CommandStep step) async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return const PipelineStepResult(
        errorMessage: 'Pipeline console session is unavailable.',
        success: false,
      );
    }

    final shellResult = await _consolePort.runCommand(
      command: step.command,
      sessionId: sessionId,
    );

    return _mapShellResult(shellResult);
  }

  Future<PipelineStepResult> _runInternalStep(CommandStep step) async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: '> [${step.name}] ${step.command}',
        sessionId: sessionId,
        stream: .input,
      );
    }

    return _executor.executeInternal(step);
  }

  PipelineStepResult _mapShellResult(ShellRunResult result) {
    if (result.wasCancelled) {
      return const PipelineStepResult(success: false, wasCancelled: true);
    }

    if (result.exitCode != 0) {
      return PipelineStepResult(
        errorMessage: 'Exit code ${result.exitCode}',
        exitCode: result.exitCode,
        success: false,
      );
    }

    return PipelineStepResult(success: true, exitCode: result.exitCode);
  }

  Future<void> _onCancelPipeline(
    Emitter<PipelineState> emit,
    CancelPipeline event,
  ) async {
    if (!state.isRunning) return;

    _cancelRequested = true;

    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _consolePort.cancelCommand(sessionId);
    } catch (_) {}
  }

  Future<void> _onDismissPipelinePanel(
    Emitter<PipelineState> emit,
    DismissPipelinePanel event,
  ) async {
    if (state.isRunning) return;
    emit(PipelineState.idle());
  }

  Future<void> _closeConsoleSession() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _consolePort.disposeSession(sessionId);
    } catch (_) {}

    _sessionId = null;
  }

  void _emitStepRunning(
    Emitter<PipelineState> emit, {
    required List<PipelineStepView> steps,
    required int index,
  }) {
    steps[index] = steps[index].copyWith(
      status: PipelineStepStatus.running,
      startedAt: DateTime.now(),
      clearElapsed: true,
    );
    _emitSteps(emit, steps: steps, activeStepIndex: index);
  }

  void _emitSteps(
    Emitter<PipelineState> emit, {
    required List<PipelineStepView> steps,
    required int? activeStepIndex,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        steps: List<PipelineStepView>.of(steps),
        activeStepIndex: activeStepIndex,
        runStatus: .running,
      ),
    );
  }

  void _markRemainingSkipped(List<PipelineStepView> steps, int fromIndex) {
    for (var i = fromIndex; i < steps.length; i++) {
      if (steps[i].status == .pending || steps[i].status == .running) {
        steps[i] = steps[i].copyWith(status: .skipped);
      }
    }
  }
}
