part of 'config_bloc.dart';

class ConfigState extends BaseBlocState {
  final DistributionConfigModel distribution;
  final PostBuildConfigModel postBuild;
  final AndroidConfigModel android;
  final List<String> projectNames;
  final CommonCmdModel commonCmd;
  final String? activeProject;
  final PostGitModel postGit;
  final AppInfoModel appInfo;
  final IosConfigModel ios;
  final PreGitModel preGit;

  const ConfigState({
    required this.distribution,
    required this.commonCmd,
    required this.postBuild,
    required this.android,
    required this.postGit,
    required this.appInfo,
    required this.preGit,
    required this.ios,

    this.projectNames = const [],
    super.loading = false,
    this.activeProject,
    super.error,
  });

  factory ConfigState.empty() => ConfigState(
    distribution: const DistributionConfigModel(),
    postBuild: const PostBuildConfigModel(),
    android: const AndroidConfigModel(),
    commonCmd: const CommonCmdModel(),
    postGit: const PostGitModel(),
    appInfo: const AppInfoModel(),
    preGit: const PreGitModel(),
    projectNames: const [],
    ios: IosConfigModel(),
  );

  @override
  List<Object?> get props => [
    activeProject,
    projectNames,
    distribution,
    postBuild,
    commonCmd,
    postGit,
    android,
    appInfo,
    loading,
    preGit,
    error,
    ios,
  ];

  @override
  ConfigState copyWith({
    DistributionConfigModel? distribution,
    PostBuildConfigModel? postBuild,
    AndroidConfigModel? android,
    List<String>? projectNames,
    CommonCmdModel? commonCmd,
    String? activeProject,
    PostGitModel? postGit,
    AppInfoModel? appInfo,
    IosConfigModel? ios,
    PreGitModel? preGit,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      activeProject: activeProject ?? this.activeProject,
      distribution: distribution ?? this.distribution,
      projectNames: projectNames ?? this.projectNames,
      postBuild: postBuild ?? this.postBuild,
      commonCmd: commonCmd ?? this.commonCmd,
      android: android ?? this.android,
      postGit: postGit ?? this.postGit,
      appInfo: appInfo ?? this.appInfo,
      loading: loading ?? this.loading,
      preGit: preGit ?? this.preGit,
      ios: ios ?? this.ios,
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeProject': activeProject,
    'distribution': distribution.toJson(),
    'projectNames': projectNames,
    'postBuild': postBuild.toJson(),
    'commonCmd': commonCmd.toJson(),
    'android': android.toJson(),
    'postGit': postGit.toJson(),
    'appInfo': appInfo.toJson(),
    'preGit': preGit.toJson(),
    'ios': ios.toJson(),
  };

  factory ConfigState.fromJson(Map<String, dynamic> json) => ConfigState(
    projectNames: List<String>.from(json['projectNames'] as List? ?? const []),
    distribution: DistributionConfigModel.fromJson(json['distribution']),
    postBuild: PostBuildConfigModel.fromJson(json['postBuild']),
    commonCmd: CommonCmdModel.fromJson(json['commonCmd']),
    android: AndroidConfigModel.fromJson(json['android']),
    activeProject: json['activeProject'] as String?,
    postGit: PostGitModel.fromJson(json['postGit']),
    appInfo: AppInfoModel.fromJson(json['appInfo']),
    preGit: PreGitModel.fromJson(json['preGit']),
    ios: IosConfigModel.fromJson(json['ios']),
  );
}
