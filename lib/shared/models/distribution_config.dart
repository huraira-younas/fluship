import 'dart:io' show Platform;

import 'package:fluship/core/json_parser/exports.dart';
import 'package:equatable/equatable.dart';
import 'base_config.dart';

enum PlayStoreDistribution {
  production,
  internal;

  static PlayStoreDistribution? fromString(String? value) => switch (value) {
    'production' => .production,
    'internal' => .internal,
    _ => null,
  };
}

class DistributionEmail extends Equatable {
  const DistributionEmail({
    this.enabled = true,
    required this.email,
    required this.name,
  });

  final bool enabled;
  final String email;
  final String name;

  factory DistributionEmail.fromJson(Map<String, dynamic> json) {
    final data = json.at<DistributionEmail>();
    return DistributionEmail(
      enabled: data.parse<bool>('enabled', defaultValue: true),
      email: data.parse<String>('email'),
      name: data.parse<String>('name'),
    );
  }

  DistributionEmail copyWith({bool? enabled, String? email, String? name}) =>
      DistributionEmail(
        enabled: enabled ?? this.enabled,
        email: email ?? this.email,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'email': email,
    'name': name,
  };

  @override
  List<Object?> get props => [enabled, email, name];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}

class ReportRecipientConfig extends Equatable {
  final String? reportRecipient;
  final String? gmailAddress;
  final String? appPassword;

  const ReportRecipientConfig({
    this.reportRecipient,
    this.gmailAddress,
    this.appPassword,
  });

  ReportRecipientConfig copyWith({
    String? reportRecipient,
    String? gmailAddress,
    String? appPassword,
  }) => ReportRecipientConfig(
    reportRecipient: reportRecipient ?? this.reportRecipient,
    gmailAddress: gmailAddress ?? this.gmailAddress,
    appPassword: appPassword ?? this.appPassword,
  );

  factory ReportRecipientConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReportRecipientConfig();

    final data = json.at<ReportRecipientConfig>();
    return ReportRecipientConfig(
      reportRecipient: data.parse<String?>('reportRecipient'),
      gmailAddress: data.parse<String?>('gmailAddress'),
      appPassword: data.parse<String?>('appPassword'),
    );
  }

  Map<String, dynamic> toJson() => {
    'reportRecipient': reportRecipient,
    'gmailAddress': gmailAddress,
    'appPassword': appPassword,
  };

  @override
  List<Object?> get props => [reportRecipient, gmailAddress, appPassword];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}

final class DistributionConfigModel extends BaseConfig {
  const DistributionConfigModel({
    this.emails = const [
      DistributionEmail(email: 'senpai331.rb@gmail.com', name: 'Senpai'),
      DistributionEmail(
        email: 'raohuraira331.rb@gmail.com',
        name: 'Huraira Younas',
      ),
    ],
    this.appstore = false,
    super.enabled = true,
    this.reportRecipient,
    this.drive = false,
    this.playstore,
  });

  final ReportRecipientConfig? reportRecipient;
  final PlayStoreDistribution? playstore;
  final List<DistributionEmail> emails;
  final bool appstore;
  final bool drive;

  factory DistributionConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DistributionConfigModel();

    final data = json.at<DistributionConfigModel>();
    return DistributionConfigModel(
      appstore: data.parse<bool>('appstore', defaultValue: Platform.isIOS),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      playstore: .fromString(data.parse<String?>('playstore')),
      emails: data.list('emails', DistributionEmail.fromJson),
      drive: data.parse<bool>('drive', defaultValue: false),
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
    List<DistributionEmail>? emails,
    bool clearPlaystore = false,
    bool? appstore,
    bool? enabled,
    bool? drive,
  }) => DistributionConfigModel(
    playstore: clearPlaystore ? null : playstore ?? this.playstore,
    reportRecipient: reportRecipient ?? this.reportRecipient,
    appstore: appstore ?? this.appstore,
    enabled: enabled ?? this.enabled,
    emails: emails ?? this.emails,
    drive: drive ?? this.drive,
  );

  @override
  List<Object?> get props => [
    reportRecipient,
    playstore,
    appstore,
    enabled,
    emails,
    drive,
  ];

  @override
  Map<String, dynamic> toJson() => {
    'emails': emails.map((e) => e.toJson()).toList(),
    'reportRecipient': reportRecipient?.toJson(),
    'playstore': playstore?.name,
    'appstore': appstore,
    'enabled': enabled,
    'drive': drive,
  };

  @override
  bool? get stringify => true;
}
