class const EmailMessage({
  required final List<String> recipients,
  required final String subject,
  required final String html,
  required final String sender,
  required final String password,
  final String? attachmentPath,
});

abstract interface class EmailClient {
  Future<void> send(EmailMessage message);
}
