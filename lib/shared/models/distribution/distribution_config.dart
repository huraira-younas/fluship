import 'dart:io' show Platform;

import 'package:fluship/core/json_parser/exports.dart';
import 'package:equatable/equatable.dart';
import '../base_config.dart';

part 'report_recipient_config.dart';
part 'google_drive_config.dart';
part 'distribution_email.dart';
part 'ios_config.dart';
part 'enum.dart';

final class DistributionConfigModel extends BaseConfig {
  const DistributionConfigModel({
    super.enabled = true,
    this.reportRecipient,
    this.driveConfig,
    this.playstore,
    this.appstore,
  });

  final ReportRecipientConfig? reportRecipient;
  final PlayStoreDistribution? playstore;
  final GoogleDriveConfig? driveConfig;
  final IosConfig? appstore;

  bool get canSendBuildReport => reportRecipient?.canSendBuildReport ?? false;
  bool get canSendToDrive => _hasCredential(driveConfig?.oauthJson);
  bool get canSendToPlayStore => false;
  bool get canSendToAppStore =>
      Platform.isMacOS && _hasCredential(appstore?.apiKeyId);

  static bool _hasCredential(String? path) => path != null && path.isNotEmpty;

  factory DistributionConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DistributionConfigModel();

    final data = json.at<DistributionConfigModel>();
    return DistributionConfigModel(
      driveConfig: data.objectOrNull(GoogleDriveConfig.fromJson, 'driveConfig'),
      appstore: data.objectOrNull(IosConfig.fromJson, 'appstore'),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      playstore: .fromString(data.parse<String?>('playstore')),
      reportRecipient: data.objectOrNull(
        ReportRecipientConfig.fromJson,
        'reportRecipient',
      ),
    );
  }

  @override
  DistributionConfigModel copyWith({
    ReportRecipientConfig? reportRecipient,
    PlayStoreDistribution? playstore,
    GoogleDriveConfig? driveConfig,
    bool clearPlaystore = false,
    bool clearAppstore = false,
    IosConfig? appstore,
    bool? enabled,
  }) => DistributionConfigModel(
    playstore: clearPlaystore ? null : playstore ?? this.playstore,
    appstore: clearAppstore ? null : appstore ?? this.appstore,
    reportRecipient: reportRecipient ?? this.reportRecipient,
    driveConfig: driveConfig ?? this.driveConfig,
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [
    reportRecipient,
    driveConfig,
    playstore,
    appstore,
    enabled,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'reportRecipient': reportRecipient?.toJson(),
    'driveConfig': driveConfig?.toJson(),
    'appstore': appstore?.toJson(),
    'playstore': playstore?.name,
    'enabled': enabled,
  };

  @override
  bool? get stringify => true;
}
