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

String whatsappDesktopUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}';
}

String whatsappWebUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
}

Future<String> sendFilesOnMac({
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

  final stamp = '$pid-${DateTime.now().microsecondsSinceEpoch}';
  final tmp = Directory.systemTemp.path;
  final captionFile = File(pathJoin(tmp, 'fluship-wa-$stamp-caption.txt'));
  final scriptFile = File(pathJoin(tmp, 'fluship-wa-$stamp.applescript'));
  try {
    captionFile.writeAsStringSync(caption);
    scriptFile.writeAsStringSync(_whatsAppSendScript);
    final result = await Process.run('osascript', [
      scriptFile.path,
      whatsappPhone(number),
      captionFile.path,
      send ? 'send' : 'draft',
      ...existing,
    ]);
    final out = '${result.stdout}\n${result.stderr}'.trim();
    if (out.contains('sent') || out.contains('attached')) {
      return out.contains('sent') ? 'sent' : 'attached';
    }
    if (result.exitCode == 0 && out.isNotEmpty) return out.split('\n').last;
    return 'failed';
  } finally {
    deleteIfExists(captionFile.path);
    deleteIfExists(scriptFile.path);
  }
}

const _whatsAppSendScript = r'''
on run argv
  if (count of argv) < 4 then return "bad-args"
  set phone to item 1 of argv
  set captionPath to item 2 of argv
  set mode to item 3 of argv
  set posixFiles to items 4 thru -1 of argv

  set aliasList to {}
  repeat with p in posixFiles
    try
      set end of aliasList to (POSIX file p as alias)
    end try
  end repeat
  if (count of aliasList) is 0 then return "no-files"
  set the clipboard to aliasList

  do shell script "open " & quoted form of ("whatsapp://send?phone=" & phone)
  delay 3
  tell application "WhatsApp" to activate
  delay 1.2

  tell application "System Events"
    if not (exists process "WhatsApp") then return "no-whatsapp"
    tell process "WhatsApp"
      set frontmost to true
      delay 0.5
      try
        set winPos to position of window 1
        set winSize to size of window 1
        set clickX to (item 1 of winPos) + ((item 1 of winSize) / 2)
        set clickY to (item 2 of winPos) + (item 2 of winSize) - 58
        click at {clickX as integer, clickY as integer}
      end try
      delay 0.4
      keystroke "v" using command down
      delay 2
    end tell
  end tell

  set captionText to do shell script "cat " & quoted form of captionPath
  set the clipboard to captionText
  delay 0.2
  tell application "System Events"
    tell process "WhatsApp"
      set frontmost to true
      keystroke "v" using command down
      delay 0.8
      if mode is "send" then
        keystroke return
        delay 0.6
        return "sent"
      end if
      return "attached"
    end tell
  end tell
end run
''';
