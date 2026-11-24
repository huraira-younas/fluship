part of 'process_manager_bloc.dart';

sealed class const ProcessManagerEvent({
  required super.name,
  super.onSuccess,
  super.onError,
}) extends BaseBlocEvent;

class const ProcessManagerInitialized({
  required final String projectRoot,
  super.onSuccess,
  super.onError,
}) extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Initialized');

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class const ProcessManagerRefreshed({
  final String? projectRoot,
  super.onSuccess,
  super.onError,
}) extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Refreshed');

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class const ProcessManagerVisibilityChanged({
  required final bool isVisible,
  super.onSuccess,
  super.onError,
}) extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Visibility_Changed');

  @override
  Map<String, dynamic> toJson() => {'is_visible': isVisible};
}

class const ProcessManagerShowAllChildrenToggled({
  required final bool value,
  super.onSuccess,
  super.onError,
}) extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Show_All_Children_Toggled');

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

class const ProcessManagerKillProcess({
  required final int pid,
  super.onSuccess,
  super.onError,
}) extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Kill_Process');

  @override
  Map<String, dynamic> toJson() => {'pid': pid};
}

class const ProcessManagerKillAllOrphans({super.onError, super.onSuccess})
    extends ProcessManagerEvent {
  this : super(name: 'Process_Manager_Kill_All_Orphans');

  @override
  Map<String, dynamic> toJson() => const {};
}
