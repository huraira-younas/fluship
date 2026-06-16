import 'base_config.dart';

final class PostGitModel extends BaseConfig {
  const PostGitModel({
    this.postCommit = false,
    this.postPush = false,
    super.enabled = true,
    this.commitMessage,
  });

  final String? commitMessage;
  final bool postCommit;
  final bool postPush;

  @override
  PostGitModel copyWith({
    String? commitMessage,
    bool? postCommit,
    bool? postPush,
    bool? enabled,
  }) => PostGitModel(
    commitMessage: commitMessage ?? this.commitMessage,
    postCommit: postCommit ?? this.postCommit,
    postPush: postPush ?? this.postPush,
    enabled: enabled ?? this.enabled,
  );

  factory PostGitModel.fromJson(Map<String, dynamic>? json) => PostGitModel(
    postCommit: json?['post_commit'] as bool? ?? false,
    commitMessage: json?['commit_message'] as String?,
    postPush: json?['post_push'] as bool? ?? false,
    enabled: json?['enabled'] as bool? ?? true,
  );

  @override
  Map<String, dynamic> toJson() => {
    'commit_message': commitMessage,
    'post_commit': postCommit,
    'post_push': postPush,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [commitMessage, postCommit, postPush, enabled];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
