class ShellRunResult {
  const ShellRunResult({
    this.wasCancelled = false,
    required this.exitCode,
    this.cwd,
  });

  final bool wasCancelled;
  final int exitCode;
  final String? cwd;
}
