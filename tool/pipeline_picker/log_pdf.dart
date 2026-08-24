bool looksLikePdf(List<int> bytes) {
  if (bytes.length < 5) return false;
  return String.fromCharCodes(bytes.take(5)) == '%PDF-';
}

String pdfSafeText(String input) {
  final out = StringBuffer();
  for (final code in input.runes) {
    if (code <= 0xFF) {
      out.writeCharCode(code);
      continue;
    }
    out.write(switch (code) {
      0x2013 || 0x2014 => '-',
      0x2018 || 0x2019 => "'",
      0x201C || 0x201D => '"',
      0x2026 => '...',
      0x2190 => '<-',
      0x2192 => '->',
      0x21D2 => '=>',
      _ => '?',
    });
  }
  return out.toString();
}

List<String> wrapPdfLines(String body, {int width = 92}) {
  final out = <String>[];
  for (final raw in pdfSafeText(body).replaceAll('\r\n', '\n').split('\n')) {
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
