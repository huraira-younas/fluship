import 'package:fluship/core/json_parser/exports.dart';
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

  factory PostGitModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PostGitModel();

    final data = json.at<PostGitModel>();
    return PostGitModel(
      postCommit: data.parse<bool>('post_commit', defaultValue: false),
      postPush: data.parse<bool>('post_push', defaultValue: false),
      enabled: data.parse<bool>('enabled', defaultValue: true),
      commitMessage: data.parse<String?>('commit_message'),
    );
  }

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
