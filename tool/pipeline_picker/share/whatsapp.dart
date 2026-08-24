import 'dart:io';

import '../host/host_actions.dart';
import '../io_helpers.dart';

const defaultWhatsAppNumber = '+923096547269';

/// Driving WhatsApp means pasting into one shared composer, so two senders at
/// once garble both messages. The heartbeat runs in its own process, so an
/// in-memory guard is not enough and the lock has to live on disk.
class WhatsAppUiLock {
  const WhatsAppUiLock({required this.path, required this.held});

  final String path;
  final bool held;

  void release() {
    if (!held) return;
    if (_lockOwner(path) != pid) return;
    deleteIfExists(path);
  }
}

int? _lockOwner(String path) {
  try {
    final raw = File(path).readAsStringSync().trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw.split('\n').first.trim());
  } catch (_) {
    return null;
  }
}

bool _lockIsFree(String path) {
  final file = File(path);
  if (!file.existsSync()) return true;
  final owner = _lockOwner(path);
  // A killed sender leaves the file behind, so a dead owner means it is free.
  if (owner == null || owner == pid || !pidAlive(owner)) return true;
  try {
    final age = DateTime.now().difference(file.lastModifiedSync());
    return age > const Duration(minutes: 3);
  } catch (_) {
    return true;
  }
}

Future<WhatsAppUiLock> acquireWhatsAppUiLock({
  Duration wait = const Duration(seconds: 2),
  String? path,
}) async {
  final lockPath = path ?? resolveAgentPath(null, 'whatsapp.lock');
  final deadline = DateTime.now().add(wait);
  while (true) {
    if (_lockIsFree(lockPath)) {
      try {
        final file = File(lockPath);
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$pid\n${DateTime.now().toIso8601String()}');
        if (_lockOwner(lockPath) == pid) {
          return WhatsAppUiLock(path: lockPath, held: true);
        }
      } catch (_) {
        // Fall through and retry until the deadline.
      }
    }
    if (!DateTime.now().isBefore(deadline)) {
      return WhatsAppUiLock(path: lockPath, held: false);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

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

String whatsappResultFromOutput(String out) {
  final lower = out.toLowerCase();
  if (lower.contains('whatsapp result: sent')) return 'sent';
  if (lower.contains('whatsapp result: attached')) return 'attached';
  if (lower.contains('whatsapp result: no-whatsapp')) return 'no-whatsapp';
  if (lower.contains('whatsapp result: no-files')) return 'no-files';
  if (lower.contains('whatsapp result: no-text')) return 'no-text';
  return 'failed';
}

Future<String> _runWhatsAppSend({
  required String number,
  required String caption,
  required List<String> files,
  required bool send,
  required bool textOnly,
  required Duration lockWait,
  required bool skipWhenBusy,
}) async {
  final py = resolveToolScript('whatsapp_send.py');
  if (py == null) return 'no-python';
  final lock = await acquireWhatsAppUiLock(wait: lockWait);
  if (!lock.held && skipWhenBusy) return 'busy';
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
      if (textOnly) '--text-only',
      if (!send) '--no-send',
      for (final path in files) ...['--file', path],
    ]);
    stdout.write(result.stdout);
    if (result.stderr.toString().trim().isNotEmpty) {
      stderr.write(result.stderr);
    }
    return whatsappResultFromOutput('${result.stdout}\n${result.stderr}');
  } finally {
    deleteIfExists(captionFile.path);
    lock.release();
  }
}

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
  return _runWhatsAppSend(
    number: number,
    caption: caption,
    files: existing,
    send: send,
    textOnly: false,
    // The final report has to go out, so outwait a ping instead of skipping.
    lockWait: const Duration(seconds: 90),
    skipWhenBusy: false,
  );
}

Future<String> sendWhatsAppText({
  required String number,
  required String text,
  bool send = true,
}) async {
  final caption = text.trim();
  if (caption.isEmpty) return 'no-text';
  return _runWhatsAppSend(
    number: number,
    caption: caption,
    files: const [],
    send: send,
    textOnly: true,
    // A ping is disposable. Never make it queue in front of the real report.
    lockWait: const Duration(seconds: 2),
    skipWhenBusy: true,
  );
}
