import 'package:fluship/core/json_parser/exports.dart';

import 'base_config.dart';

final class const AppInfoModel({
  final String? flushipWorkspacePath,
  final String? flutterProjectPath,
  super.enabled = true,
  final String? appIconPath,
  final String? buildNumber,
  final String? projectName,
  final String? version,
  final String? appName,
}) extends BaseConfig {
  @override
  AppInfoModel copyWith({
    String? flushipWorkspacePath,
    String? flutterProjectPath,
    String? appIconPath,
    String? buildNumber,
    String? projectName,
    String? version,
    String? appName,
    bool? enabled,
  }) => AppInfoModel(
    flushipWorkspacePath: flushipWorkspacePath ?? this.flushipWorkspacePath,
    flutterProjectPath: flutterProjectPath ?? this.flutterProjectPath,
    appIconPath: appIconPath ?? this.appIconPath,
    buildNumber: buildNumber ?? this.buildNumber,
    projectName: projectName ?? this.projectName,
    enabled: enabled ?? this.enabled,
    version: version ?? this.version,
    appName: appName ?? this.appName,
  );

  factory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppInfoModel();

    final data = json.at<AppInfoModel>();
    return AppInfoModel(
      flushipWorkspacePath: data.parse<String?>('fluship_workspace_path'),
      flutterProjectPath: data.parse<String?>('flutter_project_path'),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      buildNumber: data.parse<String?>('build_number'),
      projectName: data.parse<String?>('project_name'),
      appName: data.parse<String?>('app_name'),
      version: data.parse<String?>('version'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'fluship_workspace_path': flushipWorkspacePath,
    'flutter_project_path': flutterProjectPath,
    'project_name': projectName,
    'build_number': buildNumber,
    'app_name': appName,
    'enabled': enabled,
    'version': version,
  };

  @override
  List<Object?> get props => [
    flushipWorkspacePath,
    flutterProjectPath,
    appIconPath,
    projectName,
    buildNumber,
    appName,
    enabled,
    version,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
