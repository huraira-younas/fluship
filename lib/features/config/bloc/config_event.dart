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

class UpdateBuildConfig extends ConfigEvent {
  final AppInfoModel appInfo;
  const UpdateBuildConfig({
    required this.appInfo,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Update_Build_Config');

  @override
  Map<String, dynamic> toJson() => appInfo.toJson();
}
