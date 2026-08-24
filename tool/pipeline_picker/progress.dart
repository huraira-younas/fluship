import 'catalog.dart';

class ParsedStepStatus {
  const ParsedStepStatus({
    required this.id,
    required this.result,
    required this.duration,
  });

  final String id;
  final String result;
  final String duration;
}

String normalizeStepId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toLowerCase() + trimmed.substring(1);
}

List<ParsedStepStatus> parseStepStatuses(String raw) {
  if (raw.trim().isEmpty) return const [];
  final out = <ParsedStepStatus>[];
  for (final part in raw.split(',')) {
    final bits = part.trim().split(':');
    if (bits.isEmpty || bits.first.trim().isEmpty) continue;
    final id = normalizeStepId(bits[0]);
    final result = bits.length > 1 ? bits[1].trim() : '';
    final duration = bits.length > 2 ? bits.sublist(2).join(':').trim() : '';
    out.add(ParsedStepStatus(id: id, result: result, duration: duration));
  }
  return out;
}

String humanStepName(String id) {
  final copy = Catalog.copyFor(normalizeStepId(id));
  if (copy.title != normalizeStepId(id)) return copy.title;
  final spaced = id.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
  if (spaced.isEmpty) return id;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String formatStepLines(String raw) {
  final parsed = parseStepStatuses(raw);
  if (parsed.isEmpty) return '';
  return [
    for (final step in parsed)
      [
        _resultMark(step.result),
        humanStepName(step.id),
        if (step.duration.isNotEmpty) '(${step.duration})',
      ].join(' '),
  ].join('\n');
}

String formatProgressBoard({
  required List<String> selected,
  required List<String> done,
  String? current,
  Map<String, String> results = const {},
}) {
  if (selected.isEmpty) return 'Pipeline progress\nNo steps selected.';
  final doneSet = {for (final id in done) normalizeStepId(id)};
  final now = current == null || current.isEmpty
      ? ''
      : normalizeStepId(current);
  final lines = <String>['Pipeline progress'];
  var index = 1;
  for (final raw in selected) {
    final id = normalizeStepId(raw);
    final name = humanStepName(id);
    final result = results[id] ?? '';
    String state;
    if (now == id) {
      state = 'NOW';
    } else if (doneSet.contains(id)) {
      state = result.isEmpty ? 'DONE' : result.toUpperCase();
    } else {
      state = 'WAIT';
    }
    lines.add('$index. [$state] $name');
    index += 1;
  }
  return lines.join('\n');
}

String _resultMark(String result) {
  switch (result.toLowerCase()) {
    case 'ok':
    case 'done':
    case 'success':
      return 'OK';
    case 'fail':
    case 'failed':
    case 'error':
      return 'FAIL';
    case 'skip':
    case 'skipped':
      return 'SKIP';
    default:
      return result.toUpperCase();
  }
}
