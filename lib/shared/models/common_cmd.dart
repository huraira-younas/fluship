import 'base_config.dart';

enum FlutterGetType {
  get,
  upgrade;

  static FlutterGetType? fromString(String? value) => switch (value) {
    'upgrade' => .upgrade,
    'get' => .get,
    _ => null,
  };
}

final class CommonCmdModel extends BaseConfig {
  const CommonCmdModel({super.enabled = true, this.clean = false, this.type});

  final FlutterGetType? type;
  final bool clean;

  @override
  CommonCmdModel copyWith({
    bool clearType = false,
    FlutterGetType? type,
    bool? enabled,
    bool? clean,
  }) => CommonCmdModel(
    type: clearType ? null : type ?? this.type,
    enabled: enabled ?? this.enabled,
    clean: clean ?? this.clean,
  );

  factory CommonCmdModel.fromJson(Map<String, dynamic> json) => CommonCmdModel(
    type: FlutterGetType.fromString(json['type'] as String?),
    enabled: json['enabled'] as bool? ?? true,
    clean: json['clean'] as bool? ?? false,
  );

  @override
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'type': type?.name,
    'clean': clean,
  };

  @override
  List<Object?> get props => [type, clean, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
