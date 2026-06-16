import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';

import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    on<UpdateConfig>(handler(_updateConfig));
    on<LoadConfig>(handler(_loadConfig));
    on<SaveConfig>(handler(_saveConfig));
  }

  Future<void> _updateConfig(
    Emitter<ConfigState> emit,
    UpdateConfig event,
  ) async {
    switch (event.config) {
      case AppInfoModel():
        final appInfo = event.config as AppInfoModel;
        emit(state.copyWith(appInfo: appInfo));
        await _sharedPrefs.setObject(.appInfo, appInfo.toJson());
      case PreGitModel():
        final preGit = event.config as PreGitModel;
        emit(state.copyWith(preGit: preGit));
        await _sharedPrefs.setObject(.preGit, preGit.toJson());
      case CommonCmdModel():
        final commonCmd = event.config as CommonCmdModel;
        emit(state.copyWith(commonCmd: commonCmd));
        await _sharedPrefs.setObject(.commonCmd, commonCmd.toJson());
      case AndroidConfigModel():
        final android = event.config as AndroidConfigModel;
        emit(state.copyWith(android: android));
        await _sharedPrefs.setObject(.android, android.toJson());
      case IosConfigModel():
        final ios = event.config as IosConfigModel;
        emit(state.copyWith(ios: ios));
        await _sharedPrefs.setObject(.ios, ios.toJson());
      case PostGitModel():
        final postGit = event.config as PostGitModel;
        emit(state.copyWith(postGit: postGit));
        await _sharedPrefs.setObject(.postGit, postGit.toJson());
      default:
        throw Exception('Invalid config type: ${event.config.runtimeType}');
    }
  }

  Future<void> _loadConfig(Emitter<ConfigState> emit, LoadConfig event) async {
    emit(state.copyWith(loading: true));

    final savedAppInfo = _sharedPrefs.getObject(.appInfo);
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
        commonCmd: .fromJson(commonCmd),
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

  Future<void> _saveConfig(Emitter<ConfigState> emit, SaveConfig event) async {
    await Future.wait([
      _sharedPrefs.setObject(.commonCmd, state.commonCmd.toJson()),
      _sharedPrefs.setObject(.android, state.android.toJson()),
      _sharedPrefs.setObject(.appInfo, state.appInfo.toJson()),
      _sharedPrefs.setObject(.postGit, state.postGit.toJson()),
      _sharedPrefs.setObject(.preGit, state.preGit.toJson()),
      _sharedPrefs.setObject(.ios, state.ios.toJson()),
    ]);
  }
}
