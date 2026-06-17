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
  const DistributionEmail({required this.email, required this.name});

  final String email;
  final String name;

  factory DistributionEmail.fromJson(Map<String, dynamic> json) {
    final data = json.at<DistributionEmail>();
    return DistributionEmail(
      email: data.parse<String>('email'),
      name: data.parse<String>('name'),
    );
  }

  DistributionEmail copyWith({String? email, String? name}) =>
      DistributionEmail(email: email ?? this.email, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'email': email, 'name': name};

  @override
  List<Object?> get props => [email, name];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}

final class DistributionConfigModel extends BaseConfig {
  const DistributionConfigModel({
    this.emails = const [],
    this.appstore = false,
    super.enabled = true,
    this.drive = false,
    this.playstore,
  });

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
    );
  }

  @override
  DistributionConfigModel copyWith({
    PlayStoreDistribution? playstore,
    List<DistributionEmail>? emails,
    bool clearPlaystore = false,
    bool? appstore,
    bool? enabled,
    bool? drive,
  }) => DistributionConfigModel(
    playstore: clearPlaystore ? null : playstore ?? this.playstore,
    appstore: appstore ?? this.appstore,
    enabled: enabled ?? this.enabled,
    emails: emails ?? this.emails,
    drive: drive ?? this.drive,
  );

  @override
  List<Object?> get props => [playstore, emails, appstore, drive, enabled];

  @override
  Map<String, dynamic> toJson() => {
    'emails': emails.map((e) => e.toJson()).toList(),
    'playstore': playstore?.name,
    'appstore': appstore,
    'enabled': enabled,
    'drive': drive,
  };

  @override
  bool? get stringify => true;
}
