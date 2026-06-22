import 'dart:io' show Platform, Process, ProcessSignal;

class ProcessKillResult {
  const ProcessKillResult({
    required this.success,
    this.message = '',
    required this.pid,
  });

  final String message;
  final bool success;
  final int pid;
}

class ProcessKiller {
  const ProcessKiller();

  Future<ProcessKillResult> kill(int pid) async {
    if (pid <= 0) {
      return ProcessKillResult(
        message: 'Invalid process id.',
        success: false,
        pid: pid,
      );
    }

    try {
      final sent = Process.killPid(pid, ProcessSignal.sigterm);
      if (!sent) {
        return ProcessKillResult(
          message: 'Could not signal process $pid.',
          success: false,
          pid: pid,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
      Process.killPid(pid, ProcessSignal.sigkill);

      return ProcessKillResult(success: true, pid: pid);
    } catch (error) {
      return ProcessKillResult(
        message: error.toString(),
        success: false,
        pid: pid,
      );
    }
  }

  Future<List<ProcessKillResult>> killAll(Iterable<int> pids) async {
    final results = <ProcessKillResult>[];
    for (final pid in pids) {
      results.add(await kill(pid));
    }
    return results;
  }

  static bool get isSupported =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}
