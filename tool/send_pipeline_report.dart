import 'dart:convert';
import 'dart:io';

import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path/path.dart' as p;

import 'pipeline_picker/io_helpers.dart';

Future<void> main(List<String> args) async {
  final parsed = parseCliFlags(args);
  if (parsed.containsKey('help')) {
    stdout.writeln(_usage);
    return;
  }

  final secretsPath = resolveAgentPath(parsed['secrets'], 'secrets.json');
  final cachePath = resolveAgentPath(parsed['cache'], 'pipeline-cache.json');
  final secrets = await _readJson(secretsPath);
  final cache = await _readJson(cachePath);

  final logPath = parsed['log'];
  if (logPath == null || logPath.isEmpty) {
    stderr.writeln('Missing --log. Path to logs.txt is required.');
    exitCode = 64;
    return;
  }

  final logFile = File(logPath);
  if (!await logFile.exists()) {
    stderr.writeln('Pipeline log file was not found: $logPath');
    exitCode = 1;
    return;
  }

  final sender = (parsed['sender'] ?? secrets['gmailAddress'] ?? '')
      .toString()
      .trim();
  final password = (secrets['appPassword'] ?? '').toString().trim();
  final recipient = (parsed['recipient'] ?? cache['emailRecipient'] ?? '')
      .toString()
      .trim();

  if (sender.isEmpty || password.isEmpty) {
    stderr.writeln(
      'Gmail credentials are missing. Set gmailAddress and appPassword in $secretsPath.',
    );
    exitCode = 1;
    return;
  }

  if (recipient.isEmpty) {
    stderr.writeln(
      'Recipient is missing. Pass --recipient or set emailRecipient in $cachePath.',
    );
    exitCode = 1;
    return;
  }

  final appName = parsed['app-name'] ?? 'Fluship';
  final version = parsed['version'] ?? 'unknown';
  final buildNumber = parsed['build-number'] ?? '0';
  final elapsed = parsed['elapsed'] ?? 'unknown';
  final platforms = parsed['platforms'] ?? 'unknown';
  final success = _isSuccess(parsed['success'] ?? 'true');
  final steps = _parseSteps(parsed['steps'] ?? '');

  final statusMark = success ? '✓' : '✗';
  final subject = '$statusMark $appName v$version+$buildNumber - Build Report';
  final html = _buildHtml(
    appName: appName,
    version: version,
    buildNumber: buildNumber,
    elapsed: elapsed,
    platforms: platforms,
    success: success,
    steps: steps,
  );

  final message = mailer.Message()
    ..from = mailer.Address(sender, sender)
    ..recipients.add(recipient)
    ..subject = subject
    ..html = html
    ..text = _plainText(
      appName: appName,
      version: version,
      buildNumber: buildNumber,
      elapsed: elapsed,
      platforms: platforms,
      success: success,
      steps: steps,
    )
    ..attachments.add(
      mailer.FileAttachment(logFile)..fileName = p.basename(logPath),
    );

  await mailer.send(message, gmail(sender, password));
  stdout.writeln('Build report emailed to $recipient');
}

const _usage = '''
Send a Fluship pipeline report email with logs.txt attached.

  dart run tool/send_pipeline_report.dart --log <logs.txt> [options]

Reads Gmail from .fluship-agent/secrets.json and recipient from
.fluship-agent/pipeline-cache.json unless overridden.

Options:
  --log            Path to logs.txt (required)
  --recipient      Override cache emailRecipient
  --sender         Override secrets gmailAddress
  --app-name       App name (default Fluship)
  --version        Version string
  --build-number   Build number
  --success        true or false
  --elapsed        Duration label, e.g. 2m10s
  --platforms      Platform label, e.g. Android
  --steps          Comma list: Name:ok:1.2s,Other:fail:3m4s
  --secrets        Secrets JSON path
  --cache          Cache JSON path
  --help           Show this help

Do not pass the Gmail app password on the command line.
''';

Future<Map<String, dynamic>> _readJson(String path) async {
  final file = File(path);
  if (!await file.exists()) return const {};

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  return const {};
}

bool _isSuccess(String value) {
  return switch (value.trim().toLowerCase()) {
    'false' || 'fail' || 'failed' || '0' || 'no' => false,
    _ => true,
  };
}

List<({String name, bool success, String elapsed})> _parseSteps(String raw) {
  if (raw.trim().isEmpty) return const [];

  return [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) _parseStep(part.trim()),
  ];
}

({String name, bool success, String elapsed}) _parseStep(String part) {
  final bits = part.split(':');
  final name = bits.isEmpty ? 'Step' : bits[0];
  final success = bits.length < 2 ? true : _isSuccess(bits[1]);
  final elapsed = bits.length < 3 ? '' : bits.sublist(2).join(':');
  return (name: name, success: success, elapsed: elapsed);
}

String _plainText({
  required String appName,
  required String version,
  required String buildNumber,
  required String elapsed,
  required String platforms,
  required bool success,
  required List<({String name, bool success, String elapsed})> steps,
}) {
  final buffer = StringBuffer()
    ..writeln('$appName v$version+$buildNumber')
    ..writeln(success ? 'Build Succeeded' : 'Build Failed')
    ..writeln('Platforms: $platforms')
    ..writeln('Total Time: $elapsed')
    ..writeln('Pipeline Steps');
  for (final step in steps) {
    final mark = step.success ? 'ok' : 'fail';
    buffer.writeln('- ${step.name} [$mark] ${step.elapsed}');
  }
  return buffer.toString();
}

String _buildHtml({
  required String appName,
  required String version,
  required String buildNumber,
  required String elapsed,
  required String platforms,
  required bool success,
  required List<({String name, bool success, String elapsed})> steps,
}) {
  const bg = '#0d1117';
  const card = '#161b22';
  const border = '#30363d';
  const text = '#e6edf3';
  const dim = '#8b949e';
  const accent = '#58a6ff';
  const ok = '#3fb950';
  const err = '#f85149';
  final statusColor = success ? ok : err;
  final statusText = success ? 'Build Succeeded' : 'Build Failed';
  final statusMark = success ? '✓' : '✗';

  final rows = StringBuffer();
  for (final step in steps) {
    final stepColor = step.success ? ok : err;
    final stepMark = step.success ? '✓' : '✗';
    rows.writeln(
      '<tr>'
      '<td style="padding:10px 14px;color:$text;">${_escape(step.name)}</td>'
      '<td style="padding:10px 14px;text-align:center;color:$stepColor;">$stepMark</td>'
      '<td style="padding:10px 14px;text-align:right;color:$dim;">${_escape(step.elapsed)}</td>'
      '</tr>',
    );
  }

  return '''
<!DOCTYPE html>
<html>
<body style="margin:0;background:$bg;font-family:Segoe UI,Helvetica,Arial,sans-serif;">
<div style="max-width:640px;margin:24px auto;background:$card;border:1px solid $border;border-radius:12px;overflow:hidden;color:$text;">
  <div style="padding:20px 22px;border-bottom:1px solid $border;">
    <div style="font-size:12px;color:$dim;letter-spacing:0.6px;text-transform:uppercase;">Fluship</div>
    <h1 style="margin:6px 0 0;font-size:20px;">${_escape(appName)}</h1>
    <div style="margin-top:4px;color:$dim;">Build Report - v${_escape(version)}+${_escape(buildNumber)}</div>
  </div>
  <div style="padding:14px 22px;background:$statusColor;color:#ffffff;font-weight:700;">
    $statusMark  $statusText
  </div>
  <table style="width:100%;border-collapse:collapse;padding:18px 22px;">
    <tr><td style="padding:12px 22px;color:$dim;">Version</td><td style="padding:12px 22px;text-align:right;font-weight:700;">v${_escape(version)}+${_escape(buildNumber)}</td></tr>
    <tr><td style="padding:12px 22px;color:$dim;">Platforms</td><td style="padding:12px 22px;text-align:right;">${_escape(platforms)}</td></tr>
    <tr><td style="padding:12px 22px;color:$dim;">Total Time</td><td style="padding:12px 22px;text-align:right;color:$accent;font-weight:700;">${_escape(elapsed)}</td></tr>
  </table>
  <div style="padding:14px 22px 8px;border-top:1px solid $border;font-size:12px;letter-spacing:0.6px;text-transform:uppercase;color:$dim;">Pipeline Steps</div>
  <table style="width:100%;border-collapse:collapse;">
    <tr style="color:$dim;font-size:11px;text-transform:uppercase;">
      <th style="padding:10px 14px;text-align:left;">Step</th>
      <th style="padding:10px 14px;text-align:center;">Status</th>
      <th style="padding:10px 14px;text-align:right;">Time</th>
    </tr>
    $rows
  </table>
</div>
</body>
</html>
''';
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
