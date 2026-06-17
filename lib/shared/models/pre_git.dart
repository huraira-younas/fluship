import 'package:fluship/core/json_parser/exports.dart';
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

  factory PreGitModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PreGitModel();

    final data = json.at<PreGitModel>();
    return PreGitModel(
      preCommit: data.parse<bool>('pre_commit', defaultValue: false),
      prePull: data.parse<bool>('pre_pull', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      commitMessage: data.parse<String?>('commit_message'),
    );
  }

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
