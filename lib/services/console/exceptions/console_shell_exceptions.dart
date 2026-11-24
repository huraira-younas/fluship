class const SessionLimitException(final int maxSessions) implements Exception {
  @override
  String toString() => 'Maximum session limit reached ($maxSessions).';
}

class const ShellDisposedException() implements Exception {
  @override
  String toString() => 'Shell session has been disposed.';
}

class const ShellNotFoundException(final String sessionId)
    implements Exception {
  @override
  String toString() => 'Shell session not found: $sessionId';
}

class const ShellBusyException() implements Exception {
  @override
  String toString() => 'Shell is already running a command.';
}
