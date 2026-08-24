import 'progress.dart';

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

String buildWhatsAppCaption({
  required String appName,
  required String version,
  required String buildNumber,
  required bool success,
  required String steps,
  String errorExcerpt = '',
  List<String> attachments = const [],
}) {
  final status = success ? 'success' : 'failed';
  final buffer = StringBuffer()
    ..writeln('Fluship: $appName v$version+$buildNumber')
    ..writeln('Status: $status');
  final lines = formatStepLines(steps);
  if (lines.isNotEmpty) {
    buffer
      ..writeln('')
      ..writeln(lines);
  }
  final error = redactSecrets(errorExcerpt).trim();
  if (error.isNotEmpty) {
    final clip = error.length > 280 ? '${error.substring(0, 280)}...' : error;
    buffer
      ..writeln('')
      ..writeln(clip);
  }
  if (attachments.isNotEmpty) {
    buffer
      ..writeln('')
      ..writeln('Attached:')
      ..writeln([for (final path in attachments) fileNameOf(path)].join('\n'));
  }
  return buffer.toString().trim();
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

String fileNameOf(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.isEmpty ? path : parts.last;
}

String whatsappDesktopUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}';
}

String whatsappWebUri({required String number, required String text}) {
  final phone = whatsappPhone(number);
  return 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
}
