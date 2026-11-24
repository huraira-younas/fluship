part of 'distribution_config.dart';

class const GoogleDriveConfig({
  final bool enabled = false,
  final String? tokenJson,
  final String? oauthJson,
  final String? folderId,
}) extends Equatable {
  bool get canSend => hasCreds(oauthJson) && hasCreds(tokenJson);

  GoogleDriveConfig copyWith({
    String? oauthJson,
    String? tokenJson,
    String? folderId,
    bool? enabled,
  }) => GoogleDriveConfig(
    oauthJson: oauthJson ?? this.oauthJson,
    tokenJson: tokenJson ?? this.tokenJson,
    folderId: folderId ?? this.folderId,
    enabled: enabled ?? this.enabled,
  );

  factory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GoogleDriveConfig();

    final data = json.at<GoogleDriveConfig>();
    return GoogleDriveConfig(
      enabled: data.parse<bool>('enabled', defaultValue: false),
      oauthJson: data.parse<String?>('oauthJson'),
      tokenJson: data.parse<String?>('tokenJson'),
      folderId: data.parse<String?>('folderId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'oauthJson': oauthJson,
    'tokenJson': tokenJson,
    'folderId': folderId,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [oauthJson, tokenJson, folderId, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
