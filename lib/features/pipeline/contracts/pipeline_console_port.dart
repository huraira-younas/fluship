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
    required String text,
  });

  Future<void> disposeSession(String sessionId);
  Future<void> cancelCommand(String sessionId);
}

final class ConsoleBlocPipelinePort implements PipelineConsolePort {
  ConsoleBlocPipelinePort(this._bloc);
  final ConsoleBloc _bloc;

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
  }) {
    return _dispatch<void>(
      LogPipelineLine(sessionId: sessionId, stream: stream, text: text),
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

  Future<T> _dispatch<T>(ConsoleEvent event) {
    final completer = Completer<T>();

    ConsoleEvent enriched;
    if (event is CreatePipelineSession) {
      enriched = CreatePipelineSession(
        projectRoot: event.projectRoot,
        onSuccess: (data) {
          if (!completer.isCompleted) completer.complete(data as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } else if (event is RunPipelineCommand) {
      enriched = RunPipelineCommand(
        sessionId: event.sessionId,
        command: event.command,
        onSuccess: (data) {
          if (!completer.isCompleted) completer.complete(data as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } else if (event is LogPipelineLine) {
      enriched = LogPipelineLine(
        sessionId: event.sessionId,
        stream: event.stream,
        text: event.text,
        onSuccess: (_) {
          if (!completer.isCompleted) completer.complete(null as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } else if (event is CancelPipelineCommand) {
      enriched = CancelPipelineCommand(
        sessionId: event.sessionId,
        onSuccess: (_) {
          if (!completer.isCompleted) completer.complete(null as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } else if (event is ClosePipelineSession) {
      enriched = ClosePipelineSession(
        sessionId: event.sessionId,
        onSuccess: (_) {
          if (!completer.isCompleted) completer.complete(null as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } else {
      return Future.error(StateError('Unsupported pipeline console event.'));
    }

    _bloc.add(enriched);
    return completer.future;
  }
}
