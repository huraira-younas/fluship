import '../models/shell_run_result.dart';

abstract interface class IConsoleSessionPool {
  Future<void> create({required String projectRoot, required String sessionId});

  Future<void> dispose(String sessionId);

  Future<ShellRunResult> run(
    String sessionId,
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  });

  Future<void> cancel(String sessionId);
  Future<void> disposeAll();

  bool hasSession(String sessionId);
  int get sessionCount;
}
