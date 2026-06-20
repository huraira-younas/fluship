import '../console/models/console_line.dart';

class PipelineUtils {
  static String formatPipelineDuration(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 1000) return '${ms}ms';

    final totalSeconds = duration.inMilliseconds / 1000;
    if (totalSeconds < 60) {
      return totalSeconds >= 10
          ? '${duration.inSeconds}s'
          : '${totalSeconds.toStringAsFixed(1)}s';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  static String formatPipelineLogLines(List<ConsoleLine> lines) {
    if (lines.isEmpty) return '';

    final buffer = StringBuffer();
    for (final line in lines) {
      buffer.writeln(line.text);
    }

    return buffer.toString();
  }

  static String sanitizeProjectFolderName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'unknown';

    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String buildPipelineLogFileName({
    required String buildNumber,
    required String version,
  }) {
    final safeBuild = _sanitizeFileSegment(buildNumber);
    final safeVersion = _sanitizeFileSegment(version);

    return 'v${safeVersion}_${safeBuild}_logs.txt';
  }

  static String _sanitizeFileSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'unknown';

    return trimmed.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
