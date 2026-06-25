import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/pipeline_config_source.dart';
import '../contracts/pipeline_console_port.dart';
import '../contracts/pipeline_executor.dart';
import '../models/pipeline_step_view.dart';

part 'pipeline_event.dart';
part 'pipeline_state.dart';

class PipelineBloc extends BaseBloc<PipelineEvent, PipelineState> {
  PipelineBloc({
    Map<DistributionStepKind, DistributionHandler>? distributions,
    PipelineLogWriter? logWriter,
    required this._configSource,
    required this._consolePort,
    PipelineExecutor? executor,
  }) : _distributions = distributions ?? DistributionModule.createHandlerMap(),
       _logWriter = logWriter ?? const FilePipelineLogWriter(),
       _executor = executor ?? const PipelineExecutor(),
       super(PipelineState.idle()) {
    on<DismissPipelinePanel>(handler(_onDismissPipelinePanel));
    on<CancelPipeline>(handler(_onCancelPipeline));
    on<RunPipeline>(handler(_onRunPipeline));
  }

  final Map<DistributionStepKind, DistributionHandler> _distributions;
  final PipelineConfigSource _configSource;
  final PipelineConsolePort _consolePort;
  final PipelineLogWriter _logWriter;
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
    final info = configState.appInfo;

    final projectName = info.appName ?? 'unknown';
    final buildNumber = info.buildNumber ?? '0';
    final version = info.version ?? 'unknown';

    final flushipWorkspace = (info.flushipWorkspacePath ?? '').trim();

    if (projectRoot.isEmpty || flushipWorkspace.isEmpty) {
      emit(
        PipelineState(
          summaryMessage: projectRoot.isEmpty
              ? 'Set Flutter project path in Settings → Paths.'
              : 'Set Fluship workspace path in Settings → Paths.',
          finishedAt: DateTime.now(),
          startedAt: DateTime.now(),
          activeStepIndex: null,
          runStatus: .failed,
          steps: const [],
        ),
      );
      return;
    }

    var summaryMessage = 'Pipeline completed successfully.';
    var runStatus = PipelineRunStatus.completed;
    late List<PipelineStepView> stepViews;
    final startedAt = DateTime.now();
    DistributionContext? cachedDC;
    String? failureMessage;
    String? savedLogPath;

    Future<DistributionContext> distributionContextProvider() async {
      if (cachedDC != null) return cachedDC!;

      final sessionId = _sessionId;
      if (sessionId != null && savedLogPath == null) {
        try {
          savedLogPath = await _savePipelineLog(
            projectName: projectName,
            buildNumber: buildNumber,
            sessionId: sessionId,
            version: version,
          );
        } catch (_) {}
      }

      final artifactsDir = pipelineOutputDirectory(
        flushipRoot: flushipWorkspace,
        projectName: projectName,
        buildNumber: buildNumber,
        version: version,
      );
      final distributionFinishedAt = DateTime.now();

      cachedDC = DistributionContext(
        emailTheme: ReportHtmlTheme.fromCurrentTheme(),
        config: configState.distribution,
        snapshot: PipelineRunSnapshot(
          totalElapsed: distributionFinishedAt.difference(startedAt),
          platforms: DistributionPlatforms.fromConfig(configState),
          steps: List<PipelineStepView>.of(stepViews),
          finishedAt: distributionFinishedAt,
          logFilePath: savedLogPath ?? '',
          artifactsDir: artifactsDir,
          buildNumber: buildNumber,
          appName: projectName,
          runStatus: runStatus,
          startedAt: startedAt,
          version: version,
        ),
        logger: PipelineDistributionLogger(
          consolePort: _consolePort,
          sessionId: sessionId!,
        ),
      );

      return cachedDC!;
    }

    final commandSteps = ConfigPipelineResolver.resolve(
      contextProvider: distributionContextProvider,
      handlers: _distributions,
      configState,
    );

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

    stepViews = commandSteps
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
        stepViews[index] = _finalizeStepTiming(
          stepViews[index],
        ).copyWith(errorMessage: 'Cancelled', status: .failed);
        await _logStepTiming(
          errorMessage: 'Cancelled',
          view: stepViews[index],
          stepName: step.name,
          success: false,
        );

        summaryMessage = 'Pipeline cancelled.';
        runStatus = .cancelled;

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
    final totalFormatted = PipelineUtils.formatPipelineDuration(totalElapsed);

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: '[pipeline ${runStatus.name} in $totalFormatted]',
        sessionId: sessionId,
        stream: .system,
      );

      if (savedLogPath == null) {
        try {
          await _savePipelineLog(
            projectName: projectName,
            buildNumber: buildNumber,
            sessionId: sessionId,
            version: version,
          );
        } catch (_) {}
      }
    }

    if (isClosed) return;

    summaryMessage = _summaryWithTotal(
      totalFormatted: totalFormatted,
      fallback: summaryMessage,
      runStatus: runStatus,
    );

    emit(
      state.copyWith(
        error: failureMessage != null
            ? CustomState(message: failureMessage, title: 'Pipeline')
            : null,
        summaryMessage: summaryMessage,
        clearActiveStepIndex: true,
        finishedAt: finishedAt,
        runStatus: runStatus,
        steps: stepViews,
      ),
    );
  }

  Future<String?> _savePipelineLog({
    required String projectName,
    required String buildNumber,
    required String sessionId,
    required String version,
  }) async {
    final lines = _consolePort.sessionLines(sessionId);
    if (lines.isEmpty) return null;

    final logPath = await _logWriter.save(
      projectName: projectName,
      buildNumber: buildNumber,
      version: version,
      lines: lines,
    );

    final relativePath = pipelineLogRelativePath(
      projectName: projectName,
      buildNumber: buildNumber,
      version: version,
    );

    await _consolePort.logLine(
      text: '[pipeline log saved to $relativePath]',
      sessionId: sessionId,
      stream: .system,
    );

    return logPath;
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

    final formatted = PipelineUtils.formatPipelineDuration(elapsed);
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
