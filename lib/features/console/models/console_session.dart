import 'package:equatable/equatable.dart';

import 'console_line.dart';

class ConsoleSession extends Equatable {
  const ConsoleSession({
    required this.workingDirectory,
    required this.commandHistory,
    required this.isRunning,
    required this.title,
    required this.lines,
    required this.id,
  });

  final List<String> commandHistory;
  final List<ConsoleLine> lines;
  final String workingDirectory;
  final bool isRunning;
  final String title;
  final String id;

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
