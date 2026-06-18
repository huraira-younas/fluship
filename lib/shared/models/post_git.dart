import 'package:fluship/core/json_parser/exports.dart';
import 'base_config.dart';

final class PostGitModel extends GitBaseConfig {
  const PostGitModel({
    this.postCommit = false,
    this.postPush = false,
    super.enabled = true,
    super.commitMessage,
    super.targetBranch,
  });

  final bool postCommit;
  final bool postPush;

  @override
  PostGitModel copyWith({
    String? commitMessage,
    String? targetBranch,
    bool? postCommit,
    bool? postPush,
    bool? enabled,
  }) => PostGitModel(
    commitMessage: commitMessage ?? super.commitMessage,
    targetBranch: targetBranch ?? super.targetBranch,
    postCommit: postCommit ?? this.postCommit,
    postPush: postPush ?? this.postPush,
    enabled: enabled ?? this.enabled,
  );

  factory PostGitModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PostGitModel();

    final data = json.at<PostGitModel>();
    return PostGitModel(
      postCommit: data.parse<bool>('post_commit', defaultValue: false),
      postPush: data.parse<bool>('post_push', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      commitMessage: data.parse<String?>('commit_message'),
      targetBranch: data.parse<String?>('target_branch'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'commit_message': commitMessage,
    'target_branch': targetBranch,
    'post_commit': postCommit,
    'post_push': postPush,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [
    commitMessage,
    targetBranch,
    postCommit,
    postPush,
    enabled,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;

  @override
  List<CommandStep> get steps => enabled
      ? [
          if (postCommit)
            CommandStep(
              name: 'Post-Commit',
              command:
                  'git add . && git commit -m "${commitMessage ?? '{version} release'}"',
            ),
          if (postPush)
            CommandStep(
              command: 'git push origin ${targetBranch ?? 'master'}',
              name: 'Post-Push',
            ),
        ]
      : [];
}
