import 'dart:async' show Completer, StreamSubscription;
import 'dart:io' show Directory, Process;
import 'dart:convert' show utf8;

import '../exceptions/console_shell_exceptions.dart';
import '../../process/process_tree_killer.dart';
import '../contracts/shell_output_parser.dart';
import '../shell_environment_resolver.dart';
import '../models/shell_parse_result.dart';
import '../models/shell_run_result.dart';
import '../contracts/shell_runner.dart';

abstract base class BaseShellRunner({
  ShellEnvironmentResolver? envResolver,
  ProcessTreeKiller? treeKiller,
  required final IShellOutputParser _parser,
}) implements IShellRunner {
  final ShellEnvironmentResolver _envResolver =
      envResolver ?? const ShellEnvironmentResolver();
  final ProcessTreeKiller _treeKiller = treeKiller ?? const ProcessTreeKiller();
  Completer<ShellRunResult>? _runCompleter;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  void Function(String cwd)? _onCwdChanged;
  void Function(String chunk)? _onStdout;
  void Function(String chunk)? _onStderr;
  Process? _process;

  var _cancelled = false;
  var _disposed = false;
  var _running = false;

  String? _workingDirectory;
  String? _lastCwd;

  @override
  bool get isRunning => _running;

  @override
  int? get processId => _process?.pid;

  bool get _isAlive => !_disposed && _process != null;

  String get executable;
  List<String> get startupArguments;
  String wrapCommand(String command);

  @override
  Future<void> start({required String workingDirectory}) async {
    if (_disposed) throw const ShellDisposedException();
    if (_process != null) return;

    final directory = Directory(workingDirectory);
    if (!directory.existsSync()) {
      throw StateError('Working directory does not exist: $workingDirectory');
    }
    _workingDirectory = workingDirectory;

    final environment = await _envResolver.resolve(
      workingDirectory: workingDirectory,
    );

    final process = await Process.start(
      executable,
      startupArguments,
      environment: environment,
      workingDirectory: workingDirectory,
    );
    _process = process;

    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen(
          onError: _handleStreamError,
          cancelOnError: false,
          _handleStdoutChunk,
        );

    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(
          onError: _handleStreamError,
          cancelOnError: false,
          _handleStderrChunk,
        );
  }

  void _handleStdoutChunk(String chunk) {
    if (!_isAlive || !_running) return;
    _handleParse(_parser.feed(chunk));
  }

  void _handleStreamError(Object error) {
    if (!_isAlive || !_running) return;
    _onStderr?.call(error.toString());
  }

  void _handleStderrChunk(String chunk) {
    if (!_isAlive || !_running) return;
    _onStderr?.call(chunk);
  }

  @override
  Future<ShellRunResult> run(
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  }) async {
    if (_disposed) throw const ShellDisposedException();
    if (_running) throw const ShellBusyException();

    // A cancel ends the shell, so the next command gets a new one.
    if (_process == null) {
      final directory = _restartDirectory;
      if (directory == null) throw const ShellDisposedException();
      await start(workingDirectory: directory);
    }

    final process = _process;
    if (process == null) throw const ShellDisposedException();

    _runCompleter = Completer<ShellRunResult>();
    _onCwdChanged = onCwdChanged;
    _onStdout = onStdout;
    _onStderr = onStderr;
    _cancelled = false;
    _parser.reset();
    _running = true;

    try {
      process.stdin.writeln(wrapCommand(command));
      await process.stdin.flush();
      return await _runCompleter!.future;
    } catch (e) {
      if (_runCompleter != null && !_runCompleter!.isCompleted) {
        _runCompleter!.complete(
          ShellRunResult(exitCode: -1, wasCancelled: false, cwd: _lastCwd),
        );
      }
      rethrow;
    } finally {
      _runCompleter = null;
      _onCwdChanged = null;
      _onStdout = null;
      _onStderr = null;
      _running = false;
    }
  }

  void _handleParse(ShellParseResult result) {
    if (!_isAlive || !_running) return;

    var exitCode = 0;

    if (result.stdoutChunk != null && result.stdoutChunk!.isNotEmpty) {
      _onStdout?.call(result.stdoutChunk!);
    }
    if (result.stderrChunk != null && result.stderrChunk!.isNotEmpty) {
      _onStderr?.call(result.stderrChunk!);
    }
    if (result.cwd != null && result.cwd!.isNotEmpty) {
      _lastCwd = result.cwd;
      _onCwdChanged?.call(result.cwd!);
    }
    if (result.exitCode != null) exitCode = result.exitCode!;

    if (result.isCommandComplete) {
      _completeRun(
        ShellRunResult(
          wasCancelled: result.wasCancelled || _cancelled,
          exitCode: exitCode,
          cwd: _lastCwd,
        ),
      );
    }
  }

  void _completeRun(ShellRunResult result) {
    if (_runCompleter == null || _runCompleter!.isCompleted) return;
    _runCompleter!.complete(result);
  }

  /// Ends the running command by ending the shell and everything it started.
  ///
  /// The shell reads from a pipe, so a Ctrl-C byte is only more input and the
  /// command would keep running. Left alive, that command would also hold up,
  /// and report its result to, whatever is run next.
  @override
  Future<void> cancel() async {
    if (!_running) return;
    _parser.markCancelled();
    _cancelled = true;

    await _stopShell();

    _completeRun(
      ShellRunResult(exitCode: -1, wasCancelled: true, cwd: _lastCwd),
    );
  }

  String? get _restartDirectory {
    final last = _lastCwd;
    if (last != null && last.isNotEmpty && Directory(last).existsSync()) {
      return last;
    }
    return _workingDirectory;
  }

  Future<void> _stopShell() async {
    final process = _process;
    if (process == null) return;
    _process = null;

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    try {
      await _treeKiller.killTree(process.pid);
    } catch (_) {}

    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      process.kill(.sigkill);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_running) {
      await _stopShell();
      _completeRun(
        ShellRunResult(exitCode: -1, wasCancelled: true, cwd: _lastCwd),
      );
    }

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _onCwdChanged = null;
    _stdoutSub = null;
    _stderrSub = null;
    _onStdout = null;
    _onStderr = null;

    try {
      await _process?.stdin.close();
    } catch (_) {}

    await _killProcess();
    _process = null;
  }

  Future<void> _killProcess() async {
    final process = _process;
    if (process == null) return;
    try {
      process.kill(.sigterm);
    } catch (_) {
      process.kill(.sigkill);
    }
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      process.kill(.sigkill);
    }
  }
}
