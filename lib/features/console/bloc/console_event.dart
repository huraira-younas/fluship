part of 'console_bloc.dart';

sealed class ConsoleEvent extends BaseBlocEvent {
  const ConsoleEvent({required super.name, super.onError, super.onSuccess});
}

class SubmitCommand extends ConsoleEvent {
  const SubmitCommand({required this.command, super.onError, super.onSuccess})
    : super(name: 'Submit_Command');

  final String command;

  @override
  Map<String, dynamic> toJson() => {'command': command};
}

class CancelCommand extends ConsoleEvent {
  const CancelCommand({super.onError, super.onSuccess})
    : super(name: 'Cancel_Command');

  @override
  Map<String, dynamic> toJson() => {};
}

class ClearConsole extends ConsoleEvent {
  const ClearConsole({super.onError, super.onSuccess})
    : super(name: 'Clear_Console');

  @override
  Map<String, dynamic> toJson() => {};
}

class SyncProjectPath extends ConsoleEvent {
  const SyncProjectPath({required this.path, super.onError, super.onSuccess})
    : super(name: 'Sync_Project_Path');

  final String? path;

  @override
  Map<String, dynamic> toJson() => {'path': path};
}
