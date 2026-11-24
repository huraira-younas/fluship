part of 'config_bloc.dart';

sealed class const ConfigEvent({
  required super.name,
  super.onError,
  super.onSuccess,
}) extends BaseBlocEvent;

class const LoadConfig({super.onError, super.onSuccess}) extends ConfigEvent {
  this : super(name: 'Load_Config');

  @override
  Map<String, dynamic> toJson() => {};
}

class const SaveConfig({super.onError, super.onSuccess}) extends ConfigEvent {
  this : super(name: 'Save_Config');

  @override
  Map<String, dynamic> toJson() => {};
}

class const StartNewProfile({super.onError, super.onSuccess})
    extends ConfigEvent {
  this : super(name: 'Start_New_Profile');

  @override
  Map<String, dynamic> toJson() => {};
}

class const DeleteProjectProfile({
  required final String projectName,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Delete_Project_Profile');

  @override
  Map<String, dynamic> toJson() => {'project_name': projectName};
}

class const SwitchProjectProfile({
  required final String projectName,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Switch_Project_Profile');

  @override
  Map<String, dynamic> toJson() => {'project_name': projectName};
}

class const SyncProjectAppInfo({
  required final String flutterProjectPath,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Sync_Project_App_Info');

  @override
  Map<String, dynamic> toJson() => {'flutter_project_path': flutterProjectPath};
}

class const UpdateConfig({
  required final BaseConfig config,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Update_Config');

  @override
  Map<String, dynamic> toJson() => {
    "type": config.runtimeType.toString(),
    ...config.toJson(),
  };
}

class const UpdateConfigs({
  required final List<BaseConfig> configs,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Update_Configs');

  @override
  Map<String, dynamic> toJson() => {
    'types': configs.map((config) => config.runtimeType.toString()).toList(),
  };
}

class const ImportConfig({
  required final Map<String, dynamic> data,
  super.onSuccess,
  super.onError,
}) extends ConfigEvent {
  this : super(name: 'Import_Config');

  @override
  Map<String, dynamic> toJson() => {'keys': data.keys.toList()};
}
