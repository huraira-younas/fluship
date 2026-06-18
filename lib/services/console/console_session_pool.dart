import 'exceptions/console_shell_exceptions.dart';
import 'contracts/console_session_pool.dart';
import 'contracts/shell_runner_factory.dart';
import 'models/shell_run_result.dart';
import 'contracts/shell_runner.dart';
import 'console_limits.dart';

class ConsoleSessionPool implements IConsoleSessionPool {
  ConsoleSessionPool({required this._factory});

  final Map<String, IShellRunner> _runners = {};
  final IShellRunnerFactory _factory;

  @override
  int get sessionCount => _runners.length;

  @override
  bool hasSession(String sessionId) => _runners.containsKey(sessionId);

  @override
  Future<void> create({
    required String sessionId,
    required String projectRoot,
  }) async {
    if (_runners.containsKey(sessionId)) return;
    final max = ConsoleLimits.maxSessions;
    if (_runners.length >= max) {
      throw SessionLimitException(max);
    }

    final runner = _factory.build();
    await runner.start(workingDirectory: projectRoot);
    _runners[sessionId] = runner;
  }

  @override
  Future<void> dispose(String sessionId) async {
    final runner = _runners.remove(sessionId);
    if (runner == null) return;
    await runner.dispose();
  }

  @override
  Future<ShellRunResult> run(
    String sessionId,
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  }) async {
    final runner = _runners[sessionId];
    if (runner == null) throw ShellNotFoundException(sessionId);

    return runner.run(
      onCwdChanged: onCwdChanged,
      onStdout: onStdout,
      onStderr: onStderr,
      command,
    );
  }

  @override
  Future<void> cancel(String sessionId) async {
    final runner = _runners[sessionId];
    if (runner == null) throw ShellNotFoundException(sessionId);
    await runner.cancel();
  }

  @override
  Future<void> disposeAll() async {
    final ids = _runners.keys.toList();
    for (final id in ids) {
      await dispose(id);
    }
  }
}
