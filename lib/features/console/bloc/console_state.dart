part of 'console_bloc.dart';

class ConsoleState extends BaseBlocState {
  const ConsoleState({
    required this.commandHistory,
    required this.projectPath,
    required this.isRunning,
    required this.lines,

    super.loading = false,
    super.error,
  });

  final List<String> commandHistory;
  final List<ConsoleLine> lines;
  final String? projectPath;
  final bool isRunning;

  factory ConsoleState.empty() => const ConsoleState(
    commandHistory: [],
    projectPath: null,
    isRunning: false,
    lines: [],
  );

  @override
  List<Object?> get props => [
    commandHistory,
    projectPath,
    isRunning,
    lines,

    loading,
    error,
  ];

  @override
  ConsoleState copyWith({
    List<String>? commandHistory,
    List<ConsoleLine>? lines,
    String? projectPath,
    bool? isRunning,

    CustomState? error,
    bool? loading,
  }) {
    return ConsoleState(
      commandHistory: commandHistory ?? this.commandHistory,
      projectPath: projectPath ?? this.projectPath,
      isRunning: isRunning ?? this.isRunning,
      loading: loading ?? this.loading,
      lines: lines ?? this.lines,
      error: error,
    );
  }
}
