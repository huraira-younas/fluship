part of 'console_bloc.dart';

class ConsoleState extends BaseBlocState {
  const ConsoleState({
    required this.nextTerminalIndex,
    required this.activeSessionId,
    required this.projectRoot,
    required this.sessions,
    super.loading = false,
    super.error,
  });

  final List<ConsoleSession> sessions;
  final String? activeSessionId;
  final int nextTerminalIndex;
  final String? projectRoot;

  factory ConsoleState.empty() => const ConsoleState(
    activeSessionId: null,
    nextTerminalIndex: 1,
    projectRoot: null,
    sessions: [],
  );

  bool get canAddSession =>
      sessions.where((session) => !session.id.startsWith('_pipeline_')).length <
      ConsoleLimits.maxSessions;

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
    nextTerminalIndex,
    activeSessionId,
    projectRoot,
    sessions,
    loading,
    error,
  ];

  @override
  ConsoleState copyWith({
    bool clearActiveSessionId = false,
    List<ConsoleSession>? sessions,
    bool clearProjectRoot = false,
    String? activeSessionId,
    int? nextTerminalIndex,
    String? projectRoot,
    CustomState? error,
    bool? loading,
  }) {
    return ConsoleState(
      activeSessionId: !clearActiveSessionId
          ? (activeSessionId ?? this.activeSessionId)
          : null,
      projectRoot: clearProjectRoot ? null : (projectRoot ?? this.projectRoot),
      nextTerminalIndex: nextTerminalIndex ?? this.nextTerminalIndex,
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
