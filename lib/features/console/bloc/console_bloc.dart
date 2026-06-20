import 'dart:async' show Timer;

import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/services/console/console_limits.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/console_line_buffer.dart';
import '../models/console_session.dart';
import '../models/console_line.dart';

part 'console_event.dart';
part 'console_state.dart';

const pipelineConsoleSessionId = '_pipeline_console';

bool isPipelineConsoleSession(String sessionId) =>
    sessionId.startsWith('_pipeline_');

class ConsoleBloc extends BaseBloc<ConsoleEvent, ConsoleState> {
  ConsoleBloc({required this._pool}) : super(ConsoleState.empty()) {
    on<DisposeAllSessions>(handler(_onDisposeAllSessions));
    on<SyncProjectRoot>(handler(_onSyncProjectRoot));
    on<CreateSession>(handler(_onCreateSession));
    on<SelectSession>(handler(_onSelectSession));
    on<CloseSession>(handler(_onCloseSession));
    on<ClearConsole>(handler(_onClearConsole));

    on<CreatePipelineSession>(handler(_onCreatePipelineSession));
    on<CancelPipelineCommand>(handler(_onCancelPipelineCommand));
    on<ClosePipelineSession>(handler(_onClosePipelineSession));
    on<RunPipelineCommand>(handler(_onRunPipelineCommand));
    on<LogPipelineLine>(handler(_onLogPipelineLine));

    on<SubmitCommand>(_onSubmitCommand);
    on<CancelCommand>(_onCancelCommand);
  }

  final Map<String, List<ConsoleLine>> _pendingLines = {};
  final Map<String, Timer?> _flushTimers = {};
  final IConsoleSessionPool _pool;

  String? _activeSessionBeforePipeline;

  @override
  Future<void> close() async {
    await _disposeAllSessions(emit: null);
    return super.close();
  }

  bool _isSessionActive(String sessionId) =>
      !isClosed && state.sessionById(sessionId) != null;

  bool _isPipelineSession(String sessionId) =>
      isPipelineConsoleSession(sessionId);

  void _clearSessionBuffers(String sessionId) {
    _flushTimers.remove(sessionId)?.cancel();
    _pendingLines.remove(sessionId);
  }

  Future<void> _disposeAllSessions({
    required Emitter<ConsoleState>? emit,
  }) async {
    for (final timer in _flushTimers.values) {
      timer?.cancel();
    }

    _activeSessionBeforePipeline = null;
    _pendingLines.clear();
    _flushTimers.clear();

    for (final session in state.sessions) {
      if (session.isRunning) {
        try {
          await _pool.cancel(session.id);
        } catch (_) {}
      }
    }

    await _pool.disposeAll();

    if (emit == null || isClosed) return;

    emit(
      ConsoleState.empty().copyWith(
        nextTerminalIndex: state.nextTerminalIndex,
        projectRoot: state.projectRoot,
      ),
    );
  }

  Future<void> _onDisposeAllSessions(
    Emitter<ConsoleState> emit,
    DisposeAllSessions event,
  ) async {
    await _disposeAllSessions(emit: emit);
  }

  Future<void> _onSyncProjectRoot(
    Emitter<ConsoleState> emit,
    SyncProjectRoot event,
  ) async {
    final oldRoot = state.projectRoot;
    final newRoot = event.path?.trim();
    emit(state.copyWith(projectRoot: newRoot));

    if (newRoot == null || newRoot.isEmpty) return;

    if (state.sessions.isEmpty) {
      await _createSessionInternal(emit, newRoot);
      return;
    }

    if (oldRoot == null || oldRoot == newRoot) return;

    emit(
      state.copyWith(
        sessions: state.sessions.map((session) {
          if (session.workingDirectory == oldRoot) {
            return session.copyWith(workingDirectory: newRoot);
          }
          return session;
        }).toList(),
      ),
    );
  }

  Future<void> _onCreateSession(
    Emitter<ConsoleState> emit,
    CreateSession event,
  ) async {
    final root = state.projectRoot;
    if (root == null || root.isEmpty) return;
    if (!state.canAddSession) return;
    await _createSessionInternal(emit, root);
  }

  Future<void> _createSessionInternal(
    Emitter<ConsoleState> emit,
    String projectRoot,
  ) async {
    final id = _newSessionId();
    final title = 'Fluship T${state.nextTerminalIndex}';

    await _pool.create(sessionId: id, projectRoot: projectRoot);

    final session = ConsoleSession(
      workingDirectory: projectRoot,
      commandHistory: const [],
      isRunning: false,
      lines: const [],
      title: title,
      id: id,
    );

    emit(
      state.copyWith(
        nextTerminalIndex: state.nextTerminalIndex + 1,
        sessions: [...state.sessions, session],
        activeSessionId: id,
      ),
    );
  }

  Future<String> _onCreatePipelineSession(
    Emitter<ConsoleState> emit,
    CreatePipelineSession event,
  ) async {
    _activeSessionBeforePipeline ??= state.activeSessionId;
    const id = pipelineConsoleSessionId;

    final existing = state.sessionById(id);
    if (existing != null) {
      _clearSessionBuffers(id);
      if (existing.isRunning) {
        try {
          await _pool.cancel(id);
        } catch (_) {}
      }

      _updateSession(
        emit: emit,
        sessionId: id,
        transform: (session) => session.copyWith(
          workingDirectory: event.projectRoot,
          commandHistory: const [],
          isRunning: false,
          lines: const [],
        ),
      );
      emit(state.copyWith(activeSessionId: id));
      return id;
    }

    await _pool.create(sessionId: id, projectRoot: event.projectRoot);

    final session = ConsoleSession(
      workingDirectory: event.projectRoot,
      commandHistory: const [],
      isRunning: false,
      lines: const [],
      title: 'Pipeline',
      id: id,
    );

    emit(
      state.copyWith(
        sessions: [session, ...state.sessions],
        activeSessionId: id,
      ),
    );

    return id;
  }

  Future<ShellRunResult> _onRunPipelineCommand(
    Emitter<ConsoleState> emit,
    RunPipelineCommand event,
  ) async {
    final sessionId = event.sessionId;
    final command = event.command.trim();
    final session = state.sessionById(sessionId);
    if (command.isEmpty || session == null) {
      return const ShellRunResult(exitCode: 1);
    }

    if (session.isRunning) {
      return const ShellRunResult(exitCode: 1);
    }

    _updateSession(
      emit: emit,
      sessionId: sessionId,
      transform: (current) => current.copyWith(
        isRunning: true,
        lines: ConsoleLineBuffer.appendLine(
          lines: current.lines,
          text: '> $command',
          stream: .input,
        ),
      ),
    );

    return _runCommandOnSession(
      sessionId: sessionId,
      command: command,
      emit: emit,
    );
  }

  Future<void> _onCancelPipelineCommand(
    Emitter<ConsoleState> emit,
    CancelPipelineCommand event,
  ) async {
    final session = state.sessionById(event.sessionId);
    if (session == null || !session.isRunning) return;

    try {
      await _pool.cancel(event.sessionId);
    } catch (_) {}

    _clearSessionBuffers(event.sessionId);
    if (!_isSessionActive(event.sessionId)) return;

    _updateSession(
      transform: (c) => c.copyWith(isRunning: false),
      sessionId: event.sessionId,
      emit: emit,
    );
  }

  Future<void> _onClosePipelineSession(
    Emitter<ConsoleState> emit,
    ClosePipelineSession event,
  ) async {
    final id = event.sessionId;
    final session = state.sessionById(id);
    if (session == null) return;

    if (session.isRunning) {
      try {
        await _pool.cancel(id);
      } catch (_) {}
    }

    try {
      await _pool.dispose(id);
    } catch (_) {}

    _clearSessionBuffers(id);

    final remaining = state.sessions
        .where((session) => session.id != id)
        .toList();

    final pa = _activeSessionBeforePipeline;
    _activeSessionBeforePipeline = null;

    String? activeId;
    if (remaining.isNotEmpty) {
      if (pa != null && remaining.any((s) => s.id == pa)) {
        activeId = pa;
      } else {
        activeId = remaining.first.id;
      }
    }

    if (isClosed) return;
    emit(
      state.copyWith(
        clearActiveSessionId: activeId == null,
        activeSessionId: activeId,
        sessions: remaining,
      ),
    );
  }

  Future<void> _onLogPipelineLine(
    Emitter<ConsoleState> emit,
    LogPipelineLine event,
  ) async {
    if (!_isSessionActive(event.sessionId)) return;
    _updateSession(
      emit: emit,
      sessionId: event.sessionId,
      transform: (session) => session.copyWith(
        lines: ConsoleLineBuffer.appendLine(
          lines: session.lines,
          stream: event.stream,
          text: event.text,
        ),
      ),
    );
  }

  Future<void> _onCloseSession(
    Emitter<ConsoleState> emit,
    CloseSession event,
  ) async {
    if (_isPipelineSession(event.sessionId)) return;

    final userSessions = state.sessions
        .where((session) => !_isPipelineSession(session.id))
        .length;

    if (userSessions <= 1) return;

    final id = event.sessionId;
    final session = state.sessionById(id);
    if (session == null) return;

    if (session.isRunning) {
      try {
        await _pool.cancel(id);
      } catch (_) {}
    }

    try {
      await _pool.dispose(id);
    } catch (_) {}

    _clearSessionBuffers(id);

    final remaining = state.sessions.where((s) => s.id != id).toList();
    final activeId = state.activeSessionId == id
        ? remaining
              .firstWhere(
                (session) => !_isPipelineSession(session.id),
                orElse: () => remaining.first,
              )
              .id
        : state.activeSessionId;

    if (isClosed) return;
    emit(state.copyWith(sessions: remaining, activeSessionId: activeId));
  }

  Future<void> _onSelectSession(
    Emitter<ConsoleState> emit,
    SelectSession event,
  ) async {
    if (state.sessionById(event.sessionId) == null) return;
    emit(state.copyWith(activeSessionId: event.sessionId));
  }

  Future<void> _onClearConsole(
    Emitter<ConsoleState> emit,
    ClearConsole event,
  ) async {
    final id = state.activeSessionId;
    if (id == null) return;
    _updateSession(
      transform: (session) => session.copyWith(lines: const []),
      sessionId: id,
      emit: emit,
    );
  }

  Future<void> _onSubmitCommand(
    SubmitCommand event,
    Emitter<ConsoleState> emit,
  ) async {
    final command = event.command.trim();
    if (command.isEmpty) return;

    final sessionId = state.activeSessionId;
    final session = state.activeSession;
    if (sessionId == null || session == null) return;

    if (session.isRunning) {
      _appendSystem(emit, sessionId, 'A command is already running.');
      return;
    }

    final root = state.projectRoot;
    if (root == null || root.isEmpty) {
      _appendSystem(
        emit,
        sessionId,
        'Set Flutter project path in Settings first.',
      );
      return;
    }

    final history = [...session.commandHistory, command];
    if (history.length > ConsoleLimits.maxCommandHistory) {
      history.removeAt(0);
    }

    _updateSession(
      emit: emit,
      sessionId: sessionId,
      transform: (current) => current.copyWith(
        commandHistory: history,
        isRunning: true,
        lines: ConsoleLineBuffer.appendLine(
          lines: current.lines,
          text: '> $command',
          stream: .input,
        ),
      ),
    );

    await _runCommandOnSession(
      sessionId: sessionId,
      command: command,
      emit: emit,
    );
  }

  Future<ShellRunResult> _runCommandOnSession({
    required Emitter<ConsoleState> emit,
    required String sessionId,
    required String command,
  }) async {
    _pendingLines[sessionId] = List<ConsoleLine>.from(
      state.sessionById(sessionId)!.lines,
    );

    void flushPending() {
      _flushTimers[sessionId]?.cancel();
      _flushTimers[sessionId] = null;
      if (!_isSessionActive(sessionId)) return;
      final pending = _pendingLines[sessionId];
      if (pending == null) return;
      _updateSession(
        transform: (session) => session.copyWith(
          lines: List<ConsoleLine>.from(pending),
          isRunning: true,
        ),
        sessionId: sessionId,
        emit: emit,
      );
    }

    void scheduleFlush() {
      if (!_isSessionActive(sessionId)) return;
      if (_flushTimers[sessionId] != null) return;
      _flushTimers[sessionId] = Timer(
        const Duration(milliseconds: ConsoleLimits.flushIntervalMs),
        flushPending,
      );
    }

    try {
      final result = await _pool.run(
        sessionId,
        command,
        onStdout: (chunk) {
          if (!_isSessionActive(sessionId)) return;
          final pending = _pendingLines[sessionId] ??= [];
          ConsoleLineBuffer.mergeChunkInPlace(
            stream: .stdout,
            lines: pending,
            chunk: chunk,
          );
          scheduleFlush();
        },
        onStderr: (chunk) {
          if (!_isSessionActive(sessionId)) return;
          final pending = _pendingLines[sessionId] ??= [];
          ConsoleLineBuffer.mergeChunkInPlace(
            stream: .stderr,
            lines: pending,
            chunk: chunk,
          );
          scheduleFlush();
        },
        onCwdChanged: (cwd) {
          if (!_isSessionActive(sessionId)) return;
          _updateSession(
            transform: (s) => s.copyWith(workingDirectory: cwd),
            sessionId: sessionId,
            emit: emit,
          );
        },
      );

      flushPending();
      _clearSessionBuffers(sessionId);
      if (!_isSessionActive(sessionId)) return result;

      if (result.wasCancelled) {
        _updateSession(
          emit: emit,
          sessionId: sessionId,
          transform: (session) => session.copyWith(
            isRunning: false,
            lines: ConsoleLineBuffer.appendLine(
              lines: session.lines,
              text: '[cancelled]',
              stream: .system,
            ),
          ),
        );
        return result;
      }

      if (result.cwd != null && result.cwd!.isNotEmpty) {
        _updateSession(
          transform: (s) => s.copyWith(workingDirectory: result.cwd!),
          sessionId: sessionId,
          emit: emit,
        );
      }

      _updateSession(
        emit: emit,
        sessionId: sessionId,
        transform: (session) => session.copyWith(
          isRunning: false,
          lines: ConsoleLineBuffer.appendLine(
            text: '[exit ${result.exitCode}]',
            lines: session.lines,
            stream: .system,
          ),
        ),
      );
      return result;
    } catch (error) {
      flushPending();
      _clearSessionBuffers(sessionId);

      if (!_isSessionActive(sessionId)) {
        return const ShellRunResult(exitCode: 1);
      }

      _updateSession(
        emit: emit,
        sessionId: sessionId,
        transform: (session) => session.copyWith(
          lines: ConsoleLineBuffer.appendLine(
            text: error.toString(),
            lines: session.lines,
            stream: .system,
          ),
          isRunning: false,
        ),
      );
      return const ShellRunResult(exitCode: 1);
    }
  }

  Future<void> _onCancelCommand(
    CancelCommand event,
    Emitter<ConsoleState> emit,
  ) async {
    final id = state.activeSessionId;
    if (id == null) return;
    final session = state.sessionById(id);
    if (session == null || !session.isRunning) return;

    try {
      await _pool.cancel(id);
    } catch (_) {}

    _clearSessionBuffers(id);
    if (!_isSessionActive(id)) return;

    _updateSession(
      transform: (session) => session.copyWith(isRunning: false),
      sessionId: id,
      emit: emit,
    );
  }

  void _updateSession({
    required ConsoleSession Function(ConsoleSession session) transform,
    required Emitter<ConsoleState> emit,
    required String sessionId,
  }) {
    if (isClosed) return;
    final index = state.sessions.indexWhere(
      (session) => session.id == sessionId,
    );
    if (index == -1) return;
    final updated = List<ConsoleSession>.of(state.sessions);
    updated[index] = transform(state.sessions[index]);
    emit(state.copyWith(sessions: updated));
  }

  void _appendSystem(
    Emitter<ConsoleState> emit,
    String sessionId,
    String text,
  ) {
    _updateSession(
      emit: emit,
      sessionId: sessionId,
      transform: (session) => session.copyWith(
        lines: ConsoleLineBuffer.appendLine(
          lines: session.lines,
          stream: .system,
          text: text,
        ),
      ),
    );
  }

  String _newSessionId() =>
      'session_${DateTime.now().microsecondsSinceEpoch}_${state.sessions.length}';
}
