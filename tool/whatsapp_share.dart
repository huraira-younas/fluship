import 'dart:io';

import 'pipeline_picker/apk_collect.dart';
import 'pipeline_picker/host_actions.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/report_io.dart';
import 'pipeline_picker/report_pdf.dart';
import 'pipeline_picker/whatsapp.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final parsed = _parse(args);
  if (parsed.logPath.isEmpty || parsed.outputDir.isEmpty) {
    stderr.writeln('Missing --log or --output-dir.');
    exitCode = 64;
    return;
  }
  if (!isValidWhatsAppNumber(parsed.number)) {
    stderr.writeln('Enter a valid WhatsApp number.');
    exitCode = 64;
    return;
  }

  Directory(parsed.outputDir).createSync(recursive: true);
  final pdfPath = pathJoin(parsed.outputDir, 'pipeline-report.pdf');
  final apks = collectShareApks(
    outputDir: parsed.outputDir,
    projectPath: parsed.project,
  );
  final attachments = <String>[pdfPath, ...apks];
  final wrote = await writeHtmlReportPdf(
    logPath: parsed.logPath,
    pdfPath: pdfPath,
    appName: parsed.appName,
    version: parsed.version,
    buildNumber: parsed.buildNumber,
    success: parsed.success,
    steps: parsed.steps,
    excerpt: parsed.errorExcerpt,
    files: attachments,
  );
  if (!wrote) {
    final excerpt = parsed.errorExcerpt.isNotEmpty
        ? parsed.errorExcerpt
        : errorExcerptFromLog(readFileTail(parsed.logPath));
    writeReportPdf(
      path: pdfPath,
      report: PipelineReport(
        appName: parsed.appName,
        version: parsed.version,
        buildNumber: parsed.buildNumber,
        success: parsed.success,
        steps: parsed.steps,
        attachments: attachments,
        errorExcerpt: excerpt,
      ),
    );
  }
  if (!File(pdfPath).existsSync() || File(pdfPath).lengthSync() < 64) {
    stderr.writeln('Failed to write pipeline-report.pdf');
    exitCode = 1;
    return;
  }

  final chatText = buildWhatsAppChatText(
    appName: parsed.appName,
    version: parsed.version,
    buildNumber: parsed.buildNumber,
    success: parsed.success,
  );

  stdout.writeln('WhatsApp number: ${whatsappPhone(parsed.number)}');
  stdout.writeln('Chat text:\n$chatText');
  stdout.writeln('PDF:\n$pdfPath');
  stdout.writeln('Attachments:');
  for (final file in attachments) {
    stdout.writeln('  $file');
  }

  if (parsed.dryRun) {
    stdout.writeln('Dry run. WhatsApp was not opened.');
    return;
  }

  if (!Platform.isMacOS) {
    await openBrowser(whatsappWebUri(number: parsed.number, text: chatText));
    stdout.writeln(
      'Opened wa.me. Attach the PDF and APKs from ${parsed.outputDir}.',
    );
    return;
  }

  final result = await sendFilesOnMac(
    number: parsed.number,
    caption: chatText,
    files: attachments,
    send: parsed.send,
  );
  stdout.writeln('WhatsApp result: $result');
  if (result == 'sent' || result == 'attached') {
    stdout.writeln(
      result == 'sent'
          ? 'WhatsApp sent the PDF and APKs.'
          : 'PDF and APKs are in the WhatsApp compose box. Tap Send.',
    );
    return;
  }

  await Process.run('open', ['-R', pdfPath]);
  stderr.writeln(
    'WhatsApp did not receive the PDF. The file is $pdfPath. '
    'Grant Accessibility to Cursor, then drag pipeline-report.pdf into the chat.',
  );
  exitCode = 2;
}

const _help = '''
Share a Fluship pipeline PDF and APKs on WhatsApp.

Usage:
  dart tool/whatsapp_share.dart --log PATH --output-dir PATH [options]

Options:
  --number +923096547269
  --project PATH
  --app-name NAME
  --version 1.0.0
  --build-number 1
  --success true|false
  --steps Clean:ok:1.2s,BuildAab:fail:3m4s
  --error TEXT
  --dry-run
  --no-send
''';

class _Args {
  const _Args({
    required this.logPath,
    required this.outputDir,
    required this.project,
    required this.number,
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.success,
    required this.steps,
    required this.errorExcerpt,
    required this.dryRun,
    required this.send,
  });

  final String logPath;
  final String outputDir;
  final String project;
  final String number;
  final String appName;
  final String version;
  final String buildNumber;
  final bool success;
  final String steps;
  final String errorExcerpt;
  final bool dryRun;
  final bool send;
}

_Args _parse(List<String> args) {
  String logPath = '';
  String outputDir = '';
  String project = '';
  String number = defaultWhatsAppNumber;
  String appName = 'App';
  String version = '';
  String buildNumber = '';
  var success = true;
  String steps = '';
  String errorExcerpt = '';
  var dryRun = false;
  var send = true;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String next() => i + 1 < args.length ? args[++i] : '';
    switch (arg) {
      case '--log':
        logPath = next();
      case '--output-dir':
        outputDir = next();
      case '--project':
        project = next();
      case '--number':
        number = next();
      case '--app-name':
        appName = next();
      case '--version':
        version = next();
      case '--build-number':
        buildNumber = next();
      case '--success':
        success = next() != 'false';
      case '--steps':
        steps = next();
      case '--error':
        errorExcerpt = next();
      case '--dry-run':
        dryRun = true;
      case '--no-send':
        send = false;
    }
  }

  return _Args(
    logPath: logPath,
    outputDir: outputDir,
    project: project,
    number: number,
    appName: appName,
    version: version,
    buildNumber: buildNumber,
    success: success,
    steps: steps,
    errorExcerpt: errorExcerpt,
    dryRun: dryRun,
    send: send,
  );
}
