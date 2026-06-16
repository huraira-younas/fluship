import 'base_config.dart';

enum AndroidBuildType {
  apk,
  arbs;

  static AndroidBuildType? fromString(String? value) => switch (value) {
    'arbs' => .arbs,
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

  factory AndroidConfigModel.fromJson(Map<String, dynamic>? json) =>
      AndroidConfigModel(
        buildType: AndroidBuildType.fromString(json?['buildType'] as String?),
        buildAab: json?['buildAab'] as bool? ?? false,
        enabled: json?['enabled'] as bool? ?? true,
      );

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
