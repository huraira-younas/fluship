part of 'console_bloc.dart';

class ConsoleState extends BaseBlocState {
  const ConsoleState({
    required this.activeSessionId,
    required this.nextTerminalIndex,
    required this.projectRoot,
    required this.sessions,
    super.loading = false,
    super.error,
  });

  final List<ConsoleSession> sessions;
  final String? activeSessionId;
  final String? projectRoot;
  final int nextTerminalIndex;

  factory ConsoleState.empty() => const ConsoleState(
    activeSessionId: null,
    nextTerminalIndex: 1,
    projectRoot: null,
    sessions: [],
  );

  bool get canAddSession => sessions.length < ConsoleLimits.maxSessions;

  ConsoleSession? get activeSession {
    final id = activeSessionId;
    if (id == null) return null;
    return sessionById(id);
  }

  ConsoleSession? sessionById(String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    activeSessionId,
    nextTerminalIndex,
    projectRoot,
    sessions,
    loading,
    error,
  ];

  @override
  ConsoleState copyWith({
    List<ConsoleSession>? sessions,
    String? activeSessionId,
    String? projectRoot,
    int? nextTerminalIndex,
    CustomState? error,
    bool? loading,
  }) {
    return ConsoleState(
      activeSessionId: activeSessionId ?? this.activeSessionId,
      nextTerminalIndex: nextTerminalIndex ?? this.nextTerminalIndex,
      projectRoot: projectRoot ?? this.projectRoot,
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
