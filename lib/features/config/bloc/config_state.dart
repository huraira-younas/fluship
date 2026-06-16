part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final AndroidConfigModel android;
  final CommonCmdModel commonCmd;
  final AppInfoModel appInfo;
  final PreGitModel preGit;

  const ConfigState({
    required this.commonCmd,
    super.loading = false,
    required this.android,
    required this.appInfo,
    required this.preGit,
    super.error,
  });

  factory ConfigState.empty() => const ConfigState(
    android: AndroidConfigModel(),
    commonCmd: CommonCmdModel(),
    appInfo: AppInfoModel(),
    preGit: PreGitModel(),
  );

  @override
  List<Object> get props => [android, commonCmd, appInfo, preGit];

  @override
  ConfigState copyWith({
    AndroidConfigModel? android,
    CommonCmdModel? commonCmd,
    AppInfoModel? appInfo,
    PreGitModel? preGit,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      commonCmd: commonCmd ?? this.commonCmd,
      android: android ?? this.android,
      loading: loading ?? this.loading,
      appInfo: appInfo ?? this.appInfo,
      preGit: preGit ?? this.preGit,
      error: error ?? this.error,
    );
  }
}
