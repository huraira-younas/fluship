import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/models/base_config.dart';
import 'package:fluship/shared/models/ios_config.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/pre_git.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends BaseBloc<ConfigEvent, ConfigState> {
  final _projectService = const FlutterProjectService();
  final _sharedPrefs = SharedPrefs.i;

  ConfigBloc() : super(ConfigState.empty()) {
    on<SyncProjectAppInfo>(handler(_syncProjectAppInfo));
    on<UpdateConfigs>(handler(_updateConfigs));
    on<UpdateConfig>(handler(_updateConfig));
    on<LoadConfig>(handler(_loadConfig));
    on<SaveConfig>(handler(_saveConfig));
  }

  ConfigState _applyConfig(ConfigState current, BaseConfig config) {
    return switch (config) {
      PostBuildConfigModel postBuild => current.copyWith(postBuild: postBuild),
      CommonCmdModel commonCmd => current.copyWith(commonCmd: commonCmd),
      AndroidConfigModel android => current.copyWith(android: android),
      AppInfoModel appInfo => current.copyWith(appInfo: appInfo),
      PostGitModel postGit => current.copyWith(postGit: postGit),
      PreGitModel preGit => current.copyWith(preGit: preGit),
      IosConfigModel ios => current.copyWith(ios: ios),
      DistributionConfigModel distribution => current.copyWith(
        distribution: distribution,
      ),

      _ => throw UnsupportedError('Invalid config type: ${config.runtimeType}'),
    };
  }

  Future<void> _persistConfig(BaseConfig config) async {
    switch (config) {
      case AppInfoModel appInfo:
        await _sharedPrefs.setObject(.appInfo, appInfo.toJson());

      case PreGitModel preGit:
        await _sharedPrefs.setObject(.preGit, preGit.toJson());

      case CommonCmdModel commonCmd:
        await _sharedPrefs.setObject(.commonCmd, commonCmd.toJson());

      case AndroidConfigModel android:
        await _sharedPrefs.setObject(.android, android.toJson());

      case IosConfigModel ios:
        await _sharedPrefs.setObject(.ios, ios.toJson());

      case PostGitModel postGit:
        await _sharedPrefs.setObject(.postGit, postGit.toJson());

      case DistributionConfigModel distribution:
        await _sharedPrefs.setObject(.distribution, distribution.toJson());

      case PostBuildConfigModel postBuild:
        await _sharedPrefs.setObject(.postBuild, postBuild.toJson());

      default:
        throw UnsupportedError('Invalid config type: ${config.runtimeType}');
    }
  }

  Future<void> _updateConfig(
    Emitter<ConfigState> emit,
    UpdateConfig event,
  ) async {
    final updated = _applyConfig(state, event.config);
    emit(updated);
    await _persistConfig(event.config);
  }

  Future<void> _updateConfigs(
    Emitter<ConfigState> emit,
    UpdateConfigs event,
  ) async {
    var updated = state;
    for (final config in event.configs) {
      updated = _applyConfig(updated, config);
    }

    emit(updated);
    await Future.wait([
      for (final config in event.configs) _persistConfig(config),
    ]);
  }

  Future<void> _loadConfig(Emitter<ConfigState> emit, LoadConfig event) async {
    emit(state.copyWith(loading: true));

    final distribution = _sharedPrefs.getObject(.distribution);
    final savedAppInfo = _sharedPrefs.getObject(.appInfo);
    final postBuild = _sharedPrefs.getObject(.postBuild);
    final commonCmd = _sharedPrefs.getObject(.commonCmd);
    final android = _sharedPrefs.getObject(.android);
    final postGit = _sharedPrefs.getObject(.postGit);
    final preGit = _sharedPrefs.getObject(.preGit);
    final ios = _sharedPrefs.getObject(.ios);

    var appInfo = savedAppInfo != null
        ? AppInfoModel.fromJson(savedAppInfo)
        : const AppInfoModel();

    final path = appInfo.flutterProjectPath ?? '';
    if (path.isNotEmpty) {
      appInfo = await _projectService.extractAppInfo(
        flutterProjectPath: path,
        base: appInfo,
      );

      await _sharedPrefs.setObject(.appInfo, appInfo.toJson());
    }

    emit(
      state.copyWith(
        distribution: .fromJson(distribution),
        commonCmd: .fromJson(commonCmd),
        postBuild: .fromJson(postBuild),
        postGit: .fromJson(postGit),
        android: .fromJson(android),
        preGit: .fromJson(preGit),
        ios: .fromJson(ios),
        appInfo: appInfo,
        loading: false,
      ),
    );
  }

  Future<void> _syncProjectAppInfo(
    Emitter<ConfigState> emit,
    SyncProjectAppInfo event,
  ) async {
    final appInfo = await _projectService.extractAppInfo(
      flutterProjectPath: event.flutterProjectPath,
      base: state.appInfo,
    );

    await _sharedPrefs.setObject(.appInfo, appInfo.toJson());
    emit(state.copyWith(appInfo: appInfo));
  }

  Future<void> persistCurrentConfig() async {
    await Future.wait([
      _sharedPrefs.setObject(.distribution, state.distribution.toJson()),
      _sharedPrefs.setObject(.commonCmd, state.commonCmd.toJson()),
      _sharedPrefs.setObject(.postBuild, state.postBuild.toJson()),
      _sharedPrefs.setObject(.android, state.android.toJson()),
      _sharedPrefs.setObject(.appInfo, state.appInfo.toJson()),
      _sharedPrefs.setObject(.postGit, state.postGit.toJson()),
      _sharedPrefs.setObject(.preGit, state.preGit.toJson()),
      _sharedPrefs.setObject(.ios, state.ios.toJson()),
    ]);
  }

  Future<void> _saveConfig(Emitter<ConfigState> emit, SaveConfig event) async {
    await persistCurrentConfig();
  }
}
