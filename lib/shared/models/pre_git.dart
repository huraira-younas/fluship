import 'base_config.dart';

final class PreGitModel extends BaseConfig {
  const PreGitModel({
    this.preCommit = false,
    this.prePull = false,
    super.enabled = true,
    this.commitMessage,
  });

  final String? commitMessage;
  final bool preCommit;
  final bool prePull;

  @override
  PreGitModel copyWith({
    String? commitMessage,
    bool? preCommit,
    bool? prePull,
    bool? enabled,
  }) => PreGitModel(
    commitMessage: commitMessage ?? this.commitMessage,
    preCommit: preCommit ?? this.preCommit,
    prePull: prePull ?? this.prePull,
    enabled: enabled ?? this.enabled,
  );

  factory PreGitModel.fromJson(Map<String, dynamic> json) => PreGitModel(
    commitMessage: json['commit_message'] as String?,
    preCommit: json['pre_commit'] as bool? ?? false,
    prePull: json['pre_pull'] as bool? ?? false,
    enabled: json['enabled'] as bool? ?? true,
  );

  @override
  Map<String, dynamic> toJson() => {
    'commit_message': commitMessage,
    'pre_commit': preCommit,
    'pre_pull': prePull,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [commitMessage, preCommit, prePull, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
