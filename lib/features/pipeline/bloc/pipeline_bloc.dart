import 'dart:async' show unawaited;

import 'package:fluship/features/console/utils/console_line_classifier.dart';
import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/features/console/models/console_line.dart';
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
  PipelineBloc(
    this._logWriter, {
    Map<DistributionStepKind, DistributionHandler>? distributions,
    required this._configSource,
    required this._consolePort,
    PipelineExecutor? executor,
  }) : _distributions = distributions ?? DistributionModule.createHandlerMap(),
       _executor = executor ?? const PipelineExecutor(),
       super(PipelineState.idle()) {
    on<DismissPipelinePanel>(handler(_onDismissPipelinePanel));
    on<RemovePipelineStep>(handler(_onRemovePipelineStep));
    on<CancelPipeline>(handler(_onCancelPipeline));
    on<RunPipeline>(handler(_onRunPipeline));
  }

  final Map<DistributionStepKind, DistributionHandler> _distributions;
  final PipelineConfigSource _configSource;
  final PipelineConsolePort _consolePort;
  final PipelineLogWriter _logWriter;
  final PipelineExecutor _executor;

  /// Owned by the bloc rather than the run loop so that removing a step while
  /// the pipeline is running is not overwritten by the next step transition.
  var _commandSteps = const <CommandStep>[];
  final _uploadGate = UploadProgressGate();
  final _stepViews = <PipelineStepView>[];

  var _cancelRequested = false;
  int? _runningIndex;
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

    await _configSource.persistActiveProfile();

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
    final startedAt = DateTime.now();
    DistributionContext? cachedDC;
    var hadStepFailures = false;
    String? failureMessage;
    String? savedLogPath;

    final artifacts = PipelineRunArtifacts(startedAt: startedAt);
    final emailTheme = ReportHtmlTheme.fromCurrentTheme();

    Future<DistributionContext> buildDistributionContext({
      required String logFilePath,
    }) async {
      final sessionId = _sessionId!;
      final artifactsDir = pipelineOutputDirectory(
        flushipRoot: flushipWorkspace,
        projectName: projectName,
        buildNumber: buildNumber,
        version: version,
      );

      final contextFinishedAt = DateTime.now();
      return DistributionContext(
        onUploadProgress: (progress) => _applyUploadProgress(emit, progress),
        emailTheme: emailTheme,
        config: configState.distribution,
        snapshot: PipelineRunSnapshot(
          platforms: DistributionPlatforms.fromArtifacts(artifacts.paths),
          totalElapsed: contextFinishedAt.difference(startedAt),
          collectedArtifacts: List<String>.of(artifacts.paths),
          steps: List<PipelineStepView>.of(_stepViews),
          finishedAt: contextFinishedAt,
          artifactsDir: artifactsDir,
          buildNumber: buildNumber,
          logFilePath: logFilePath,
          appName: projectName,
          runStatus: runStatus,
          startedAt: startedAt,
          version: version,
        ),
        logger: PipelineDistributionLogger(
          consolePort: _consolePort,
          sessionId: sessionId,
        ),
      );
    }

    Future<DistributionContext> distributionContextProvider() async {
      if (cachedDC != null) return cachedDC!;

      cachedDC = await buildDistributionContext(logFilePath: '');
      return cachedDC!;
    }

    Future<DistributionContext> reportContextProvider() async {
      if (savedLogPath == null) {
        final sessionId = _sessionId;
        if (sessionId != null) {
          try {
            savedLogPath = await _savePipelineLog(
              projectName: projectName,
              buildNumber: buildNumber,
              sessionId: sessionId,
              version: version,
            );
          } catch (_) {}
        }
      }

      return buildDistributionContext(logFilePath: savedLogPath ?? '');
    }

    final commandSteps = ConfigPipelineResolver.resolve(
      contextProvider: distributionContextProvider,
      reportContextProvider: reportContextProvider,
      handlers: _distributions,
      artifacts: artifacts,
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

    _commandSteps = commandSteps;
    _stepViews
      ..clear()
      ..addAll(
        commandSteps.map(
          (step) => PipelineStepView(
            description: step.description,
            status: .pending,
            name: step.name,
          ),
        ),
      );

    emit(
      PipelineState(
        steps: List<PipelineStepView>.of(_stepViews),
        summaryMessage: 'Running pipeline…',
        activeStepIndex: null,
        startedAt: startedAt,
        runStatus: .running,
      ),
    );

    _sessionId = await _consolePort.createSession(projectRoot: projectRoot);
    _uploadGate.reset();
    await _consolePort.logLine(
      text: PipelineLogCopy.started(
        build: buildNumber,
        app: projectName,
        version: version,
      ),
      sessionId: _sessionId!,
      stream: .system,
      kind: .info,
    );

    for (var index = 0; index < commandSteps.length; index++) {
      if (_cancelRequested || isClosed) {
        runStatus = PipelineRunStatus.cancelled;
        summaryMessage = 'Pipeline cancelled.';
        _markRemainingSkipped(index, includeAlwaysRun: true);
        break;
      }

      // Skipped by a cascade or removed from the panel while running.
      if (_stepViews[index].status == .skipped) continue;

      final step = commandSteps[index];
      _emitStepRunning(emit, index: index);

      final result = step.isInternal
          ? await _runInternalStep(step)
          : await _runShellStep(step);

      if (_cancelRequested || result.wasCancelled) {
        _stepViews[index] = _finalizeStepTiming(
          _stepViews[index],
        ).copyWith(status: .cancelled);
        await _logStepTiming(
          view: _stepViews[index],
          stepName: step.name,
          outcome: .cancelled,
        );

        summaryMessage = 'Pipeline cancelled.';
        runStatus = .cancelled;

        _markRemainingSkipped(index + 1, includeAlwaysRun: true);
        _emitSteps(emit, activeStepIndex: null);
        break;
      }

      if (!result.success) {
        hadStepFailures = true;
        final errorText = PipelineUtils.formatStepError(result.errorMessage);
        _stepViews[index] = _finalizeStepTiming(
          _stepViews[index],
        ).copyWith(status: PipelineStepStatus.failed, errorMessage: errorText);
        await _logStepTiming(
          errorMessage: errorText,
          view: _stepViews[index],
          stepName: step.name,
          outcome: .failed,
        );

        summaryMessage = '${step.name} failed.';
        failureMessage ??= errorText;
        runStatus = PipelineRunStatus.failed;

        if (step.isCritical) {
          _markRemainingSkipped(index + 1);
        } else {
          _cascadeSkip(fromIndex: index + 1, blockedIds: {?step.id});
        }

        _emitSteps(emit, activeStepIndex: null);
        continue;
      }

      _stepViews[index] = _finalizeStepTiming(
        _stepViews[index],
      ).copyWith(status: .completed);

      await _logStepTiming(
        view: _stepViews[index],
        stepName: step.name,
        outcome: .completed,
      );

      _emitSteps(emit, activeStepIndex: null);
    }

    final finishedAt = DateTime.now();
    final totalElapsed = finishedAt.difference(startedAt);
    final totalFormatted = PipelineUtils.formatPipelineDuration(totalElapsed);

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: PipelineLogCopy.ended(runStatus, totalFormatted),
        sessionId: sessionId,
        stream: .system,
        kind: switch (runStatus) {
          .cancelled => .warn,
          .failed => .error,
          _ => .success,
        },
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
      hadStepFailures: hadStepFailures,
      totalFormatted: totalFormatted,
      fallback: summaryMessage,
      runStatus: runStatus,
    );

    emit(
      state.copyWith(
        error: failureMessage != null
            ? CustomState(message: failureMessage, title: 'Pipeline')
            : null,
        steps: List<PipelineStepView>.of(_stepViews),
        summaryMessage: summaryMessage,
        clearActiveStepIndex: true,
        finishedAt: finishedAt,
        runStatus: runStatus,
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
      text: PipelineLogCopy.logSaved(relativePath),
      sessionId: sessionId,
      stream: .system,
      kind: .info,
    );

    return logPath;
  }

  String _summaryWithTotal({
    required PipelineRunStatus runStatus,
    required String totalFormatted,
    required bool hadStepFailures,
    required String fallback,
  }) {
    return switch (runStatus) {
      .completed => 'Pipeline completed successfully in $totalFormatted.',
      .failed when hadStepFailures =>
        'Pipeline finished with failed steps in $totalFormatted.',
      .cancelled => 'Pipeline cancelled after $totalFormatted.',
      .running => fallback,
      .failed => fallback,
      .idle => fallback,
    };
  }

  PipelineStepView _finalizeStepTiming(PipelineStepView view) {
    final started = view.startedAt;
    if (started == null) return view.copyWith(clearUpload: true);

    return view.copyWith(
      elapsed: DateTime.now().difference(started),
      clearStartedAt: true,
      clearUpload: true,
    );
  }

  Future<void> _logStepTiming({
    required PipelineStepView view,
    required String stepName,
    required PipelineStepStatus outcome,
    String? errorMessage,
  }) async {
    final sessionId = _sessionId;
    final elapsed = view.elapsed;
    if (sessionId == null || elapsed == null) return;

    final formatted = PipelineUtils.formatPipelineDuration(elapsed);
    final (text, kind) = switch (outcome) {
      .cancelled => (
        PipelineLogCopy.stepCancelled(stepName, formatted),
        ConsoleLineKind.warn,
      ),
      .failed => (
        PipelineLogCopy.stepFailed(stepName, formatted, errorMessage),
        ConsoleLineKind.error,
      ),
      _ => (
        PipelineLogCopy.stepFinished(stepName, formatted),
        ConsoleLineKind.success,
      ),
    };

    await _consolePort.logLine(
      sessionId: sessionId,
      stream: .system,
      kind: kind,
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

    final result = _mapShellResult(
      await _consolePort.runCommand(
        command: step.command,
        sessionId: sessionId,
      ),
    );

    final recovery = step.recoveryCommand;
    if (result.success ||
        result.wasCancelled ||
        _cancelRequested ||
        recovery == null) {
      return result;
    }

    await _consolePort.logLine(
      text: PipelineLogCopy.stepRetry(step.name),
      sessionId: sessionId,
      stream: .system,
      kind: .warn,
    );

    return _mapShellResult(
      await _consolePort.runCommand(command: recovery, sessionId: sessionId),
    );
  }

  Future<PipelineStepResult> _runInternalStep(CommandStep step) async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: PipelineLogCopy.stepStarting(step.name),
        sessionId: sessionId,
        stream: .system,
        kind: .info,
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
        errorMessage: _shellFailureMessage(result.exitCode),
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

  Future<void> _onRemovePipelineStep(
    Emitter<PipelineState> emit,
    RemovePipelineStep event,
  ) async {
    final index = event.index;
    if (!state.isRunning || index < 0 || index >= _stepViews.length) return;
    if (_stepViews[index].status != .pending) return;

    final step = _commandSteps[index];
    _stepViews[index] = _stepViews[index].copyWith(status: .skipped);
    _cascadeSkip(fromIndex: index + 1, blockedIds: {?step.id});

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _consolePort.logLine(
        text: PipelineLogCopy.stepRemoved(step.name),
        sessionId: sessionId,
        stream: .system,
        kind: .info,
      );
    }

    _emitSteps(emit, activeStepIndex: state.activeStepIndex);
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

  void _applyUploadProgress(
    Emitter<PipelineState> emit,
    PipelineUploadProgress progress,
  ) {
    if (isClosed || _cancelRequested) return;
    if (!_uploadGate.allow(progress)) return;

    final index = _runningIndex ?? state.activeStepIndex;
    if (index == null || index < 0 || index >= _stepViews.length) return;
    if (_stepViews[index].status != .running) return;

    _stepViews[index] = _stepViews[index].copyWith(upload: progress);
    _emitSteps(emit, activeStepIndex: index);

    final sessionId = _sessionId;
    if (sessionId == null) return;
    unawaited(
      _consolePort.logLine(
        text: progress.consoleLine,
        sessionId: sessionId,
        stream: .stdout,
        kind: .progress,
      ),
    );
  }

  String _shellFailureMessage(int exitCode) {
    final sessionId = _sessionId;
    if (sessionId != null) {
      final lines = _consolePort.sessionLines(sessionId);
      for (var i = lines.length - 1; i >= 0; i--) {
        if (lines[i].displayKind != .error) continue;
        final text = lines[i].text.trim();
        if (text.isEmpty || text.startsWith('[exit')) continue;
        return PipelineUtils.formatStepError(text);
      }
    }
    return PipelineUtils.formatStepError('Exit code $exitCode');
  }

  void _emitStepRunning(Emitter<PipelineState> emit, {required int index}) {
    _uploadGate.reset();
    _runningIndex = index;
    _stepViews[index] = _stepViews[index].copyWith(
      status: PipelineStepStatus.running,
      startedAt: DateTime.now(),
      clearElapsed: true,
      clearUpload: true,
    );
    _emitSteps(emit, activeStepIndex: index);
  }

  void _emitSteps(
    Emitter<PipelineState> emit, {
    required int? activeStepIndex,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        steps: List<PipelineStepView>.of(_stepViews),
        activeStepIndex: activeStepIndex,
        runStatus: .running,
      ),
    );
  }

  /// Skips every pending step that depends, directly or through another
  /// skipped step, on one of [blockedIds]. Single forward pass: each newly
  /// skipped id joins the blocked set, so transitive edges resolve in order.
  void _cascadeSkip({
    required Set<PipelineStepId> blockedIds,
    required int fromIndex,
  }) {
    if (blockedIds.isEmpty) return;

    for (var i = fromIndex; i < _stepViews.length; i++) {
      if (_stepViews[i].status != .pending) continue;

      final step = _commandSteps[i];
      if (step.alwaysRun || step.dependsOn.isEmpty) continue;
      if (!step.dependsOn.any(blockedIds.contains)) continue;

      _stepViews[i] = _stepViews[i].copyWith(status: .skipped);
      if (step.id != null) blockedIds.add(step.id!);
    }
  }

  /// [includeAlwaysRun] is set when the run stops for good, such as a cancel,
  /// so nothing is left showing as pending. An aborting failure leaves those
  /// steps alone because the build report still has to go out.
  void _markRemainingSkipped(int fromIndex, {bool includeAlwaysRun = false}) {
    final steps = _stepViews;
    for (var i = fromIndex; i < steps.length; i++) {
      if (!includeAlwaysRun && _commandSteps[i].alwaysRun) continue;
      if (steps[i].status == .pending || steps[i].status == .running) {
        steps[i] = steps[i].copyWith(status: .skipped);
      }
    }
  }
}
