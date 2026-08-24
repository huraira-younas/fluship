import 'dart:convert';
import 'dart:io';

import '../../report/log_pdf.dart';
import '../../report/report_pdf.dart';

void main() {
  final bytes = buildReportPdf(
    const PipelineReport(
      appName: 'Reelstay',
      version: '1.8.2',
      buildNumber: '8205',
      success: true,
      steps: 'Clean:ok:10s,BuildAab:fail:3m',
      attachments: ['/tmp/pipeline-report.pdf', '/tmp/app.apk'],
      errorExcerpt: 'appPassword=secret failed to sign',
    ),
  );
  _check(looksLikePdf(bytes), 'pdf header');
  final text = latin1.decode(bytes, allowInvalid: true);
  _check(text.contains('FLUSHIP'), 'brand');
  _check(text.contains('Reelstay'), 'app');
  _check(text.contains('SUCCESS'), 'badge');
  _check(text.contains('Clean old build files'), 'job name');
  _check(text.contains('pipeline-report.pdf'), 'file name');
  _check(!text.contains('appPassword=secret'), 'no raw secret');
  _check(text.contains('[redacted]'), 'redacted');
  _check(!text.contains('Command log'), 'no log dump');
  _check(!text.contains('real log line'), 'no raw log');
  _check(!text.contains('\u2014'), 'em-dash');

  final cleaned = stripLogNoise('BT\n/F1 10 Tf\nhello\n%PDF-1.4');
  _check(cleaned.contains('hello'), 'keep text');
  _check(!cleaned.contains('%PDF'), 'drop pdf junk');
  _check(!cleaned.split('\n').contains('BT'), 'drop BT');

  final file = File(
    '${Directory.systemTemp.path}/fluship-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  writeReportPdf(
    path: file.path,
    report: const PipelineReport(
      appName: 'Demo',
      version: '1.0.0',
      buildNumber: '1',
      success: false,
      steps: 'Clean:ok:1s',
    ),
  );
  _check(looksLikePdf(file.readAsBytesSync()), 'written');
  file.deleteSync();
  stdout.writeln('report pdf tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
