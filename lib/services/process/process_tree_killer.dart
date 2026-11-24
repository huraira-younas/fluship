import 'dart:io' show Platform, Process, ProcessSignal;

import 'models/process_entry.dart';
import 'process_enumerator.dart';

/// Stops a process together with everything it started.
///
/// A shell on a pipe cannot be interrupted with Ctrl-C, so cancelling a
/// command means ending the shell and its children outright. Only descendants
/// of the given pid are signalled: the shell shares Fluship's process group,
/// so a group kill would take the app down with it.
class ProcessTreeKiller {
  const ProcessTreeKiller({
    this.enumerator = const ProcessEnumerator(),
    this.grace = const Duration(milliseconds: 400),
  });

  final ProcessEnumerator enumerator;

  /// Time a process gets to exit on SIGTERM before it is killed.
  final Duration grace;

  /// Pids started, directly or indirectly, by [rootPid]. Children come before
  /// their parents so a parent is never signalled while it can still spawn.
  static List<int> descendantsOf(Iterable<RawProcessRow> rows, int rootPid) {
    final childrenOf = <int, List<int>>{};
    for (final row in rows) {
      childrenOf.putIfAbsent(row.ppid, () => <int>[]).add(row.pid);
    }

    final ordered = <int>[];
    final seen = <int>{rootPid};

    void visit(int pid) {
      for (final child in childrenOf[pid] ?? const <int>[]) {
        if (!seen.add(child)) continue;
        visit(child);
        ordered.add(child);
      }
    }

    visit(rootPid);
    return ordered;
  }

  Future<void> killTree(int rootPid) async {
    if (rootPid <= 0) return;

    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/PID', '$rootPid', '/T', '/F']);
      } catch (_) {}
      return;
    }

    final rows = await enumerator.listProcesses();
    final targets = [...descendantsOf(rows, rootPid), rootPid];

    for (final pid in targets) {
      _signal(pid, ProcessSignal.sigterm);
    }

    await Future<void>.delayed(grace);

    for (final pid in targets) {
      _signal(pid, ProcessSignal.sigkill);
    }
  }

  void _signal(int pid, ProcessSignal signal) {
    try {
      Process.killPid(pid, signal);
    } catch (_) {}
  }
}
