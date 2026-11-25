class const EmailMessage({
  required final List<String> recipients,
  final String senderName = 'Fluship',
  required final String password,
  required final String subject,
  final String? attachmentPath,
  required final String sender,
  required final String text,
  required final String html,
});

abstract interface class EmailClient {
  Future<void> send(EmailMessage message);
}
