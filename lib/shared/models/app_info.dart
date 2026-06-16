
import 'package:equatable/equatable.dart';

final class AppInfoModel implements Equatable {
  const AppInfoModel({
    this.flutterProjectPath,
    this.buildNumber,
    this.gitBranch,
    this.version,
  });

  final String? flutterProjectPath;
  final String? buildNumber;
  final String? gitBranch;
  final String? version;

  AppInfoModel copyWith({
    String? flutterProjectPath,
    String? buildNumber,
    String? gitBranch,
    String? version,
  }) => AppInfoModel(
    flutterProjectPath: flutterProjectPath ?? this.flutterProjectPath,
    buildNumber: buildNumber ?? this.buildNumber,
    gitBranch: gitBranch ?? this.gitBranch,
    version: version ?? this.version,
  );

  factory AppInfoModel.fromJson(Map<String, dynamic> json) => AppInfoModel(
    flutterProjectPath: json['flutter_project_path'] as String?,
    buildNumber: json['build_number'] as String?,
    gitBranch: json['git_branch'] as String?,
    version: json['version'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'flutter_project_path': flutterProjectPath,
    'build_number': buildNumber,
    'git_branch': gitBranch,
    'version': version,
  };

  @override
  List<Object?> get props => [
    flutterProjectPath,
    buildNumber,
    gitBranch,
    version,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
