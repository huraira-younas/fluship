part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final AppInfoModel appInfo;

  const ConfigState({
    super.loading = false,
    required this.appInfo,
    super.error,
  });

  factory ConfigState.empty() => const ConfigState(appInfo: AppInfoModel());

  @override
  List<Object> get props => [appInfo];

  @override
  ConfigState copyWith({
    AppInfoModel? appInfo,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      appInfo: appInfo ?? this.appInfo,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}
