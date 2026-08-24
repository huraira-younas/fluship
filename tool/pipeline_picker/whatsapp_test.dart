import 'dart:io';

import 'io_helpers.dart';
import 'whatsapp.dart';

void main() {
  _check(isValidWhatsAppNumber(defaultWhatsAppNumber), 'default valid');
  _check(whatsappPhone(defaultWhatsAppNumber) == '923096547269', 'digits');
  _check(isValidWhatsAppNumber('03001234567'), 'local 11');
  _check(!isValidWhatsAppNumber(''), 'empty invalid');
  _check(!isValidWhatsAppNumber('123'), 'short invalid');
  _check(
    resolveWhatsAppNumber(cached: '', incoming: '') == defaultWhatsAppNumber,
    'resolve default',
  );
  _check(
    resolveWhatsAppNumber(cached: '+111', incoming: '+222') == '+222',
    'incoming wins',
  );
  _check(
    resolveWhatsAppNumber(cached: '+111', incoming: '') == '+111',
    'cache used',
  );

  final redacted = redactSecrets('appPassword=super-secret failed to sign');
  _check(!redacted.contains('super-secret'), 'redact password');
  _check(redacted.contains('[redacted]'), 'redacted marker');

  final chat = buildWhatsAppChatText(
    appName: 'Reelstay',
    version: '1.8.2',
    buildNumber: '8205',
    success: true,
  );
  _check(chat.startsWith('Fluship: Reelstay v1.8.2+8205 succeeded.'), 'chat');
  _check(chat.contains('PDF report and any APKs are attached.'), 'chat pdf');
  _check(!chat.contains('Steps:'), 'chat has no step dump');
  _check(!chat.contains('BumpVersion:ok'), 'chat has no ids');

  final uri = whatsappDesktopUri(
    number: defaultWhatsAppNumber,
    text: 'hello world',
  );
  _check(uri.startsWith('whatsapp://send?phone=923096547269'), 'desktop uri');
  _check(uri.contains('text=hello%20world'), 'encoded text');
  _check(
    whatsappWebUri(
      number: defaultWhatsAppNumber,
      text: 'x',
    ).startsWith('https://wa.me/923096547269'),
    'web uri',
  );
  _check(
    fileNameOf('/tmp/pipeline-report.pdf') == 'pipeline-report.pdf',
    'name',
  );
  _check(whatsAppSendScript.contains('writeObjects'), 'copies file urls');
  _check(
    whatsAppSendScript.contains('fileURLWithPath'),
    'uses file urls not aliases',
  );
  _check(
    !whatsAppSendScript.contains('as alias'),
    'does not put aliases on clipboard',
  );
  _check(
    whatsAppSendScript.indexOf('copyFilesToClipboard') <
        whatsAppSendScript.indexOf('set the clipboard to captionText'),
    'files hit the clipboard before caption',
  );
  _check(
    errorExcerptFromLog('ok\nGradle failed.\n') == 'Gradle failed.',
    'excerpt',
  );

  stdout.writeln('whatsapp tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
