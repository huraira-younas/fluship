import 'dart:async' show Completer;

import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/console/bloc/console_bloc.dart';

abstract interface class PipelineConsolePort {
  Future<String> createSession({required String projectRoot});
  Future<ShellRunResult> runCommand({
    required String sessionId,
    required String command,
  });

  Future<void> logLine({
    required ConsoleStream stream,
    required String sessionId,
    ConsoleLineKind? kind,
    required String text,
  });

  List<ConsoleLine> sessionLines(String sessionId);
  Future<void> disposeSession(String sessionId);
  Future<void> cancelCommand(String sessionId);
}

final class ConsoleBlocPipelinePort(final ConsoleBloc _bloc)
    implements PipelineConsolePort {
  @override
  Future<String> createSession({required String projectRoot}) {
    return _dispatch<String>(CreatePipelineSession(projectRoot: projectRoot));
  }

  @override
  Future<ShellRunResult> runCommand({
    required String sessionId,
    required String command,
  }) {
    return _dispatch<ShellRunResult>(
      RunPipelineCommand(sessionId: sessionId, command: command),
    );
  }

  @override
  Future<void> logLine({
    required ConsoleStream stream,
    required String sessionId,
    required String text,
    ConsoleLineKind? kind,
  }) {
    return _dispatch<void>(
      LogPipelineLine(
        sessionId: sessionId,
        stream: stream,
        text: text,
        kind: kind,
      ),
    );
  }

  @override
  Future<void> cancelCommand(String sessionId) {
    return _dispatch<void>(CancelPipelineCommand(sessionId: sessionId));
  }

  @override
  Future<void> disposeSession(String sessionId) {
    return _dispatch<void>(ClosePipelineSession(sessionId: sessionId));
  }

  @override
  List<ConsoleLine> sessionLines(String sessionId) {
    final session = _bloc.state.sessionById(sessionId);
    if (session == null) return const [];
    return List<ConsoleLine>.from(session.lines);
  }

  Future<T> _dispatch<T>(ConsoleEvent event) {
    final completer = Completer<T>();

    final ConsoleEvent enriched;
    switch (event) {
      case CreatePipelineSession(:final projectRoot):
        enriched = CreatePipelineSession(
          projectRoot: projectRoot,
          onSuccess: (data) {
            if (!completer.isCompleted) completer.complete(data as T);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(StateError(error.message));
            }
          },
        );
      case RunPipelineCommand(:final sessionId, :final command):
        enriched = RunPipelineCommand(
          sessionId: sessionId,
          command: command,
          onSuccess: (data) {
            if (!completer.isCompleted) completer.complete(data as T);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(StateError(error.message));
            }
          },
        );
      case LogPipelineLine(
        :final sessionId,
        :final stream,
        :final text,
        :final kind,
      ):
        enriched = LogPipelineLine(
          sessionId: sessionId,
          stream: stream,
          text: text,
          kind: kind,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete(null as T);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(StateError(error.message));
            }
          },
        );
      case CancelPipelineCommand(:final sessionId):
        enriched = CancelPipelineCommand(
          sessionId: sessionId,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete(null as T);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(StateError(error.message));
            }
          },
        );
      case ClosePipelineSession(:final sessionId):
        enriched = ClosePipelineSession(
          sessionId: sessionId,
          onSuccess: (_) {
            if (!completer.isCompleted) completer.complete(null as T);
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(StateError(error.message));
            }
          },
        );
      case _:
        return Future.error(StateError('Unsupported pipeline console event.'));
    }

    _bloc.add(enriched);
    return completer.future;
  }
}
