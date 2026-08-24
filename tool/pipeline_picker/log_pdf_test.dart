import 'dart:convert';
import 'dart:io';

import 'log_pdf.dart';

void main() {
  final bytes = buildLogPdf(
    title: 'Fluship Demo v1.0.0+1 failed',
    body:
        'Clean:ok\nBuildAab failed\nappPassword=secret should stay in raw log',
  );
  _check(looksLikePdf(bytes), 'pdf header');
  final text = latin1.decode(bytes, allowInvalid: true);
  _check(text.contains('Fluship Demo'), 'title in pdf');
  _check(text.contains('BuildAab failed'), 'log in pdf');
  _check(!text.contains('\u2014'), 'pdf em-dash');

  final wrapped = wrapPdfLines('a' * 200);
  _check(wrapped.length >= 2, 'wrap long line');

  final file = File(
    '${Directory.systemTemp.path}/fluship-pdf-${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  writeLogPdf(path: file.path, title: 'T', body: 'Body line');
  _check(looksLikePdf(file.readAsBytesSync()), 'written pdf');
  file.deleteSync();
  stdout.writeln('log pdf tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
