String formatPipelineDuration(Duration duration) {
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
