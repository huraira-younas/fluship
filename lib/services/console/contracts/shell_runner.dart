import '../models/shell_run_result.dart';

abstract interface class IShellRunner {
  int? get processId;

  Future<void> start({required String workingDirectory});

  Future<ShellRunResult> run(
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  });

  Future<void> dispose();
  Future<void> cancel();

  bool get isRunning;
}
