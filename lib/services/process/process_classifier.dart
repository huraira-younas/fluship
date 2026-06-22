import 'models/process_entry.dart';
import 'process_command_label.dart';

class ProcessClassifier {
  const ProcessClassifier();

  static const _buildPatterns = [
    'flutter',
    'dart',
    'gradle',
    'java',
    'pod',
    'xcodebuild',
    'kotlin',
    'kotlinc',
    'aapt2',
  ];

  List<ProcessRow> classify({
    required Map<String, int> trackedShellPids,
    required List<RawProcessRow> rows,
    required bool showAllChildren,
    required String projectRoot,
    required int selfPid,
  }) {
    if (rows.isEmpty) return const [];

    final pidToPpid = {for (final row in rows) row.pid: row.ppid};
    final trackedSet = trackedShellPids.values.toSet();
    final sessionByPid = {
      for (final e in trackedShellPids.entries) e.value: e.key,
    };
    final normalizedRoot = projectRoot.trim();

    final excluded = <int>{selfPid, ...trackedSet};
    final results = <ProcessRow>[];

    for (final row in rows) {
      if (excluded.contains(row.pid)) continue;

      final trackedAncestor = _findTrackedAncestor(
        trackedSet: trackedSet,
        pidToPpid: pidToPpid,
        pid: row.pid,
      );

      if (trackedAncestor != null) {
        final buildRelated = _isBuildRelated(row.command);
        if (!showAllChildren && !buildRelated) continue;

        results.add(
          _toRow(
            sessionLabel: _sessionLabel(sessionByPid[trackedAncestor]),
            trackedShellPid: trackedAncestor,
            pidToPpid: pidToPpid,
            kind: .active,
            row: row,
          ),
        );
        continue;
      }

      final buildRelated = _isBuildRelated(row.command);
      final projectLinked =
          normalizedRoot.isNotEmpty && row.command.contains(normalizedRoot);

      if (buildRelated && projectLinked) {
        results.add(_toRow(row: row, pidToPpid: pidToPpid, kind: .orphan));
      }
    }

    results.sort((a, b) {
      final kindOrder = a.kind.index.compareTo(b.kind.index);
      if (kindOrder != 0) return kindOrder;
      final depthOrder = a.depth.compareTo(b.depth);
      if (depthOrder != 0) return depthOrder;
      return a.displayName.compareTo(b.displayName);
    });

    return results;
  }

  ProcessRow _toRow({
    required Map<int, int> pidToPpid,
    required RawProcessRow row,
    required ProcessKind kind,
    String? sessionLabel,
    int? trackedShellPid,
  }) {
    return ProcessRow(
      displayName: ProcessCommandLabel.displayName(row.command),
      sessionLabel: sessionLabel,
      command: row.command,
      ppid: row.ppid,
      pid: row.pid,
      kind: kind,
      depth: trackedShellPid == null
          ? 0
          : _depthFromShell(
              shellPid: trackedShellPid,
              pidToPpid: pidToPpid,
              pid: row.pid,
            ),
    );
  }

  static bool _isBuildRelated(String command) {
    final lower = command.toLowerCase();
    return _buildPatterns.any(lower.contains);
  }

  static int _depthFromShell({
    required Map<int, int> pidToPpid,
    required int shellPid,
    required int pid,
  }) {
    var current = pid;
    var depth = 0;

    while (true) {
      final parent = pidToPpid[current];
      if (parent == null || parent <= 0) return depth;
      if (parent == shellPid) return depth + 1;
      current = parent;
      depth++;
    }
  }

  static int? _findTrackedAncestor({
    required Map<int, int> pidToPpid,
    required Set<int> trackedSet,
    required int pid,
  }) {
    final visited = <int>{};
    var current = pid;

    while (visited.add(current)) {
      if (trackedSet.contains(current)) return current;
      final parent = pidToPpid[current];
      if (parent == null || parent <= 0) return null;
      current = parent;
    }

    return null;
  }

  static String _sessionLabel(String? sessionId) {
    if (sessionId == null) return 'Console';
    if (sessionId.startsWith('_pipeline_')) return 'Pipeline';
    return 'Console';
  }
}
