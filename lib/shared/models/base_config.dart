import 'package:equatable/equatable.dart';

abstract class BaseConfig extends Equatable {
  const BaseConfig({required this.enabled});

  final bool enabled;

  BaseConfig copyWith({bool? enabled});
  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [enabled];
}

abstract class GitBaseConfig extends BaseConfig {
  const GitBaseConfig({
    required super.enabled,
    this.commitMessage,
    this.targetBranch,
  });

  final String? commitMessage;
  final String? targetBranch;
}
