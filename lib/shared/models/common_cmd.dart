import 'package:fluship/core/json_parser/exports.dart';
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

  factory CommonCmdModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CommonCmdModel();

    final data = json.at<CommonCmdModel>();
    return CommonCmdModel(
      enabled: data.parse<bool>('enabled', defaultValue: true),
      clean: data.parse<bool>('clean', defaultValue: false),
      type: .fromString(data.parse<String?>('type')),
    );
  }

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

  @override
  List<CommandStep> get steps => enabled
      ? [
          if (clean) const CommandStep(name: 'Clean', command: 'flutter clean'),
          if (type == .get)
            const CommandStep(name: 'Get', command: 'flutter pub get'),
          if (type == .upgrade)
            const CommandStep(name: 'Upgrade', command: 'flutter pub upgrade'),
        ]
      : [];
}
