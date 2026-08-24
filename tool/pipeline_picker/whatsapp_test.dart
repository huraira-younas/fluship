import 'dart:io';

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

  final caption = buildWhatsAppCaption(
    appName: 'Demo',
    version: '1.0.0',
    buildNumber: '2',
    success: false,
    steps: 'Clean:ok:1s,BuildAab:fail:3m',
    errorExcerpt: 'appPassword=super-secret failed to sign',
  );
  _check(caption.contains('Status: failed'), 'fail status');
  _check(caption.contains('FAIL Build Play bundle (AAB) (3m)'), 'step detail');
  _check(!caption.contains('BuildAab:fail:3m'), 'no packed dump');
  _check(!caption.contains('super-secret'), 'redact password');
  _check(caption.contains('[redacted]'), 'redacted marker');
  _check(!caption.contains('\u2014'), 'caption em-dash');

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

  stdout.writeln('whatsapp tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
