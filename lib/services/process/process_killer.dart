import 'dart:io' show Platform, Process, ProcessSignal;

class const ProcessKillResult({
  required final bool success,
  final String message = '',
  required final int pid,
});

class const ProcessKiller() {
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

      await Future.pause(const Duration(milliseconds: 400));
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
