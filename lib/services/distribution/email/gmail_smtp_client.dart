import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show File;

import '../contracts/email_client.dart';

class GmailSmtpClient implements EmailClient {
  const GmailSmtpClient();

  @override
  Future<void> send(EmailMessage message) async {
    final server = gmail(message.sender, message.password);
    final mail = mailer.Message()
      ..from = mailer.Address(message.sender, message.sender)
      ..recipients.addAll(message.recipients)
      ..subject = message.subject
      ..html = message.html
      ..text = message.html;

    final attachmentPath = message.attachmentPath;
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final file = File(attachmentPath);
      if (await file.exists()) {
        mail.attachments.add(
          mailer.FileAttachment(file)..fileName = p.basename(attachmentPath),
        );
      }
    }

    await mailer.send(mail, server);
  }
}
