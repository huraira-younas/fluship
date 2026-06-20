String buildPipelineLogFileName({
  required String buildNumber,
  required String version,
}) {
  final safeBuild = _sanitizeFileSegment(buildNumber);
  final safeVersion = _sanitizeFileSegment(version);

  return 'v${safeVersion}_${safeBuild}_logs.txt';
}

String _sanitizeFileSegment(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'unknown';

  return trimmed.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
}
