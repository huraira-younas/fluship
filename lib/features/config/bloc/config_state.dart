part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final CommonCmdModel commonCmd;
  final AppInfoModel appInfo;
  final PreGitModel preGit;

  const ConfigState({
    required this.commonCmd,
    super.loading = false,
    required this.appInfo,
    required this.preGit,
    super.error,
  });

  factory ConfigState.empty() => const ConfigState(
    commonCmd: CommonCmdModel(),
    appInfo: AppInfoModel(),
    preGit: PreGitModel(),
  );

  @override
  List<Object> get props => [commonCmd, appInfo, preGit];

  @override
  ConfigState copyWith({
    CommonCmdModel? commonCmd,
    AppInfoModel? appInfo,
    PreGitModel? preGit,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      commonCmd: commonCmd ?? this.commonCmd,
      loading: loading ?? this.loading,
      appInfo: appInfo ?? this.appInfo,
      preGit: preGit ?? this.preGit,
      error: error ?? this.error,
    );
  }
}
