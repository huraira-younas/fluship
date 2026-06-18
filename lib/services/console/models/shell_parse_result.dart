class ShellParseResult {
  const ShellParseResult({
    this.isCommandComplete = false,
    this.wasCancelled = false,
    this.stdoutChunk,
    this.stderrChunk,
    this.exitCode,
    this.cwd,
  });

  final bool isCommandComplete;
  final String? stdoutChunk;
  final String? stderrChunk;
  final bool wasCancelled;
  final int? exitCode;
  final String? cwd;

  bool get hasOutput =>
      (stdoutChunk != null && stdoutChunk!.isNotEmpty) ||
      (stderrChunk != null && stderrChunk!.isNotEmpty);
}
