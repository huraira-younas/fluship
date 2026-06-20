import 'dart:io' show Platform;

import 'package:fluship/core/json_parser/exports.dart';
import 'base_config.dart';

final class IosConfigModel extends BaseConfig {
  IosConfigModel({
    this.podClean = false,
    this.buildIpa = false,
    bool enabled = true,
  }) : super(enabled: Platform.isMacOS ? enabled : false);

  final bool podClean;
  final bool buildIpa;

  factory IosConfigModel.fromJson(Map<String, dynamic> json) {
    final data = json.at<IosConfigModel>();
    return IosConfigModel(
      podClean: data.parse<bool>('podClean', defaultValue: false),
      buildIpa: data.parse<bool>('buildIpa', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
    );
  }

  @override
  IosConfigModel copyWith({bool? podClean, bool? buildIpa, bool? enabled}) {
    return IosConfigModel(
      podClean: podClean ?? this.podClean,
      buildIpa: buildIpa ?? this.buildIpa,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'podClean': podClean,
    'buildIpa': buildIpa,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [podClean, buildIpa, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
