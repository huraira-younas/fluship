/// WhatsApp Agent Platform, as far as Fluship uses it.
///
/// An agent can only message the account that created it, so every call
/// here talks to one person: the owner of the API key.
abstract interface class WhatsAppClient {
  /// Finds the creator's `user:<id>` from the messages they sent the agent.
  /// Returns null when the agent has not been written to yet.
  Future<String?> findCreatorId({required String token});

  Future<void> sendText({
    required String token,
    required String body,
    required String to,
  });

  /// Uploads a file and returns the media id to pass to [sendDocument].
  Future<String> uploadDocument({
    required String mimeType,
    required String token,
    required String path,
  });

  Future<void> sendDocument({
    required String fileName,
    required String mediaId,
    required String token,
    required String to,
    String? caption,
  });
}

class WhatsAppLimits {
  const WhatsAppLimits._();

  static const maxDocumentBytes = 16 * 1024 * 1024;
  static const maxCaptionLength = 1024;
  static const maxTextLength = 4096;
}

/// [message] is safe to show and log: it never contains the API key.
class WhatsAppApiException implements Exception {
  const WhatsAppApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  final int statusCode;
  final String message;
  final int? code;

  bool get isRetryable => statusCode == 429 || statusCode == 503;

  @override
  String toString() => message;
}
