import 'dart:convert';
import 'dart:io';

import 'pipeline_picker/apk_collect.dart';
import 'pipeline_picker/host_actions.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/log_pdf.dart';
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
    stderr.writeln(reasonNumber);
    exitCode = 64;
    return;
  }

  Directory(parsed.outputDir).createSync(recursive: true);
  final logFile = File(parsed.logPath);
  final logText = logFile.existsSync() ? logFile.readAsStringSync() : '';
  final excerpt = parsed.errorExcerpt.isNotEmpty
      ? parsed.errorExcerpt
      : errorExcerptFromLog(logText);
  final pdfPath = pathJoin(parsed.outputDir, 'pipeline-report.pdf');
  final apks = collectShareApks(
    outputDir: parsed.outputDir,
    projectPath: parsed.project,
  );
  final attachments = <String>[pdfPath, ...apks];
  final title =
      'Fluship ${parsed.appName} v${parsed.version}+${parsed.buildNumber} '
      '${parsed.success ? 'success' : 'failed'}';
  final caption = buildWhatsAppCaption(
    appName: parsed.appName,
    version: parsed.version,
    buildNumber: parsed.buildNumber,
    success: parsed.success,
    steps: parsed.steps,
    errorExcerpt: excerpt,
    attachments: attachments,
  );
  writeLogPdf(path: pdfPath, title: title, body: '$caption\n\n$logText');

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

  final uri = Platform.isMacOS
      ? whatsappDesktopUri(number: parsed.number, text: chatText)
      : whatsappWebUri(number: parsed.number, text: chatText);
  await openBrowser(uri);

  if (!Platform.isMacOS) {
    stdout.writeln(
      'Opened wa.me. Attach the PDF and APKs from ${parsed.outputDir}.',
    );
    return;
  }

  final attached = await attachFilesOnMac(attachments);
  if (attached) {
    stdout.writeln(
      'PDF and APKs were pasted into WhatsApp. Check the compose box, then tap Send.',
    );
    return;
  }

  await Process.run('open', ['-R', pdfPath]);
  stdout.writeln(
    'WhatsApp chat is open with a short status. The PDF was not pasted. '
    'The PDF is $pdfPath. Drag pipeline-report.pdf and any APKs into the chat. '
    'Do not send the chat text without the PDF.',
  );
}

const reasonNumber = 'Enter a valid WhatsApp number.';

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
  );
}

String errorExcerptFromLog(String log) {
  final redacted = redactSecrets(log);
  for (final line in redacted.split('\n').reversed) {
    final lower = line.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('fail') ||
        lower.contains('exception')) {
      return line.trim();
    }
  }
  return '';
}

Future<bool> attachFilesOnMac(List<String> files) async {
  final existing = [
    for (final path in files)
      if (File(path).existsSync()) path,
  ];
  if (existing.isEmpty) return false;

  try {
    await Future<void>.delayed(const Duration(seconds: 2));
    await Process.run('osascript', [
      '-e',
      'tell application "WhatsApp" to activate',
    ]);
    await Future<void>.delayed(const Duration(seconds: 2));

    final copied =
        await _copyFilesToPasteboard(existing) ||
        await _copyFilesWithFinder(existing);
    if (!copied) {
      return await _openFilesInWhatsApp(existing);
    }

    final pasted = await Process.run('osascript', [
      '-e',
      'tell application "WhatsApp" to activate\n'
          'delay 0.8\n'
          'tell application "System Events" to keystroke "v" using command down',
    ]);
    if (pasted.exitCode != 0) {
      return await _openFilesInWhatsApp(existing);
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> _copyFilesToPasteboard(List<String> files) async {
  final script = File(
    '${Directory.systemTemp.path}/fluship-whatsapp-pasteboard.js',
  );
  script.writeAsStringSync('''
ObjC.import("AppKit");
const paths = ${jsonEncode(files)};
const pb = \$.NSPasteboard.generalPasteboard;
pb.clearContents;
const urls = \$.NSMutableArray.array;
for (const path of paths) {
  urls.addObject(\$.NSURL.fileURLWithPath(path));
}
pb.writeObjects(urls);
''');
  final result = await Process.run('osascript', [
    '-l',
    'JavaScript',
    script.path,
  ]);
  return result.exitCode == 0;
}

Future<bool> _copyFilesWithFinder(List<String> files) async {
  final lines = [
    'set theFiles to {}',
    for (final path in files)
      'set end of theFiles to POSIX file ${jsonEncode(path)}',
    'set the clipboard to theFiles',
  ];
  final result = await Process.run('osascript', ['-e', lines.join('\n')]);
  return result.exitCode == 0;
}

Future<bool> _openFilesInWhatsApp(List<String> files) async {
  var any = false;
  for (final path in files) {
    final opened = await Process.run('open', ['-a', 'WhatsApp', path]);
    if (opened.exitCode == 0) any = true;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  return any;
}
