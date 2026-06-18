import 'package:fluship/services/console/contracts/shell_runner.dart';
import 'package:fluship/services/console/console_session_pool.dart';
import 'package:fluship/services/console/exceptions/console_shell_exceptions.dart';
import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/services/console/runners/shell_runner_factory.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShellRunner implements IShellRunner {
  var started = false;
  var disposed = false;
  var running = false;
  String? lastCommand;

  @override
  bool get isRunning => running;

  @override
  Future<void> cancel() async {
    running = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    running = false;
  }

  @override
  Future<ShellRunResult> run(
    String command, {
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
    required void Function(String cwd) onCwdChanged,
  }) async {
    lastCommand = command;
    running = true;
    onStdout('ok\n');
    onCwdChanged('/project');
    running = false;
    return const ShellRunResult(exitCode: 0, cwd: '/project');
  }

  @override
  Future<void> start({required String workingDirectory}) async {
    started = true;
  }
}

class FakeShellRunnerFactory extends ShellRunnerFactory {
  FakeShellRunnerFactory(this.runner);

  final FakeShellRunner runner;

  @override
  IShellRunner build() => runner;
}

void main() {
  group('ConsoleSessionPool', () {
    late FakeShellRunner runner;
    late ConsoleSessionPool pool;

    setUp(() {
      runner = FakeShellRunner();
      pool = ConsoleSessionPool(factory: FakeShellRunnerFactory(runner));
    });

    test('creates and disposes session', () async {
      await pool.create(sessionId: 'a', projectRoot: r'C:\project');
      expect(pool.hasSession('a'), isTrue);
      expect(runner.started, isTrue);

      await pool.dispose('a');
      expect(pool.hasSession('a'), isFalse);
      expect(runner.disposed, isTrue);
    });

    test('enforces max sessions', () async {
      await pool.create(sessionId: '1', projectRoot: r'C:\p');
      await pool.create(sessionId: '2', projectRoot: r'C:\p');
      await pool.create(sessionId: '3', projectRoot: r'C:\p');

      expect(
        () => pool.create(sessionId: '4', projectRoot: r'C:\p'),
        throwsA(isA<SessionLimitException>()),
      );
    });

    test('runs command on session', () async {
      await pool.create(sessionId: 'a', projectRoot: r'C:\project');
      final output = <String>[];

      final result = await pool.run(
        'a',
        'echo hi',
        onStdout: output.add,
        onStderr: (_) {},
        onCwdChanged: (_) {},
      );

      expect(result.exitCode, 0);
      expect(runner.lastCommand, 'echo hi');
      expect(output.join(), contains('ok'));
    });
  });
}
