import '../catalog/catalog.dart';

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
        boardMark(step.result),
        humanStepName(step.id),
        if (step.duration.isNotEmpty) step.duration,
      ].join('  '),
  ].join('\n');
}

String formatProgressBoard({
  required List<String> selected,
  required List<String> done,
  String? current,
  Map<String, String> results = const {},
  Map<String, String> times = const {},
  String appName = '',
  String version = '',
  String buildNumber = '',
  String uploadLabel = '',
  String note = '',
}) {
  final title = _boardTitle(
    appName: appName,
    version: version,
    buildNumber: buildNumber,
  );
  if (selected.isEmpty) {
    return '$title\n${_rule()}\n  No jobs selected.\n${_rule()}';
  }

  final doneSet = {for (final id in done) normalizeStepId(id)};
  final now = current == null || current.isEmpty
      ? ''
      : normalizeStepId(current);
  final rows = <String>[];
  var finished = 0;
  var index = 1;
  for (final raw in selected) {
    final id = normalizeStepId(raw);
    final isNow = now == id;
    final isDone = doneSet.contains(id);
    if (isDone && !isNow) finished += 1;
    final mark = boardState(
      isNow: isNow,
      isDone: isDone,
      result: results[id] ?? '',
    );
    final time = times[id] ?? '';
    final name = _fit(humanStepName(id), 34);
    final line = StringBuffer('  ${index.toString().padLeft(2)}  $mark  $name');
    if (time.isNotEmpty) line.write('  $time');
    rows.add(line.toString());
    index += 1;
  }

  final nowName = now.isEmpty ? '-' : humanStepName(now);
  return [
    title,
    _rule(),
    ...rows,
    _rule(),
    '  $finished/${selected.length} done    now: $nowName',
    if (uploadLabel.trim().isNotEmpty) '  upload: ${uploadLabel.trim()}',
    if (note.trim().isNotEmpty) '  note: ${note.trim()}',
  ].join('\n');
}

String boardState({
  required bool isNow,
  required bool isDone,
  required String result,
}) {
  if (isNow) return 'NOW ';
  if (!isDone) return 'WAIT';
  final mark = boardMark(result);
  return mark.length >= 4 ? mark.substring(0, 4) : mark.padRight(4);
}

String boardMark(String result) {
  switch (result.toLowerCase()) {
    case 'ok':
    case 'done':
    case 'success':
    case '':
      return 'DONE';
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

String _boardTitle({
  required String appName,
  required String version,
  required String buildNumber,
}) {
  final bits = <String>['FLUSHIP'];
  if (appName.trim().isNotEmpty) bits.add(appName.trim());
  if (version.trim().isNotEmpty) {
    final build = buildNumber.trim();
    bits.add(build.isEmpty ? 'v$version' : 'v$version+$build');
  }
  return bits.join('  ');
}

String _rule() => '  ----------------------------------------------';

String _fit(String text, int width) {
  if (text.length <= width) return text.padRight(width);
  if (width <= 1) return text.substring(0, width);
  return '${text.substring(0, width - 1)}.';
}
