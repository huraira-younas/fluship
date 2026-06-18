import 'dart:async' show Completer, StreamSubscription;
import 'dart:io' show Directory, Platform, Process;
import 'dart:convert' show utf8;

import '../exceptions/console_shell_exceptions.dart';
import '../parsing/marker_shell_output_parser.dart';
import '../contracts/shell_output_parser.dart';
import '../models/shell_parse_result.dart';
import '../models/shell_run_result.dart';
import '../contracts/shell_runner.dart';

abstract base class BaseShellRunner implements IShellRunner {
  BaseShellRunner({required this._parser});

  final IShellOutputParser _parser;

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
  String? _lastCwd;

  @override
  bool get isRunning => _running;

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

    final process = await Process.start(
      executable,
      startupArguments,
      workingDirectory: workingDirectory,
      environment: Platform.environment,
    );
    _process = process;

    _stdoutSub = process.stdout.transform(utf8.decoder).listen(
      onError: _handleStdoutError,
      cancelOnError: false,
      _handleStdoutChunk,
    );

    _stderrSub = process.stderr.transform(utf8.decoder).listen(
      onError: _handleStderrError,
      cancelOnError: false,
      _handleStderrChunk,
    );
  }

  void _handleStdoutChunk(String chunk) {
    if (!_isAlive || _disposed || !_running) return;
    _handleParse(_parser.feed(chunk));
  }

  void _handleStdoutError(Object error) {
    if (!_isAlive || _disposed || !_running) return;
    _onStderr?.call(error.toString());
  }

  void _handleStderrChunk(String chunk) {
    if (!_isAlive || _disposed || !_running) return;
    _onStderr?.call(chunk);
  }

  void _handleStderrError(Object error) {
    if (!_isAlive || _disposed || !_running) return;
    _onStderr?.call(error.toString());
  }

  @override
  Future<ShellRunResult> run(
    String command, {
    required void Function(String cwd) onCwdChanged,
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
  }) async {
    if (_disposed) throw const ShellDisposedException();
    final process = _process;

    if (process == null) throw const ShellDisposedException();
    if (_running) throw const ShellBusyException();

    _runCompleter = Completer<ShellRunResult>();
    _onCwdChanged = onCwdChanged;
    _onStdout = onStdout;
    _onStderr = onStderr;
    _cancelled = false;
    _parser.reset();
    _running = true;

    process.stdin.writeln(wrapCommand(command));
    await process.stdin.flush();

    try {
      return await _runCompleter!.future;
    } finally {
      _runCompleter = null;
      _onCwdChanged = null;
      _onStdout = null;
      _onStderr = null;
      _running = false;
    }
  }

  void _handleParse(ShellParseResult result) {
    if (!_isAlive || _disposed || !_running) return;

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

  @override
  Future<void> cancel() async {
    if (!_running) return;
    _cancelled = true;
    final parser = _parser;
    if (parser is MarkerShellOutputParser) parser.markCancelled();

    try {
      _process?.stdin.writeln('\x03');
      await _process?.stdin.flush();
    } catch (_) {
      await _killProcess();
    }

    _completeRun(
      ShellRunResult(exitCode: -1, wasCancelled: true, cwd: _lastCwd),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_running) {
      _completeRun(
        ShellRunResult(exitCode: -1, wasCancelled: true, cwd: _lastCwd),
      );
    }

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _onCwdChanged = null;
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
