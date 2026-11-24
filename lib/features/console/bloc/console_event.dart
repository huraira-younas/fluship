part of 'console_bloc.dart';

sealed class const ConsoleEvent({
  required super.name,
  super.onError,
  super.onSuccess,
}) extends BaseBlocEvent;

class const SyncProjectRoot({
  required final String? path,
  super.onError,
  super.onSuccess,
}) extends ConsoleEvent {
  this : super(name: 'Sync_Project_Root');

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class const CreateSession({super.onError, super.onSuccess})
    extends ConsoleEvent {
  this : super(name: 'Create_Session');

  @override
  Map<String, dynamic> toJson() => {};
}

class const CloseSession({
  required final String sessionId,
  super.onError,
  super.onSuccess,
}) extends ConsoleEvent {
  this : super(name: 'Close_Session');

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class const SelectSession({
  required final String sessionId,
  super.onError,
  super.onSuccess,
}) extends ConsoleEvent {
  this : super(name: 'Select_Session');

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class const SubmitCommand({
  required final String command,
  super.onError,
  super.onSuccess,
}) extends ConsoleEvent {
  this : super(name: 'Submit_Command');

  @override
  Map<String, dynamic> toJson() => {'command': command};
}

class const CancelCommand({super.onError, super.onSuccess})
    extends ConsoleEvent {
  this : super(name: 'Cancel_Command');

  @override
  Map<String, dynamic> toJson() => {};
}

class const ClearConsole({super.onError, super.onSuccess})
    extends ConsoleEvent {
  this : super(name: 'Clear_Console');

  @override
  Map<String, dynamic> toJson() => {};
}

class const DisposeAllSessions({super.onError, super.onSuccess})
    extends ConsoleEvent {
  this : super(name: 'Dispose_All_Sessions');

  @override
  Map<String, dynamic> toJson() => {};
}

class const CreatePipelineSession({
  required final String projectRoot,
  super.onSuccess,
  super.onError,
}) extends ConsoleEvent {
  this : super(name: 'Create_Pipeline_Session');

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class const RunPipelineCommand({
  required final String sessionId,
  required final String command,
  super.onSuccess,
  super.onError,
}) extends ConsoleEvent {
  this : super(name: 'Run_Pipeline_Command');

  @override
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'command': command,
  };
}

class const CancelPipelineCommand({
  required final String sessionId,
  super.onSuccess,
  super.onError,
}) extends ConsoleEvent {
  this : super(name: 'Cancel_Pipeline_Command');

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class const ClosePipelineSession({
  required final String sessionId,
  super.onSuccess,
  super.onError,
}) extends ConsoleEvent {
  this : super(name: 'Close_Pipeline_Session');

  @override
  Map<String, dynamic> toJson() => {'session_id': sessionId};
}

class const LogPipelineLine({
  required final String sessionId,
  required final ConsoleStream stream,
  required final String text,
  super.onSuccess,
  super.onError,
  final ConsoleLineKind? kind,
}) extends ConsoleEvent {
  this : super(name: 'Log_Pipeline_Line');

  @override
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'stream': stream.name,
    'kind': kind?.name,
    'text': text,
  };
}
