import 'package:fluship/core/json_parser/json_map_parser.dart';
import 'package:equatable/equatable.dart';
import 'base_config.dart';

enum PowerAction {
  shutdown,
  sleep,
  lock;

  static PowerAction? fromString(String? value) => switch (value) {
    'shutdown' => .shutdown,
    'sleep' => .sleep,
    'lock' => .lock,
    _ => null,
  };
}

class PowerConfig extends Equatable {
  const PowerConfig({
    this.delay = const Duration(seconds: 10),
    this.action = .shutdown,
  });

  final PowerAction action;
  final Duration delay;

  @override
  List<Object?> get props => [action, delay];

  PowerConfig copyWith({PowerAction? action, Duration? delay}) =>
      PowerConfig(action: action ?? this.action, delay: delay ?? this.delay);

  factory PowerConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PowerConfig();

    final data = json.at<PowerConfig>();
    return PowerConfig(
      delay: Duration(seconds: data.parse<int>('delay', defaultValue: 10)),
      action: .fromString(data.parse<String?>('action')) ?? .shutdown,
    );
  }

  Map<String, dynamic> toJson() => {
    'delay': delay.inSeconds,
    'action': action.name,
  };

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}

class PostBuildConfigModel extends BaseConfig {
  const PostBuildConfigModel({
    this.openOutputs = false,
    super.enabled = true,
    this.powerConfig,
  });

  final PowerConfig? powerConfig;
  final bool openOutputs;

  factory PostBuildConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PostBuildConfigModel();

    final data = json.at<PostBuildConfigModel>();
    return PostBuildConfigModel(
      powerConfig: data.objectOrNull(PowerConfig.fromJson, 'powerConfig'),
      openOutputs: data.parse<bool>('openOutputs', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
    );
  }

  @override
  PostBuildConfigModel copyWith({
    bool clearPowerConfig = false,
    PowerConfig? powerConfig,
    bool? openOutputs,
    bool? enabled,
  }) {
    return PostBuildConfigModel(
      powerConfig: clearPowerConfig ? null : powerConfig ?? this.powerConfig,
      openOutputs: openOutputs ?? this.openOutputs,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'powerConfig': powerConfig?.toJson(),
    'openOutputs': openOutputs,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [enabled, powerConfig, openOutputs];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
