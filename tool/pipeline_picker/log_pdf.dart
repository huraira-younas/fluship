import 'dart:convert';
import 'dart:io';

List<int> buildLogPdf({required String title, required String body}) {
  final lines = wrapPdfLines('$title\n\n$body');
  const linesPerPage = 56;
  final pages = <List<String>>[];
  for (var i = 0; i < lines.length; i += linesPerPage) {
    final end = (i + linesPerPage < lines.length)
        ? i + linesPerPage
        : lines.length;
    pages.add(lines.sublist(i, end));
  }
  if (pages.isEmpty) pages.add(const <String>['']);

  final fontId = 3 + pages.length * 2;
  final chunks = <List<int>>[];
  chunks.add(latin1.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));

  final offsets = <int>[0];
  var cursor = chunks.fold<int>(0, (sum, c) => sum + c.length);

  void addObj(List<int> bytes) {
    offsets.add(cursor);
    chunks.add(bytes);
    cursor += bytes.length;
  }

  addObj(_obj(1, '<< /Type /Catalog /Pages 2 0 R >>'));
  final kids = [
    for (var i = 0; i < pages.length; i++) '${3 + i * 2} 0 R',
  ].join(' ');
  addObj(_obj(2, '<< /Type /Pages /Count ${pages.length} /Kids [ $kids ] >>'));

  for (var i = 0; i < pages.length; i++) {
    final pageId = 3 + i * 2;
    final contentId = pageId + 1;
    addObj(
      _obj(
        pageId,
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Contents $contentId 0 R /Resources << /Font << /F1 $fontId 0 R >> >> >>',
      ),
    );
    addObj(_streamObj(contentId, _pageStream(pages[i], i + 1, pages.length)));
  }
  addObj(
    _obj(fontId, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'),
  );

  final xrefAt = cursor;
  final buf = StringBuffer('xref\n0 ${offsets.length}\n');
  buf.write('0000000000 65535 f \n');
  for (var i = 1; i < offsets.length; i++) {
    buf.write('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
  }
  buf.write(
    'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xrefAt\n%%EOF\n',
  );
  chunks.add(latin1.encode(buf.toString()));
  return chunks.expand((c) => c).toList();
}

void writeLogPdf({
  required String path,
  required String title,
  required String body,
}) {
  File(path).writeAsBytesSync(buildLogPdf(title: title, body: body));
}

bool looksLikePdf(List<int> bytes) {
  if (bytes.length < 5) return false;
  return String.fromCharCodes(bytes.take(5)) == '%PDF-';
}

List<String> wrapPdfLines(String body) {
  const width = 92;
  final out = <String>[];
  for (final raw in body.replaceAll('\r\n', '\n').split('\n')) {
    var line = raw.replaceAll('\t', '  ');
    if (line.isEmpty) {
      out.add('');
      continue;
    }
    while (line.length > width) {
      out.add(line.substring(0, width));
      line = line.substring(width);
    }
    out.add(line);
  }
  return out;
}

List<int> _obj(int id, String body) {
  return latin1.encode('$id 0 obj\n$body\nendobj\n');
}

List<int> _streamObj(int id, String content) {
  final bytes = latin1.encode(content);
  return latin1.encode(
    '$id 0 obj\n<< /Length ${bytes.length} >>\nstream\n$content\nendstream\nendobj\n',
  );
}

String _pageStream(List<String> lines, int page, int total) {
  final buf = StringBuffer()..write('BT\n/F1 10 Tf\n50 750 Td\n14 TL\n');
  for (final line in lines) {
    buf.write('(${_escape(line)}) Tj\nT*\n');
  }
  buf.write(
    'ET\nBT\n/F1 9 Tf\n50 28 Td\n(${_escape('Page $page / $total')}) Tj\nET\n',
  );
  return buf.toString();
}

String _escape(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ');
}
