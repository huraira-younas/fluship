class SessionLimitException implements Exception {
  const SessionLimitException(this.maxSessions);
  final int maxSessions;

  @override
  String toString() => 'Maximum session limit reached ($maxSessions).';
}

class ShellDisposedException implements Exception {
  const ShellDisposedException();

  @override
  String toString() => 'Shell session has been disposed.';
}

class ShellNotFoundException implements Exception {
  const ShellNotFoundException(this.sessionId);

  final String sessionId;

  @override
  String toString() => 'Shell session not found: $sessionId';
}

class ShellBusyException implements Exception {
  const ShellBusyException();

  @override
  String toString() => 'Shell is already running a command.';
}
