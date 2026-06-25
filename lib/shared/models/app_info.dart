import 'package:fluship/core/json_parser/exports.dart';
import 'base_config.dart';

final class AppInfoModel extends BaseConfig {
  const AppInfoModel({
    this.flushipWorkspacePath,
    this.flutterProjectPath,
    super.enabled = true,
    this.buildNumber,
    this.version,
    this.appName,
  });

  final String? flushipWorkspacePath;
  final String? flutterProjectPath;
  final String? buildNumber;
  final String? version;
  final String? appName;

  @override
  AppInfoModel copyWith({
    String? flushipWorkspacePath,
    String? flutterProjectPath,
    String? buildNumber,
    String? version,
    String? appName,
    bool? enabled,
  }) => AppInfoModel(
    flushipWorkspacePath: flushipWorkspacePath ?? this.flushipWorkspacePath,
    flutterProjectPath: flutterProjectPath ?? this.flutterProjectPath,
    buildNumber: buildNumber ?? this.buildNumber,
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
      enabled: data.parse<bool>('enabled', defaultValue: true),
      buildNumber: data.parse<String?>('build_number'),
      appName: data.parse<String?>('app_name'),
      version: data.parse<String?>('version'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'fluship_workspace_path': flushipWorkspacePath,
    'flutter_project_path': flutterProjectPath,
    'build_number': buildNumber,
    'app_name': appName,
    'enabled': enabled,
    'version': version,
  };

  @override
  List<Object?> get props => [
    flushipWorkspacePath,
    flutterProjectPath,
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
