import 'package:fluship/core/json_parser/exports.dart';
import 'package:equatable/equatable.dart';
import 'base_config.dart';

enum AndroidBuildType {
  arbs,
  apk;

  static AndroidBuildType? fromString(String? value) => switch (value) {
    'arbs' => .arbs,
    'apk' => .apk,
    _ => null,
  };
}

class GooglePlayConsoleConfig extends Equatable {
  final String? packageName;
  final String saJsonPath;

  const GooglePlayConsoleConfig({
    required this.packageName,
    required this.saJsonPath,
  });

  GooglePlayConsoleConfig copyWith({String? packageName, String? saJsonPath}) =>
      GooglePlayConsoleConfig(
        packageName: packageName ?? this.packageName,
        saJsonPath: saJsonPath ?? this.saJsonPath,
      );

  factory GooglePlayConsoleConfig.fromJson(Map<String, dynamic> json) {
    final data = json.at<GooglePlayConsoleConfig>();
    return GooglePlayConsoleConfig(
      packageName: data.parse<String?>('packageName'),
      saJsonPath: data.parse<String>('saJsonPath'),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'saJsonPath': saJsonPath,
  };
  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [packageName, saJsonPath];
}

final class AndroidConfigModel extends BaseConfig {
  const AndroidConfigModel({
    this.buildAab = false,
    super.enabled = true,
    this.buildType,
    this.gpConfig,
  });

  final GooglePlayConsoleConfig? gpConfig;
  final AndroidBuildType? buildType;
  final bool buildAab;

  factory AndroidConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AndroidConfigModel();

    final data = json.at<AndroidConfigModel>();
    return AndroidConfigModel(
      gpConfig: data.objectOrNull(GooglePlayConsoleConfig.fromJson, 'gpConfig'),
      buildAab: data.parse<bool>('buildAab', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      buildType: .fromString(data.parse<String?>('buildType')),
    );
  }

  @override
  AndroidConfigModel copyWith({
    GooglePlayConsoleConfig? gpConfig,
    AndroidBuildType? buildType,
    bool clearBuildType = false,
    bool? buildAab,
    bool? enabled,
  }) {
    return AndroidConfigModel(
      buildType: clearBuildType ? null : buildType ?? this.buildType,
      gpConfig: gpConfig ?? this.gpConfig,
      buildAab: buildAab ?? this.buildAab,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'gpConfig': gpConfig?.toJson(),
    'buildType': buildType?.name,
    'buildAab': buildAab,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [gpConfig, buildType, buildAab, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
