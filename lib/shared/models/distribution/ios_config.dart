part of 'distribution_config.dart';

class IosConfig extends Equatable {
  final String? issuerId;
  final String? apiKeyId;
  final bool enabled;

  const IosConfig({this.issuerId, this.apiKeyId, this.enabled = false});

  IosConfig copyWith({String? issuerId, String? apiKeyId, bool? enabled}) =>
      IosConfig(
        issuerId: issuerId ?? this.issuerId,
        apiKeyId: apiKeyId ?? this.apiKeyId,
        enabled: enabled ?? this.enabled,
      );

  factory IosConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const IosConfig();

    final data = json.at<IosConfig>();
    return IosConfig(
      enabled: data.parse<bool>('enabled', defaultValue: false),
      issuerId: data.parse<String?>('issuerId'),
      apiKeyId: data.parse<String?>('apiKeyId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'issuerId': issuerId,
    'apiKeyId': apiKeyId,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [issuerId, apiKeyId, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
