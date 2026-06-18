import 'dart:async' show Completer, StreamSubscription;
import 'dart:io' show Directory, Platform, Process;
import 'dart:convert' show utf8;

class ConsoleService {
  Process? _activeProcess;
  bool _cancelled = false;

  bool get isRunning => _activeProcess != null;

  Future<int> run({
    required void Function(String chunk) onStdout,
    required void Function(String chunk) onStderr,
    required String workingDirectory,
    required String command,
  }) async {
    if (isRunning) {
      throw StateError('A command is already running.');
    }

    final directory = Directory(workingDirectory);
    if (!directory.existsSync()) {
      throw StateError(
        'Flutter project path does not exist: $workingDirectory',
      );
    }

    _cancelled = false;
    final executable = Platform.isWindows ? 'cmd.exe' : 'sh';
    final arguments = Platform.isWindows ? ['/c', command] : ['-c', command];

    final process = await Process.start(
      workingDirectory: workingDirectory,
      environment: Platform.environment,
      executable,
      arguments,
    );
    _activeProcess = process;

    final exitCode = Completer<int>();
    final subscriptions = <StreamSubscription<String>>[];

    void listenStream(Stream<List<int>> stream, void Function(String) onData) {
      subscriptions.add(
        stream
            .transform(utf8.decoder)
            .listen(
              onError: (e) => onData(e.toString()),
              cancelOnError: false,
              onDone: () {},
              onData,
            ),
      );
    }

    listenStream(process.stdout, onStdout);
    listenStream(process.stderr, onStderr);

    process.exitCode.then((code) {
      if (!exitCode.isCompleted) exitCode.complete(code);
    });

    try {
      return await exitCode.future;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      _activeProcess = null;
    }
  }

  Future<void> cancel() async {
    final process = _activeProcess;
    if (process == null) return;

    _cancelled = true;
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

    _activeProcess = null;
  }

  bool get wasCancelled => _cancelled;
}
