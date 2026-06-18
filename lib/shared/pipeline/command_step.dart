import 'package:equatable/equatable.dart';

final class CommandStep extends Equatable {
  const CommandStep({
    required this.command,
    required this.name,
    this.onExecute,
  });

  final Future<void> Function()? onExecute;
  final String command;
  final String name;

  bool get isInternal => onExecute != null;

  @override
  List<Object?> get props => [name, command];
}
