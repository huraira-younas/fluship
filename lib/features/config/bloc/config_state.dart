part of 'config_bloc.dart';

class const ConfigState({
  required final DistributionConfigModel distribution,
  required final CommonCmdModel commonCmd,
  required final PostBuildConfigModel postBuild,
  required final AndroidConfigModel android,
  required final PostGitModel postGit,
  required final AppInfoModel appInfo,
  required final PreGitModel preGit,
  required final IosConfigModel ios,

  final List<String> projectNames = const [],
  final bool pendingImport = false,
  super.loading = false,
  final String? activeProject,
  super.error,
}) extends BaseBlocState {
  factory empty() => ConfigState(
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
    pendingImport,
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
    bool? pendingImport,
    IosConfigModel? ios,
    PreGitModel? preGit,
    CustomState? error,
    bool? loading,
  }) {
    return ConfigState(
      activeProject: activeProject ?? this.activeProject,
      pendingImport: pendingImport ?? this.pendingImport,
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
    'distribution': distribution.toJson(),
    'postBuild': postBuild.toJson(),
    'commonCmd': commonCmd.toJson(),
    'activeProject': activeProject,
    'projectNames': projectNames,
    'android': android.toJson(),
    'postGit': postGit.toJson(),
    'appInfo': appInfo.toJson(),
    'preGit': preGit.toJson(),
    'ios': ios.toJson(),
  };

  factory fromJson(Map<String, dynamic> json) => ConfigState(
    commonCmd: CommonCmdModel.fromJson(json['commonCmd'] ?? json['common_cmd']),
    projectNames: List<String>.from(json['projectNames'] as List? ?? const []),
    distribution: DistributionConfigModel.fromJson(json['distribution']),
    postGit: PostGitModel.fromJson(json['postGit'] ?? json['post_git']),
    appInfo: AppInfoModel.fromJson(json['appInfo'] ?? json['app_info']),
    preGit: PreGitModel.fromJson(json['preGit'] ?? json['pre_git']),
    android: AndroidConfigModel.fromJson(json['android']),
    activeProject: json['activeProject'] as String?,
    ios: IosConfigModel.fromJson(json['ios']),
    postBuild: PostBuildConfigModel.fromJson(
      json['postBuild'] ?? json['post_build'],
    ),
  );
}
