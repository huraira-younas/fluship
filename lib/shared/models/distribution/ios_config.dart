part of 'distribution_config.dart';

class IosConfig extends Equatable {
  final String? apiKeyPath;
  final String? issuerId;
  final String? apiKeyId;
  final bool enabled;

  const IosConfig({
    this.enabled = false,
    this.apiKeyPath,
    this.issuerId,
    this.apiKeyId,
  });

  bool get canSend =>
      hasCreds(apiKeyPath) && hasCreds(issuerId) && hasCreds(apiKeyId);

  IosConfig copyWith({
    String? apiKeyPath,
    String? issuerId,
    String? apiKeyId,
    bool? enabled,
  }) => IosConfig(
    apiKeyPath: apiKeyPath ?? this.apiKeyPath,
    issuerId: issuerId ?? this.issuerId,
    apiKeyId: apiKeyId ?? this.apiKeyId,
    enabled: enabled ?? this.enabled,
  );

  factory IosConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const IosConfig();

    final data = json.at<IosConfig>();
    return IosConfig(
      enabled: data.parse<bool>('enabled', defaultValue: false),
      apiKeyPath: data.parse<String?>('apiKeyPath'),
      issuerId: data.parse<String?>('issuerId'),
      apiKeyId: data.parse<String?>('apiKeyId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'apiKeyPath': apiKeyPath,
    'issuerId': issuerId,
    'apiKeyId': apiKeyId,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [issuerId, apiKeyId, apiKeyPath, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
