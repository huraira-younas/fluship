import 'dart:async' show Completer;

import 'package:fluship/features/console/bloc/console_bloc.dart';
import 'package:fluship/features/console/models/console_session.dart';
import 'package:fluship/features/console/widgets/console_session_tabs.dart';
import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConsoleSessionPool implements IConsoleSessionPool {
  final created = <String>[];
  final disposed = <String>[];
  final cancelled = <String>[];

  @override
  int get sessionCount => created.length - disposed.length;

  @override
  Map<String, int> get trackedShellPids => const {};

  @override
  Set<int> get trackedShellPidSet => const {};

  @override
  bool hasSession(String sessionId) =>
      created.contains(sessionId) && !disposed.contains(sessionId);

  @override
  Future<void> create({
    required String projectRoot,
    required String sessionId,
  }) async {
    created.add(sessionId);
  }

  @override
  Future<void> dispose(String sessionId) async {
    disposed.add(sessionId);
  }

  @override
  Future<void> disposeAll() async {
    disposed.addAll(created.where((id) => !disposed.contains(id)));
  }

  @override
  Future<void> cancel(String sessionId) async {
    cancelled.add(sessionId);
  }

  @override
  Future<ShellRunResult> run(
    String sessionId,
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  }) async {
    return const ShellRunResult(exitCode: 0);
  }
}

Future<void> pumpBloc() => Future<void>.delayed(Duration.zero);

Future<T> dispatch<T>(ConsoleBloc bloc, ConsoleEvent event) {
  final completer = Completer<T>();

  if (event is CreatePipelineSession) {
    bloc.add(
      CreatePipelineSession(
        projectRoot: event.projectRoot,
        onSuccess: (data) {
          if (!completer.isCompleted) completer.complete(data as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      ),
    );
  } else if (event is ClosePipelineSession) {
    bloc.add(
      ClosePipelineSession(
        sessionId: event.sessionId,
        onSuccess: (data) {
          if (!completer.isCompleted) completer.complete(data as T);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      ),
    );
  } else {
    return Future.error(StateError('Unsupported test event.'));
  }

  return completer.future;
}

void main() {
  group('pipelineFirstSessions', () {
    test('places pipeline sessions before user sessions', () {
      final ordered = pipelineFirstSessions([
        const ConsoleSession(
          workingDirectory: '/project',
          commandHistory: [],
          isRunning: false,
          lines: [],
          title: 'Fluship T1',
          id: 'user_a',
        ),
        const ConsoleSession(
          workingDirectory: '/project',
          commandHistory: [],
          isRunning: false,
          lines: [],
          title: 'Pipeline',
          id: pipelineConsoleSessionId,
        ),
      ]);

      expect(ordered.first.id, pipelineConsoleSessionId);
      expect(ordered.last.id, 'user_a');
    });
  });

  group('canCloseConsoleTab', () {
    test('always allows closing pipeline tab', () {
      const pipeline = ConsoleSession(
        workingDirectory: '/project',
        commandHistory: [],
        isRunning: false,
        lines: [],
        title: 'Pipeline',
        id: pipelineConsoleSessionId,
      );

      expect(canCloseConsoleTab(1, pipeline), isTrue);
      expect(canCloseConsoleTab(0, pipeline), isTrue);
    });

    test('allows user tab close only when multiple user sessions exist', () {
      const user = ConsoleSession(
        workingDirectory: '/project',
        commandHistory: [],
        isRunning: false,
        lines: [],
        title: 'Fluship T1',
        id: 'user_a',
      );

      expect(canCloseConsoleTab(1, user), isFalse);
      expect(canCloseConsoleTab(2, user), isTrue);
    });
  });

  group('ConsoleBloc pipeline tab', () {
    late FakeConsoleSessionPool pool;
    late ConsoleBloc bloc;

    setUp(() {
      pool = FakeConsoleSessionPool();
      bloc = ConsoleBloc(pool: pool);
    });

    tearDown(() => bloc.close());

    test('CreatePipelineSession inserts pipeline at index 0', () async {
      bloc.add(const SyncProjectRoot(path: '/project'));
      await pumpBloc();

      expect(bloc.state.sessions, hasLength(1));
      final userSessionId = bloc.state.sessions.first.id;

      await dispatch<String>(
        bloc,
        const CreatePipelineSession(projectRoot: '/project'),
      );

      expect(bloc.state.sessions, hasLength(2));
      expect(bloc.state.sessions.first.id, pipelineConsoleSessionId);
      expect(bloc.state.sessions.last.id, userSessionId);
      expect(pool.created, contains(pipelineConsoleSessionId));
    });

    test(
      'ClosePipelineSession removes session and disposes pool entry',
      () async {
        bloc.add(const SyncProjectRoot(path: '/project'));
        await pumpBloc();

        await dispatch<String>(
          bloc,
          const CreatePipelineSession(projectRoot: '/project'),
        );

        expect(bloc.state.sessionById(pipelineConsoleSessionId), isNotNull);

        await dispatch<void>(
          bloc,
          const ClosePipelineSession(sessionId: pipelineConsoleSessionId),
        );

        expect(bloc.state.sessionById(pipelineConsoleSessionId), isNull);
        expect(pool.disposed, contains(pipelineConsoleSessionId));
        expect(bloc.state.sessions, hasLength(1));
      },
    );

    test('CloseSession ignores pipeline session id', () async {
      bloc.add(const SyncProjectRoot(path: '/project'));
      await pumpBloc();

      await dispatch<String>(
        bloc,
        const CreatePipelineSession(projectRoot: '/project'),
      );

      bloc.add(const CloseSession(sessionId: pipelineConsoleSessionId));
      await pumpBloc();

      expect(bloc.state.sessionById(pipelineConsoleSessionId), isNotNull);
      expect(pool.disposed, isEmpty);
    });
  });
}
