part of 'console_bloc.dart';

sealed class ConsoleEvent extends BaseBlocEvent {
  const ConsoleEvent({required super.name, super.onError, super.onSuccess});
}

class SyncProjectRoot extends ConsoleEvent {
  const SyncProjectRoot({required this.path, super.onError, super.onSuccess})
    : super(name: 'Sync_Project_Root');

  final String? path;

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class CreateSession extends ConsoleEvent {
  const CreateSession({super.onError, super.onSuccess})
    : super(name: 'Create_Session');

  @override
  Map<String, dynamic> toJson() => {};
}

class CloseSession extends ConsoleEvent {
  const CloseSession({required this.sessionId, super.onError, super.onSuccess})
    : super(name: 'Close_Session');

  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class SelectSession extends ConsoleEvent {
  const SelectSession({required this.sessionId, super.onError, super.onSuccess})
    : super(name: 'Select_Session');

  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
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

class DisposeAllSessions extends ConsoleEvent {
  const DisposeAllSessions({super.onError, super.onSuccess})
    : super(name: 'Dispose_All_Sessions');

  @override
  Map<String, dynamic> toJson() => {};
}

class CreatePipelineSession extends ConsoleEvent {
  const CreatePipelineSession({
    required this.projectRoot,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Create_Pipeline_Session');

  final String projectRoot;

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class RunPipelineCommand extends ConsoleEvent {
  const RunPipelineCommand({
    required this.sessionId,
    required this.command,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Run_Pipeline_Command');

  final String sessionId;
  final String command;

  @override
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'command': command,
  };
}

class CancelPipelineCommand extends ConsoleEvent {
  const CancelPipelineCommand({
    required this.sessionId,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Cancel_Pipeline_Command');

  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class ClosePipelineSession extends ConsoleEvent {
  const ClosePipelineSession({
    required this.sessionId,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Close_Pipeline_Session');

  final String sessionId;

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class LogPipelineLine extends ConsoleEvent {
  const LogPipelineLine({
    required this.sessionId,
    required this.stream,
    required this.text,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Log_Pipeline_Line');

  final ConsoleStream stream;
  final String sessionId;
  final String text;

  @override
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'stream': stream.name,
    'text': text,
  };
}
