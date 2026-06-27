import 'package:fluship/core/json_parser/exports.dart';
import 'base_config.dart';

enum AndroidBuildType {
  splits,
  apk;

  static AndroidBuildType? fromString(String? value) => switch (value) {
    'splits' => .splits,
    'apk' => .apk,
    _ => null,
  };
}

final class AndroidConfigModel extends BaseConfig {
  const AndroidConfigModel({
    this.buildAab = false,
    super.enabled = true,
    this.buildType,
  });

  final AndroidBuildType? buildType;
  final bool buildAab;

  factory AndroidConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AndroidConfigModel();

    final data = json.at<AndroidConfigModel>();
    return AndroidConfigModel(
      buildAab: data.parse<bool>('buildAab', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      buildType: .fromString(data.parse<String?>('buildType')),
    );
  }

  @override
  AndroidConfigModel copyWith({
    AndroidBuildType? buildType,
    bool clearBuildType = false,
    bool? buildAab,
    bool? enabled,
  }) {
    return AndroidConfigModel(
      buildType: clearBuildType ? null : buildType ?? this.buildType,
      buildAab: buildAab ?? this.buildAab,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'buildType': buildType?.name,
    'buildAab': buildAab,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [buildType, buildAab, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
