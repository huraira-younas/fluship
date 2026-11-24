part of 'distribution_config.dart';

class const SlackConfig({final bool enabled = false, final String? webhookUrl})
    extends Equatable {
  bool get canSend => hasCreds(webhookUrl);

  SlackConfig copyWith({String? webhookUrl, bool? enabled}) => SlackConfig(
    webhookUrl: webhookUrl ?? this.webhookUrl,
    enabled: enabled ?? this.enabled,
  );

  factory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SlackConfig();

    final data = json.at<SlackConfig>();
    return SlackConfig(
      enabled: data.parse<bool>('enabled', defaultValue: false),
      webhookUrl: data.parse<String?>('webhookUrl'),
    );
  }

  Map<String, dynamic> toJson() => {
    'webhookUrl': webhookUrl,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [webhookUrl, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
