import 'package:fluship/core/json_parser/exports.dart';
import 'base_config.dart';

final class AppInfoModel extends BaseConfig {
  const AppInfoModel({
    this.flushipWorkspacePath,
    this.flutterProjectPath,
    this.buildNumber,
    this.projectName,
    super.enabled = true,
    this.version,
    this.appName,
  });

  final String? flushipWorkspacePath;
  final String? flutterProjectPath;
  final String? projectName;
  final String? buildNumber;
  final String? version;
  final String? appName;

  @override
  AppInfoModel copyWith({
    String? flushipWorkspacePath,
    String? flutterProjectPath,
    String? buildNumber,
    String? projectName,
    bool? enabled,
    String? version,
    String? appName,
  }) => AppInfoModel(
    flushipWorkspacePath: flushipWorkspacePath ?? this.flushipWorkspacePath,
    flutterProjectPath: flutterProjectPath ?? this.flutterProjectPath,
    buildNumber: buildNumber ?? this.buildNumber,
    projectName: projectName ?? this.projectName,
    enabled: enabled ?? this.enabled,
    version: version ?? this.version,
    appName: appName ?? this.appName,
  );

  factory AppInfoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppInfoModel();

    final data = json.at<AppInfoModel>();
    return AppInfoModel(
      flushipWorkspacePath: data.parse<String?>('fluship_workspace_path'),
      flutterProjectPath: data.parse<String?>('flutter_project_path'),
      buildNumber: data.parse<String?>('build_number'),
      projectName: data.parse<String?>('project_name'),
      appName: data.parse<String?>('app_name'),
      enabled: data.parse<bool>('enabled', defaultValue: true),
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
