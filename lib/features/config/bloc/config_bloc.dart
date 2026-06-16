import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends BaseBloc<ConfigEvent, ConfigState> {
  final _sharedPrefs = SharedPrefs.i;

  ConfigBloc() : super(ConfigState.empty()) {
    on<LoadConfig>(handler(_loadConfig));
    on<SaveConfig>(handler(_saveConfig));
  }

  Future<void> _loadConfig(Emitter<ConfigState> emit, LoadConfig event) async {
    emit(state.copyWith(loading: true));

    final appInfo = _sharedPrefs.getObject(.appInfo);

    emit(
      state.copyWith(
        loading: false,
        appInfo: appInfo != null
            ? AppInfoModel.fromJson(appInfo)
            : AppInfoModel(),
      ),
    );
  }

  Future<void> _saveConfig(Emitter<ConfigState> emit, SaveConfig event) async {
    emit(state.copyWith(loading: true));

    await _sharedPrefs.setObject(.appInfo, state.appInfo.toJson());
    emit(state.copyWith(loading: false));
  }
}
