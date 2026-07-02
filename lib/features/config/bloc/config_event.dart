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

class SyncProjectAppInfo extends ConfigEvent {
  const SyncProjectAppInfo({
    required this.flutterProjectPath,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Sync_Project_App_Info');

  final String flutterProjectPath;

  @override
  Map<String, dynamic> toJson() => {'flutter_project_path': flutterProjectPath};
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

class UpdateConfigs extends ConfigEvent {
  const UpdateConfigs({required this.configs, super.onSuccess, super.onError})
    : super(name: 'Update_Configs');

  final List<BaseConfig> configs;

  @override
  Map<String, dynamic> toJson() => {
    'types': configs.map((config) => config.runtimeType.toString()).toList(),
  };
}

class ImportConfig extends ConfigEvent {
  const ImportConfig({required this.data, super.onSuccess, super.onError})
    : super(name: 'Import_Config');

  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() => {'keys': data.keys.toList()};
}
