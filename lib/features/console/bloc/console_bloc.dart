import 'dart:async' show Timer;

import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/console/console_limits.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/console_line_buffer.dart';
import '../models/console_session.dart';
import '../models/console_line.dart';

part 'console_event.dart';
part 'console_state.dart';

class ConsoleBloc extends BaseBloc<ConsoleEvent, ConsoleState> {
  ConsoleBloc({required this._pool}) : super(ConsoleState.empty()) {
    on<DisposeAllSessions>(handler(_onDisposeAllSessions));
    on<SyncProjectRoot>(handler(_onSyncProjectRoot));
    on<CreateSession>(handler(_onCreateSession));
    on<SelectSession>(handler(_onSelectSession));
    on<CloseSession>(handler(_onCloseSession));
    on<ClearConsole>(handler(_onClearConsole));

    on<SubmitCommand>(_onSubmitCommand);
    on<CancelCommand>(_onCancelCommand);
  }

  final Map<String, List<ConsoleLine>> _pendingLines = {};
  final Map<String, Timer?> _flushTimers = {};
  final IConsoleSessionPool _pool;

  @override
  Future<void> close() async {
    await _disposeAllSessions(emit: null);
    return super.close();
  }

  bool _isSessionActive(String sessionId) =>
      !isClosed && state.sessionById(sessionId) != null;

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

  Future<void> _onCloseSession(
    Emitter<ConsoleState> emit,
    CloseSession event,
  ) async {
    if (state.sessions.length <= 1) return;

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
        ? remaining.first.id
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
      transform: (s) => s.copyWith(
        commandHistory: history,
        isRunning: true,
        lines: ConsoleLineBuffer.appendLine(
          text: '> $command',
          lines: s.lines,
          stream: .input,
        ),
      ),
    );

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
        transform: (s) => s.copyWith(lines: .from(pending), isRunning: true),
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
            lines: pending,
            stream: .stdout,
            chunk: chunk,
          );
          scheduleFlush();
        },
        onStderr: (chunk) {
          if (!_isSessionActive(sessionId)) return;
          final pending = _pendingLines[sessionId] ??= [];
          ConsoleLineBuffer.mergeChunkInPlace(
            lines: pending,
            stream: .stderr,
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
      if (!_isSessionActive(sessionId)) return;

      if (result.wasCancelled) {
        _updateSession(
          emit: emit,
          sessionId: sessionId,
          transform: (s) => s.copyWith(
            isRunning: false,
            lines: ConsoleLineBuffer.appendLine(
              text: '[cancelled]',
              stream: .system,
              lines: s.lines,
            ),
          ),
        );
        return;
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
        transform: (s) => s.copyWith(
          isRunning: false,
          lines: ConsoleLineBuffer.appendLine(
            text: '[exit ${result.exitCode}]',
            stream: .system,
            lines: s.lines,
          ),
        ),
      );
    } catch (e) {
      flushPending();
      _clearSessionBuffers(sessionId);
      if (!_isSessionActive(sessionId)) return;
      _updateSession(
        emit: emit,
        sessionId: sessionId,
        transform: (s) => s.copyWith(
          lines: ConsoleLineBuffer.appendLine(
            text: e.toString(),
            stream: .system,
            lines: s.lines,
          ),
          isRunning: false,
        ),
      );
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
      transform: (s) => s.copyWith(isRunning: false),
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
      transform: (s) => s.copyWith(
        lines: ConsoleLineBuffer.appendLine(
          stream: .system,
          lines: s.lines,
          text: text,
        ),
      ),
    );
  }

  String _newSessionId() =>
      'session_${DateTime.now().microsecondsSinceEpoch}_${state.sessions.length}';
}
