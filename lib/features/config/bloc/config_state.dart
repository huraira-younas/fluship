part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final AppInfoModel appInfo;
  final PreGitModel preGit;

  const ConfigState({
    super.loading = false,
    required this.appInfo,
    required this.preGit,
    super.error,
  });

  factory ConfigState.empty() =>
      const ConfigState(appInfo: AppInfoModel(), preGit: PreGitModel());

  @override
  List<Object> get props => [appInfo, preGit];

  @override
  ConfigState copyWith({
    AppInfoModel? appInfo,
    PreGitModel? preGit,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      loading: loading ?? this.loading,
      appInfo: appInfo ?? this.appInfo,
      preGit: preGit ?? this.preGit,
      error: error ?? this.error,
    );
  }
}
