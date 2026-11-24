class const ShellParseResult({
  final bool isCommandComplete = false,
  final bool wasCancelled = false,
  final String? stdoutChunk,
  final String? stderrChunk,
  final int? exitCode,
  final String? cwd,
});
