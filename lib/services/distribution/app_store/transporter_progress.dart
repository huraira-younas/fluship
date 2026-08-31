final _percentRe = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%');

int? parseTransporterPercent(String line) {
  final match = _percentRe.firstMatch(line);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null || value < 0 || value > 100) return null;
  return value.round();
}

bool isTransporterNoise(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return true;

  final upper = trimmed.toUpperCase();
  if (upper.startsWith('DBG-') || upper.startsWith('[DBG')) return true;
  if (upper.startsWith('DEBUG') || upper.startsWith('TRACE')) return true;
  if (upper.contains('PKG-DBG')) return true;
  return false;
}

bool isTransporterLogLine(String line) {
  if (isTransporterNoise(line)) return false;
  final lower = line.toLowerCase();
  return lower.contains('authentication') ||
      lower.contains('unauthorized') ||
      lower.contains('rejected') ||
      lower.contains('invalid') ||
      lower.contains('unable') ||
      lower.contains('error') ||
      lower.contains('fail') ||
      lower.contains('not found');
}
