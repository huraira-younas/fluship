part of 'config_bloc.dart';

sealed class ConfigEvent extends BaseBlocEvent {
  const ConfigEvent({required super.name, super.onError, super.onSuccess});
}

class LoadConfig extends ConfigEvent {
  const LoadConfig({super.onError, super.onSuccess})
    : super(name: 'Load_Config');

  @override
  Map<String, dynamic> toJson() => {};
}

class SaveConfig extends ConfigEvent {
  const SaveConfig({super.onError, super.onSuccess})
    : super(name: 'Save_Config');

  @override
  Map<String, dynamic> toJson() => {};
}

class UpdateConfig extends ConfigEvent {
  final BaseConfig config;
  const UpdateConfig({required this.config, super.onSuccess, super.onError})
    : super(name: 'Update_Config');

  @override
  Map<String, dynamic> toJson() => {
    "type": config.runtimeType.toString(),
    ...config.toJson(),
  };
}
