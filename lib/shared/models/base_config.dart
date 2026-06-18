import 'package:equatable/equatable.dart';

abstract class BaseConfig extends Equatable {
  const BaseConfig({required this.enabled});

  final bool enabled;

  BaseConfig copyWith({bool? enabled});
  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [enabled];

  List<CommandStep> get steps;
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

class CommandStep extends Equatable {
  const CommandStep({required this.name, required this.command});

  final String command;
  final String name;

  @override
  List<Object?> get props => [name, command];
}
