import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/models/ios_config.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:fluship/shared/models/pre_git.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';

class FlushipConfigExport {
  const FlushipConfigExport({
    required this.distribution,
    required this.postBuild,
    required this.commonCmd,
    required this.android,
    required this.postGit,
    required this.appInfo,
    required this.preGit,
    required this.ios,
  });

  final DistributionConfigModel distribution;
  final PostBuildConfigModel postBuild;
  final AndroidConfigModel android;
  final CommonCmdModel commonCmd;
  final PostGitModel postGit;
  final AppInfoModel appInfo;
  final IosConfigModel ios;
  final PreGitModel preGit;

  factory FlushipConfigExport.fromState(ConfigState state) =>
      FlushipConfigExport(
        distribution: state.distribution,
        postBuild: state.postBuild,
        commonCmd: state.commonCmd,
        android: state.android,
        postGit: state.postGit,
        appInfo: state.appInfo,
        preGit: state.preGit,
        ios: state.ios,
      );

  factory FlushipConfigExport.fromJson(Map<String, dynamic> json) =>
      FlushipConfigExport(
        distribution: DistributionConfigModel.fromJson(json['distribution']),
        postBuild: PostBuildConfigModel.fromJson(json['post_build']),
        android: AndroidConfigModel.fromJson(json['android']),
        commonCmd: CommonCmdModel.fromJson(json['common_cmd']),
        appInfo: AppInfoModel.fromJson(json['app_info']),
        postGit: PostGitModel.fromJson(json['post_git']),
        preGit: PreGitModel.fromJson(json['pre_git']),
        ios: IosConfigModel.fromJson(json['ios']),
      );

  ConfigState toState() => ConfigState(
    distribution: distribution,
    postBuild: postBuild,
    commonCmd: commonCmd,
    android: android,
    postGit: postGit,
    appInfo: appInfo,
    preGit: preGit,
    ios: ios,
  );

  Map<String, dynamic> toJson() => {
    'distribution': distribution.toJson(),
    'post_build': postBuild.toJson(),
    'common_cmd': commonCmd.toJson(),
    'app_info': appInfo.toJson(),
    'post_git': postGit.toJson(),
    'android': android.toJson(),
    'pre_git': preGit.toJson(),
    'ios': ios.toJson(),
  };
}
