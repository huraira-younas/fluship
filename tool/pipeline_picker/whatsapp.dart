import 'dart:io';

import 'io_helpers.dart';

const defaultWhatsAppNumber = '+923096547269';

String digitsOnly(String raw) {
  return raw.replaceAll(RegExp(r'\D'), '');
}

bool isValidWhatsAppNumber(String raw) {
  final digits = digitsOnly(raw);
  return digits.length >= 10 && digits.length <= 15;
}

String whatsappPhone(String raw) => digitsOnly(raw);

String resolveWhatsAppNumber({
  required String cached,
  required String incoming,
}) {
  final fromIncoming = incoming.trim();
  if (fromIncoming.isNotEmpty) return fromIncoming;
  final fromCache = cached.trim();
  if (fromCache.isNotEmpty) return fromCache;
  return defaultWhatsAppNumber;
}

String redactSecrets(String text) {
  var out = text;
  const patterns = <String>[
    r'appPassword["\s:=]+[^\s,"]+',
    r'app_password["\s:=]+[^\s,"]+',
    r'password["\s:=]+[^\s,"]+',
  ];
  for (final pattern in patterns) {
    out = out.replaceAll(
      RegExp(pattern, caseSensitive: false),
      'password [redacted]',
    );
  }
  return out;
}

String errorExcerptFromLog(String log) {
  for (final line in redactSecrets(log).split('\n').reversed) {
    final lower = line.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('fail') ||
        lower.contains('exception')) {
      return line.trim();
    }
  }
  return '';
}

String buildWhatsAppChatText({
  required String appName,
  required String version,
  required String buildNumber,
  required bool success,
}) {
  final status = success ? 'succeeded' : 'failed';
  return 'Fluship: $appName v$version+$buildNumber $status.\n'
      'PDF report and any APKs are attached.';
}

String whatsappDesktopChatUri({required String number}) {
  return 'whatsapp://send?phone=${whatsappPhone(number)}';
}

String whatsappDesktopUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}';
}

String whatsappWebUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
}

String? resolveWhatsAppSendPy() => resolveToolScript('whatsapp_send.py');

Future<String> sendWhatsAppFiles({
  required String number,
  required String caption,
  required List<String> files,
  required bool send,
}) async {
  final existing = [
    for (final path in files)
      if (File(path).existsSync()) path,
  ];
  if (existing.isEmpty) return 'no-files';
  final py = resolveWhatsAppSendPy();
  if (py == null) return 'no-python';
  final stamp = '$pid-${DateTime.now().microsecondsSinceEpoch}';
  final captionFile = File(
    pathJoin(Directory.systemTemp.path, 'fluship-wa-$stamp-caption.txt'),
  );
  try {
    captionFile.writeAsStringSync(caption);
    final result = await Process.run('python3', [
      py,
      '--number',
      whatsappPhone(number),
      '--caption-file',
      captionFile.path,
      if (!send) '--no-send',
      for (final path in existing) ...['--file', path],
    ]);
    stdout.write(result.stdout);
    if (result.stderr.toString().trim().isNotEmpty) {
      stderr.write(result.stderr);
    }
    final out = '${result.stdout}\n${result.stderr}'.toLowerCase();
    if (out.contains('whatsapp result: sent')) return 'sent';
    if (out.contains('whatsapp result: attached')) return 'attached';
    if (out.contains('whatsapp result: no-whatsapp')) return 'no-whatsapp';
    if (out.contains('whatsapp result: no-files')) return 'no-files';
    return 'failed';
  } finally {
    deleteIfExists(captionFile.path);
  }
}
