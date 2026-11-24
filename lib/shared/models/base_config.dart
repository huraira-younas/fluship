import 'package:equatable/equatable.dart';

abstract class const BaseConfig({required final bool enabled})
    extends Equatable {
  BaseConfig copyWith({bool? enabled});
  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [enabled];
}

abstract class const GitBaseConfig({
  required super.enabled,
  final String? commitMessage,
  final String? targetBranch,
}) extends BaseConfig;
