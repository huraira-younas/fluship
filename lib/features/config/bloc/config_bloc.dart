import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/shared/models/base_config.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/pre_git.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends BaseBloc<ConfigEvent, ConfigState> {
  final _sharedPrefs = SharedPrefs.i;

  ConfigBloc() : super(ConfigState.empty()) {
    on<UpdateConfig>(handler(_updateConfig));
    on<LoadConfig>(handler(_loadConfig));
    on<SaveConfig>(handler(_saveConfig));
  }

  void _updateConfig(Emitter<ConfigState> emit, UpdateConfig event) {
    switch (event.config) {
      case AppInfoModel():
        emit(state.copyWith(appInfo: event.config as AppInfoModel));
      case PreGitModel():
        emit(state.copyWith(preGit: event.config as PreGitModel));
      default:
        throw Exception('Invalid config type: ${event.config.runtimeType}');
    }
  }

  Future<void> _loadConfig(Emitter<ConfigState> emit, LoadConfig event) async {
    emit(state.copyWith(loading: true));

    final appInfo = _sharedPrefs.getObject(.appInfo);
    final preGit = _sharedPrefs.getObject(.preGit);

    emit(
      state.copyWith(
        loading: false,
        preGit: preGit != null
            ? PreGitModel.fromJson(preGit)
            : const PreGitModel(),
        appInfo: appInfo != null
            ? AppInfoModel.fromJson(appInfo)
            : const AppInfoModel(),
      ),
    );
  }

  Future<void> _saveConfig(Emitter<ConfigState> emit, SaveConfig event) async {
    emit(state.copyWith(loading: true));

    await Future.wait([
      _sharedPrefs.setObject(.appInfo, state.appInfo.toJson()),
      _sharedPrefs.setObject(.preGit, state.preGit.toJson()),
    ]);

    emit(state.copyWith(loading: false));
  }
}
