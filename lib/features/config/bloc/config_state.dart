part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final AndroidConfigModel android;
  final CommonCmdModel commonCmd;
  final PostGitModel postGit;
  final AppInfoModel appInfo;
  final IosConfigModel ios;
  final PreGitModel preGit;

  const ConfigState({
    required this.commonCmd,
    super.loading = false,
    required this.android,
    required this.postGit,
    required this.appInfo,
    required this.preGit,
    required this.ios,
    super.error,
  });

  factory ConfigState.empty() => const ConfigState(
    android: AndroidConfigModel(),
    commonCmd: CommonCmdModel(),
    postGit: PostGitModel(),
    appInfo: AppInfoModel(),
    preGit: PreGitModel(),
    ios: IosConfigModel(),
  );

  @override
  List<Object> get props => [android, commonCmd, postGit, appInfo, preGit, ios];

  @override
  ConfigState copyWith({
    AndroidConfigModel? android,
    CommonCmdModel? commonCmd,
    PostGitModel? postGit,
    AppInfoModel? appInfo,
    PreGitModel? preGit,
    IosConfigModel? ios,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      commonCmd: commonCmd ?? this.commonCmd,
      android: android ?? this.android,
      loading: loading ?? this.loading,
      postGit: postGit ?? this.postGit,
      appInfo: appInfo ?? this.appInfo,
      preGit: preGit ?? this.preGit,
      error: error ?? this.error,
      ios: ios ?? this.ios,
    );
  }
}
