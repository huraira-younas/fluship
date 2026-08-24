import 'dart:convert';
import 'dart:io';

import 'io_helpers.dart';
import 'log_pdf.dart';
import 'progress.dart';
import 'whatsapp.dart';

class PipelineReport {
  const PipelineReport({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.success,
    required this.steps,
    this.attachments = const [],
    this.errorExcerpt = '',
  });

  final String appName;
  final String version;
  final String buildNumber;
  final bool success;
  final String steps;
  final List<String> attachments;
  final String errorExcerpt;

  String get versionLabel {
    if (version.trim().isEmpty) return '';
    final build = buildNumber.trim();
    return build.isEmpty ? 'v$version' : 'v$version+$build';
  }
}

void writeReportPdf({required String path, required PipelineReport report}) {
  File(path).writeAsBytesSync(buildReportPdf(report));
}

List<int> buildReportPdf(PipelineReport report) {
  final safe = PipelineReport(
    appName: report.appName,
    version: report.version,
    buildNumber: report.buildNumber,
    success: report.success,
    steps: report.steps,
    attachments: report.attachments,
    errorExcerpt: redactSecrets(report.errorExcerpt),
  );
  final jobs = parseStepStatuses(safe.steps);
  final pages = <_Page>[];
  pages.addAll(_summaryPages(safe, jobs));
  if (pages.isEmpty) pages.add(_Page()..titleBar(report, 'Report'));
  return _assemble(pages);
}

List<_Page> _summaryPages(PipelineReport report, List<ParsedStepStatus> jobs) {
  final pages = <_Page>[];
  var page = _Page()..titleBar(report, report.success ? 'SUCCESS' : 'FAILED');
  var y = 668.0;

  void ensure({required double need}) {
    if (y - need >= 56) return;
    page.footer(pages.length + 1);
    pages.add(page);
    page = _Page()..titleBar(report, report.success ? 'SUCCESS' : 'FAILED');
    y = 668;
  }

  page.section('Overview', 40, y);
  y -= 22;
  page.meta(report, 40, y);
  y -= 36;

  if (report.errorExcerpt.trim().isNotEmpty) {
    ensure(need: 56);
    page.section('Issue', 40, y);
    y -= 18;
    final issue = wrapPdfLines(
      stripLogNoise(report.errorExcerpt),
      width: 78,
    ).take(3);
    page.callout(40, y - (issue.length * 13) - 10, 532, issue.length * 13 + 16);
    var iy = y - 8;
    for (final line in issue) {
      page.text(line, 50, iy - 12, 10, ink, false);
      iy -= 13;
    }
    y = iy - 16;
  }

  ensure(need: 40);
  page.section('Jobs', 40, y);
  y -= 8;
  page.tableHead(40, y - 18);
  y -= 22;

  if (jobs.isEmpty) {
    page.text('No job results were recorded.', 48, y - 12, 10, muted, false);
    y -= 28;
  } else {
    var row = 0;
    for (final job in jobs) {
      ensure(need: 22);
      page.tableRow(
        40,
        y - 18,
        index: row + 1,
        name: humanStepName(job.id),
        mark: boardMark(job.result),
        time: job.duration,
        alt: row.isOdd,
      );
      y -= 20;
      row += 1;
    }
  }

  final files = [
    for (final path in report.attachments)
      if (path.trim().isNotEmpty) fileNameOf(path),
  ];
  if (files.isNotEmpty) {
    y -= 12;
    ensure(need: 28 + files.length * 14.0);
    page.section('Files', 40, y);
    y -= 18;
    for (final name in files) {
      page.text(name, 48, y - 10, 10, ink, false);
      y -= 14;
    }
  }

  page.footer(pages.length + 1);
  pages.add(page);
  return pages;
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);
  final double r;
  final double g;
  final double b;
  String get pdf =>
      '${r.toStringAsFixed(3)} ${g.toStringAsFixed(3)} ${b.toStringAsFixed(3)}';
}

const navy = _Rgb(0.071, 0.086, 0.118);
const blue = _Rgb(0.298, 0.553, 1.0);
const green = _Rgb(0.176, 0.769, 0.510);
const red = _Rgb(1.0, 0.361, 0.478);
const ink = _Rgb(0.102, 0.118, 0.157);
const muted = _Rgb(0.420, 0.463, 0.545);
const white = _Rgb(1, 1, 1);
const paper = _Rgb(0.973, 0.976, 0.984);
const line = _Rgb(0.890, 0.902, 0.922);

class _Page {
  final StringBuffer buf = StringBuffer();

  void fill(double x, double y, double w, double h, _Rgb color) {
    buf.writeln('${color.pdf} rg');
    buf.writeln('${_n(x)} ${_n(y)} ${_n(w)} ${_n(h)} re f');
  }

  void text(
    String value,
    double x,
    double y,
    double size,
    _Rgb color,
    bool bold,
  ) {
    final safe = pdfSafeText(value);
    if (safe.isEmpty) return;
    buf
      ..writeln('BT')
      ..writeln('/${bold ? 'F2' : 'F1'} ${_n(size)} Tf')
      ..writeln('${color.pdf} rg')
      ..writeln('1 0 0 1 ${_n(x)} ${_n(y)} Tm')
      ..writeln('(${_escape(safe)}) Tj')
      ..writeln('ET');
  }

  void titleBar(PipelineReport report, String badge) {
    fill(0, 704, 612, 88, navy);
    text('FLUSHIP PIPELINE', 40, 764, 9, blue, true);
    final name = report.appName.trim().isEmpty ? 'App' : report.appName.trim();
    text(name, 40, 738, 22, white, true);
    final version = report.versionLabel;
    if (version.isNotEmpty) {
      text(version, 40, 716, 11, const _Rgb(0.75, 0.80, 0.90), false);
    }
    final ok = report.success;
    final badgeColor = ok ? green : red;
    fill(470, 736, 102, 22, badgeColor);
    text(badge, 482, 743, 10, white, true);
  }

  void section(String label, double x, double y) {
    text(label.toUpperCase(), x, y, 9, blue, true);
  }

  void meta(PipelineReport report, double x, double y) {
    final jobs = parseStepStatuses(report.steps);
    final okCount = jobs.where((j) => boardMark(j.result) == 'DONE').length;
    final bits = <String>[
      if (report.versionLabel.isNotEmpty) report.versionLabel,
      '${jobs.length} jobs',
      '$okCount done',
      report.success ? 'run succeeded' : 'run failed',
    ];
    text(bits.join('   ·   '), x, y, 11, ink, false);
  }

  void callout(double x, double y, double w, double h) {
    fill(x, y, w, h, const _Rgb(1, 0.945, 0.949));
    fill(x, y, 4, h, red);
  }

  void tableHead(double x, double y) {
    fill(x, y, 532, 18, paper);
    text('#', x + 8, y + 5, 8, muted, true);
    text('JOB', x + 32, y + 5, 8, muted, true);
    text('RESULT', x + 360, y + 5, 8, muted, true);
    text('TIME', x + 450, y + 5, 8, muted, true);
  }

  void tableRow(
    double x,
    double y, {
    required int index,
    required String name,
    required String mark,
    required String time,
    required bool alt,
  }) {
    if (alt) fill(x, y, 532, 18, paper);
    text('$index', x + 8, y + 5, 9, muted, false);
    text(_clip(name, 46), x + 32, y + 5, 10, ink, false);
    final markColor = switch (mark) {
      'FAIL' => red,
      'SKIP' => muted,
      _ => green,
    };
    text(mark, x + 360, y + 5, 9, markColor, true);
    if (time.isNotEmpty) text(time, x + 450, y + 5, 9, muted, false);
  }

  void footer(int pageHint) {
    fill(40, 36, 532, 0.6, line);
    text('Fluship pipeline report', 40, 22, 8, muted, false);
    if (pageHint > 0) {
      text('Page $pageHint', 520, 22, 8, muted, false);
    }
  }
}

List<int> _assemble(List<_Page> pages) {
  final chunks = <List<int>>[latin1.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n')];
  final offsets = <int>[0];
  var cursor = chunks.fold<int>(0, (sum, c) => sum + c.length);

  void addObj(List<int> bytes) {
    offsets.add(cursor);
    chunks.add(bytes);
    cursor += bytes.length;
  }

  List<int> obj(int id, String body) =>
      latin1.encode('$id 0 obj\n$body\nendobj\n');

  addObj(obj(1, '<< /Type /Catalog /Pages 2 0 R >>'));
  final kids = [
    for (var i = 0; i < pages.length; i++) '${3 + i * 2} 0 R',
  ].join(' ');
  addObj(obj(2, '<< /Type /Pages /Count ${pages.length} /Kids [ $kids ] >>'));

  final fontRegular = 3 + pages.length * 2;
  final fontBold = fontRegular + 1;

  for (var i = 0; i < pages.length; i++) {
    final pageId = 3 + i * 2;
    final contentId = pageId + 1;
    final content = pages[i].buf.toString();
    final bytes = latin1.encode(content);
    addObj(
      obj(
        pageId,
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Contents $contentId 0 R /Resources << /Font << '
        '/F1 $fontRegular 0 R /F2 $fontBold 0 R >> >> >>',
      ),
    );
    addObj(
      latin1.encode(
        '$contentId 0 obj\n<< /Length ${bytes.length} >>\nstream\n$content\nendstream\nendobj\n',
      ),
    );
  }
  addObj(
    obj(fontRegular, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'),
  );
  addObj(
    obj(
      fontBold,
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>',
    ),
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

String stripLogNoise(String raw) {
  var text = pdfSafeText(raw);
  text = text.replaceAll(RegExp(r'\x1B\[[0-9;]*[A-Za-z]'), '');
  text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  final out = <String>[];
  for (final line in text.replaceAll('\r\n', '\n').split('\n')) {
    final trimmed = line.trimRight();
    if (_looksLikePdfJunk(trimmed)) continue;
    out.add(trimmed);
  }
  return out.join('\n');
}

bool _looksLikePdfJunk(String line) {
  if (line.startsWith('%PDF') || line.startsWith('%%EOF')) return true;
  if (RegExp(r'^\d+ 0 obj').hasMatch(line)) return true;
  if (line == 'BT' || line == 'ET' || line == 'T*' || line == 'endobj') {
    return true;
  }
  return RegExp(r'^(/F\d+\s+\d+\s+Tf|stream|endstream)').hasMatch(line);
}

String _escape(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}

String _clip(String text, int max) {
  if (text.length <= max) return text;
  return '${text.substring(0, max - 1)}.';
}

String _n(double value) => value.toStringAsFixed(2);
