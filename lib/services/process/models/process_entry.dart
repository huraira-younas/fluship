import 'package:equatable/equatable.dart';

enum ProcessKind { active, orphan }

class const ProcessRow({
  required final String displayName,
  required final String command,
  required final int depth,
  required final ProcessKind kind,
  required final int ppid,
  required final int pid,
  final String? sessionLabel,
}) extends Equatable {
  String get kindLabel => switch (kind) {
    .active => 'Active',
    .orphan => 'Orphan',
  };

  String get kindDescription => switch (kind) {
    .active => 'Linked to a running Fluship pipeline or console shell. Killing may stop your build.',
    .orphan => 'Leftover from a previous Fluship run. No active shell owns it — safe to kill.',
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

class const RawProcessRow({
  required final String command,
  required final int ppid,
  required final int pid,
}) extends Equatable {
  @override
  List<Object?> get props => [pid, ppid, command];
}
