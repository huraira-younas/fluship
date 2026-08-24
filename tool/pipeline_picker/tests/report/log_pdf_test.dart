import 'dart:io';

import '../../report/log_pdf.dart';

void main() {
  final wrapped = wrapPdfLines('a' * 200);
  _check(wrapped.length >= 2, 'wrap long line');

  final safe = pdfSafeText('Lahore \u2192 Peshawar \u2014 ok');
  _check(safe.contains('Lahore -> Peshawar - ok'), 'unicode to latin1');
  _check(!safe.contains('\u2014'), 'safe em-dash');

  _check(looksLikePdf('%PDF-1.4 extra'.codeUnits), 'pdf header');
  _check(!looksLikePdf('not-pdf'.codeUnits), 'reject');

  stdout.writeln('log pdf tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
