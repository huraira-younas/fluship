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

const _maxNameWidth = 34;
const _barWidth = 14;

/// How much of the run is finished. The current job never counts as done, so
/// the board and the WhatsApp ping always agree.
class BoardProgress {
  const BoardProgress({required this.done, required this.total});

  final int done;
  final int total;

  int get percent => total == 0 ? 0 : (done * 100 / total).round();

  String get label => '$done/$total done';
}

BoardProgress boardProgress({
  required List<String> selected,
  required List<String> done,
  String current = '',
}) {
  final doneSet = {for (final id in done) normalizeStepId(id)};
  final now = normalizeStepId(current);
  var finished = 0;
  for (final raw in selected) {
    final id = normalizeStepId(raw);
    if (doneSet.contains(id) && id != now) finished += 1;
  }
  return BoardProgress(done: finished, total: selected.length);
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
  String runElapsed = '',
  int maxRows = 0,
}) {
  final title = _boardTitle(
    appName: appName,
    version: version,
    buildNumber: buildNumber,
  );
  if (selected.isEmpty) {
    return _frame([
      [title],
      ['No jobs selected.'],
    ]);
  }

  final doneSet = {for (final id in done) normalizeStepId(id)};
  final now = current == null || current.isEmpty
      ? ''
      : normalizeStepId(current);
  final cells = <_BoardRow>[];
  var nowIndex = -1;
  for (final raw in selected) {
    final id = normalizeStepId(raw);
    final isNow = now == id;
    if (isNow) nowIndex = cells.length;
    cells.add(
      _BoardRow(
        index: cells.length + 1,
        mark: boardState(
          isNow: isNow,
          isDone: doneSet.contains(id),
          result: results[id] ?? '',
        ),
        name: _fit(humanStepName(id), _maxNameWidth),
        time: times[id] ?? '',
      ),
    );
  }

  final shown = _window(cells, nowIndex: nowIndex, maxRows: maxRows);
  final nameWidth = shown.fold(
    0,
    (w, row) => row.name.length > w ? row.name.length : w,
  );
  final timeWidth = shown.fold(
    0,
    (w, row) => row.time.length > w ? row.time.length : w,
  );
  final hidden = cells.length - shown.length;
  final progress = boardProgress(selected: selected, done: done, current: now);
  return _frame([
    [title],
    [
      for (final row in shown) row.render(nameWidth, timeWidth),
      if (hidden > 0) '+$hidden more',
    ],
    [
      [
        progressBar(progress.percent),
        progress.label,
        '${progress.percent}%',
        if (runElapsed.trim().isNotEmpty) 'run ${runElapsed.trim()}',
      ].join('  '),
      'now: ${now.isEmpty ? '-' : humanStepName(now)}',
      if (uploadLabel.trim().isNotEmpty) 'upload: ${uploadLabel.trim()}',
      if (note.trim().isNotEmpty) 'note: ${note.trim()}',
    ],
  ]);
}

String progressBar(int percent, {int width = _barWidth}) {
  final clamped = percent.clamp(0, 100);
  final filled = (width * clamped / 100).round().clamp(0, width);
  return '${'\u2588' * filled}${'\u2591' * (width - filled)}';
}

/// Boxes the sections so the board reads as one card in chat. Sections are
/// split by a divider, every line is padded to the widest line in the board.
String _frame(List<List<String>> sections) {
  final lines = [for (final section in sections) ...section];
  final width = lines.fold(0, (w, line) => line.length > w ? line.length : w);
  final out = <String>['\u250c${'\u2500' * (width + 2)}\u2510'];
  for (final section in sections) {
    if (section.isEmpty) continue;
    if (out.length > 1) out.add('\u251c${'\u2500' * (width + 2)}\u2524');
    for (final line in section) {
      out.add('\u2502 ${line.padRight(width)} \u2502');
    }
  }
  out.add('\u2514${'\u2500' * (width + 2)}\u2518');
  return out.join('\n');
}

class _BoardRow {
  const _BoardRow({
    required this.index,
    required this.mark,
    required this.name,
    required this.time,
  });

  final int index;
  final String mark;
  final String name;
  final String time;

  String render(int nameWidth, int timeWidth) {
    final head = '${index.toString().padLeft(2, '0')}  $mark  ';
    if (timeWidth == 0 || time.isEmpty) return '$head$name'.trimRight();
    return '$head${name.padRight(nameWidth)}  ${time.padLeft(timeWidth)}';
  }
}

/// Keeps the board short enough for a chat message while always showing the
/// current job. `maxRows` of 0 or less shows everything.
List<_BoardRow> _window(
  List<_BoardRow> rows, {
  required int nowIndex,
  required int maxRows,
}) {
  if (maxRows <= 0 || rows.length <= maxRows) return rows;
  final wanted = nowIndex < 0 ? maxRows : nowIndex + 2;
  final end = wanted.clamp(maxRows, rows.length);
  return rows.sublist(end - maxRows, end);
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

String _fit(String text, int width) {
  if (text.length <= width) return text.padRight(width);
  if (width <= 1) return text.substring(0, width);
  return '${text.substring(0, width - 1)}.';
}
