final _percentRe = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*%');

int? parseTransporterPercent(String line) {
  final match = _percentRe.firstMatch(line);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null || value < 0 || value > 100) return null;
  return value.round();
}
