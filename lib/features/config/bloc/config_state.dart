part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final DistributionConfigModel distribution;
  final AndroidConfigModel android;
  final CommonCmdModel commonCmd;
  final PostGitModel postGit;
  final AppInfoModel appInfo;
  final IosConfigModel ios;
  final PreGitModel preGit;

  const ConfigState({
    required this.distribution,
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
    distribution: DistributionConfigModel(),
    android: AndroidConfigModel(),
    commonCmd: CommonCmdModel(),
    postGit: PostGitModel(),
    appInfo: AppInfoModel(),
    preGit: PreGitModel(),
    ios: IosConfigModel(),
  );

  @override
  List<Object> get props => [
    distribution,
    commonCmd,
    postGit,
    android,
    appInfo,
    preGit,
    ios,
  ];

  @override
  ConfigState copyWith({
    DistributionConfigModel? distribution,
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
      distribution: distribution ?? this.distribution,
      commonCmd: commonCmd ?? this.commonCmd,
      android: android ?? this.android,
      postGit: postGit ?? this.postGit,
      appInfo: appInfo ?? this.appInfo,
      preGit: preGit ?? this.preGit,
      loading: loading ?? false,
      ios: ios ?? this.ios,
      error: error,
    );
  }
}
