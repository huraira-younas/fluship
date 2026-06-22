import 'package:equatable/equatable.dart';

enum ProcessKind { active, orphan }

class ProcessRow extends Equatable {
  const ProcessRow({
    required this.displayName,
    required this.command,
    required this.depth,
    required this.kind,
    required this.ppid,
    required this.pid,
    this.sessionLabel,
  });

  final String? sessionLabel;
  final String displayName;
  final ProcessKind kind;
  final String command;
  final int depth;
  final int ppid;
  final int pid;

  String get kindLabel => switch (kind) {
    .active => 'Active',
    .orphan => 'Orphan',
  };

  String get kindDescription => switch (kind) {
    .active =>
      'Linked to a running Fluship pipeline or console shell. Killing may stop your build.',
    .orphan =>
      'Leftover from a previous Fluship run. No active shell owns it — safe to kill.',
  };

  @override
  List<Object?> get props => [
    sessionLabel,
    displayName,
    command,
    depth,
    ppid,
    kind,
    pid,
  ];
}

class RawProcessRow extends Equatable {
  const RawProcessRow({
    required this.command,
    required this.ppid,
    required this.pid,
  });

  final String command;
  final int ppid;
  final int pid;

  @override
  List<Object?> get props => [pid, ppid, command];
}
