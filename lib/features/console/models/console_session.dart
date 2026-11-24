import 'package:equatable/equatable.dart';

import 'console_line.dart';

class const ConsoleSession({
  required final String workingDirectory,
  required final List<String> commandHistory,
  required final bool isRunning,
  required final String title,
  required final List<ConsoleLine> lines,
  required final String id,
}) extends Equatable {
  ConsoleSession copyWith({
    List<String>? commandHistory,
    String? workingDirectory,
    List<ConsoleLine>? lines,
    bool? isRunning,
    String? title,
  }) {
    return ConsoleSession(
      workingDirectory: workingDirectory ?? this.workingDirectory,
      commandHistory: commandHistory ?? this.commandHistory,
      isRunning: isRunning ?? this.isRunning,
      lines: lines ?? this.lines,
      title: title ?? this.title,
      id: id,
    );
  }

  @override
  List<Object?> get props => [
    workingDirectory,
    commandHistory,
    isRunning,
    lines,
    title,
    id,
  ];
}
