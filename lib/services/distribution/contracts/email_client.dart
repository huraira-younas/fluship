class EmailMessage {
  const EmailMessage({
    required this.recipients,
    required this.subject,
    required this.html,
    required this.sender,
    required this.password,
    this.attachmentPath,
  });

  final List<String> recipients;
  final String? attachmentPath;
  final String password;
  final String subject;
  final String sender;
  final String html;
}

abstract interface class EmailClient {
  Future<void> send(EmailMessage message);
}
