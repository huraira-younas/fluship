part of 'distribution_config.dart';

class const WhatsAppConfig({
  final bool enabled = false,

  /// Opaque `user:<id>` of the WhatsApp account that created the agent. It is
  /// read from a message that account sent to the agent, never typed in: the
  /// Agent Platform takes no phone numbers and lets an agent message only its
  /// creator.
  final String? recipientId,
  final String? apiKey,
}) extends Equatable {
  bool get isConnected => hasCreds(recipientId);
  bool get canSend => hasCreds(apiKey) && isConnected;

  WhatsAppConfig copyWith({
    bool clearRecipient = false,
    bool clearApiKey = false,
    String? recipientId,
    String? apiKey,
    bool? enabled,
  }) => WhatsAppConfig(
    recipientId: clearRecipient ? null : recipientId ?? this.recipientId,
    apiKey: clearApiKey ? null : apiKey ?? this.apiKey,
    enabled: enabled ?? this.enabled,
  );

  factory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WhatsAppConfig();

    final data = json.at<WhatsAppConfig>();
    return WhatsAppConfig(
      enabled: data.parse<bool>('enabled', defaultValue: false),
      recipientId: data.parse<String?>('recipientId'),
      apiKey: data.parse<String?>('apiKey'),
    );
  }

  Map<String, dynamic> toJson() => {
    'recipientId': recipientId,
    'enabled': enabled,
    'apiKey': apiKey,
  };

  @override
  List<Object?> get props => [recipientId, enabled, apiKey];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
