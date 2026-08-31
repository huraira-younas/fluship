import 'package:fluship/features/console/models/console_line.dart';

class PipelineUtils {
  static final _folderNonAlnum = RegExp(r'[^a-z0-9]+');
  static final _pathUnsafe = RegExp(r'[<>:"/\\|?*]');
  static final _folderEdges = RegExp(r'^_|_$');
  static final _folderRepeat = RegExp(r'_+');

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
        .replaceAll(_folderNonAlnum, '_')
        .replaceAll(_folderRepeat, '_')
        .replaceAll(_folderEdges, '');
  }

  static String sanitizePathSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'unknown';

    return trimmed.replaceAll(_pathUnsafe, '_');
  }

  static String formatStepError(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Step failed without details. Check the Console tab.';
    }

    var text = message.trim();
    const prefixes = ['Exception: ', 'StateError: ', 'Bad state: '];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    return _withHint(text);
  }

  static String _withHint(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('check play') ||
        lower.contains('check app store') ||
        lower.contains('check drive') ||
        lower.contains('check the console')) {
      return text;
    }

    if (lower.contains('exit code')) {
      return '$text Check the Console tab.';
    }
    if (lower.contains('service account') ||
        (lower.contains('play') &&
            (lower.contains('403') || lower.contains('permission')))) {
      return '$text Check Play credentials in Settings.';
    }
    if (lower.contains('issuer') ||
        lower.contains('transporter') ||
        lower.contains('auth key')) {
      return '$text Check App Store credentials in Settings.';
    }
    if (lower.contains('oauth') && lower.contains('drive')) {
      return '$text Check Drive credentials in Settings.';
    }
    return text;
  }
}
