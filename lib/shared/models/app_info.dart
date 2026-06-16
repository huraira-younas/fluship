import 'base_config.dart';

final class AppInfoModel extends BaseConfig {
  const AppInfoModel({
    this.flutterProjectPath,
    super.enabled = true,
    this.buildNumber,
    this.gitBranch,
    this.version,
    this.appName,
  });

  final String? flutterProjectPath;
  final String? buildNumber;
  final String? gitBranch;
  final String? version;
  final String? appName;

  @override
  AppInfoModel copyWith({
    String? flutterProjectPath,
    String? buildNumber,
    String? gitBranch,
    String? version,
    String? appName,
    bool? enabled,
  }) => AppInfoModel(
    flutterProjectPath: flutterProjectPath ?? this.flutterProjectPath,
    buildNumber: buildNumber ?? this.buildNumber,
    gitBranch: gitBranch ?? this.gitBranch,
    enabled: enabled ?? this.enabled,
    version: version ?? this.version,
    appName: appName ?? this.appName,
  );

  factory AppInfoModel.fromJson(Map<String, dynamic> json) => AppInfoModel(
    flutterProjectPath: json['flutter_project_path'] as String?,
    buildNumber: json['build_number'] as String?,
    enabled: json['enabled'] as bool? ?? true,
    gitBranch: json['git_branch'] as String?,
    appName: json['app_name'] as String?,
    version: json['version'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'flutter_project_path': flutterProjectPath,
    'build_number': buildNumber,
    'git_branch': gitBranch,
    'app_name': appName,
    'enabled': enabled,
    'version': version,
  };

  @override
  List<Object?> get props => [
    flutterProjectPath,
    buildNumber,
    gitBranch,
    appName,
    enabled,
    version,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
