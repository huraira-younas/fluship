import 'package:fluship/core/json_parser/exports.dart';
import 'package:equatable/equatable.dart';

import '../base_config.dart';
import 'has_creds.dart';

part 'report_recipient_config.dart';
part 'google_drive_config.dart';
part 'google_play_config.dart';
part 'distribution_email.dart';
part 'whatsapp_config.dart';
part 'slack_config.dart';
part 'ios_config.dart';

final class DistributionConfigModel extends BaseConfig {
  const DistributionConfigModel({
    super.enabled = true,
    this.reportRecipient,
    this.whatsappConfig,
    this.releaseNotes,
    this.driveConfig,
    this.slackConfig,
    this.playstore,
    this.appstore,
  });

  final ReportRecipientConfig? reportRecipient;
  final GooglePlayConsoleConfig? playstore;
  final WhatsAppConfig? whatsappConfig;
  final GoogleDriveConfig? driveConfig;
  final SlackConfig? slackConfig;
  final String? releaseNotes;
  final IosConfig? appstore;

  bool get canSendBuildReport => reportRecipient?.canSend ?? false;
  bool get canSendToPlayStore => playstore?.canSend ?? false;
  bool get canSendToWhatsApp => whatsappConfig?.canSend ?? false;
  bool get canSendToAppStore => appstore?.canSend ?? false;
  bool get canSendToSlack => slackConfig?.canSend ?? false;
  bool get canSendToDrive => driveConfig?.canSend ?? false;

  factory DistributionConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DistributionConfigModel();

    final data = json.at<DistributionConfigModel>();
    return DistributionConfigModel(
      driveConfig: data.objectOrNull(GoogleDriveConfig.fromJson, 'driveConfig'),
      slackConfig: data.objectOrNull(SlackConfig.fromJson, 'slackConfig'),
      appstore: data.objectOrNull(IosConfig.fromJson, 'appstore'),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      releaseNotes: data.parse<String?>('releaseNotes'),
      reportRecipient: data.objectOrNull(
        ReportRecipientConfig.fromJson,
        'reportRecipient',
      ),
      whatsappConfig: data.objectOrNull(
        WhatsAppConfig.fromJson,
        'whatsappConfig',
      ),
      playstore: data.objectOrNull(
        GooglePlayConsoleConfig.fromJson,
        'playstore',
      ),
    );
  }

  @override
  DistributionConfigModel copyWith({
    ReportRecipientConfig? reportRecipient,
    GooglePlayConsoleConfig? playstore,
    WhatsAppConfig? whatsappConfig,
    GoogleDriveConfig? driveConfig,
    bool clearAppstore = false,
    SlackConfig? slackConfig,
    String? releaseNotes,
    IosConfig? appstore,
    bool? enabled,
  }) => DistributionConfigModel(
    appstore: clearAppstore ? null : appstore ?? this.appstore,
    reportRecipient: reportRecipient ?? this.reportRecipient,
    whatsappConfig: whatsappConfig ?? this.whatsappConfig,
    releaseNotes: releaseNotes ?? this.releaseNotes,
    driveConfig: driveConfig ?? this.driveConfig,
    slackConfig: slackConfig ?? this.slackConfig,
    playstore: playstore ?? this.playstore,
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [
    reportRecipient,
    whatsappConfig,
    releaseNotes,
    driveConfig,
    slackConfig,
    playstore,
    appstore,
    enabled,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'reportRecipient': reportRecipient?.toJson(),
    'whatsappConfig': whatsappConfig?.toJson(),
    'driveConfig': driveConfig?.toJson(),
    'slackConfig': slackConfig?.toJson(),
    'playstore': playstore?.toJson(),
    'appstore': appstore?.toJson(),
    'releaseNotes': releaseNotes,
    'enabled': enabled,
  };

  @override
  bool? get stringify => true;
}
