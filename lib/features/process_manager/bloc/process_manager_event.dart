part of 'process_manager_bloc.dart';

sealed class ProcessManagerEvent extends BaseBlocEvent {
  const ProcessManagerEvent({
    required super.name,
    super.onSuccess,
    super.onError,
  });
}

class ProcessManagerInitialized extends ProcessManagerEvent {
  const ProcessManagerInitialized({
    required this.projectRoot,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Process_Manager_Initialized');

  final String projectRoot;

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class ProcessManagerRefreshed extends ProcessManagerEvent {
  const ProcessManagerRefreshed({
    this.projectRoot,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Process_Manager_Refreshed');

  final String? projectRoot;

  @override
  Map<String, dynamic> toJson() => {'project_root': projectRoot};
}

class ProcessManagerVisibilityChanged extends ProcessManagerEvent {
  const ProcessManagerVisibilityChanged({
    required this.isVisible,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Process_Manager_Visibility_Changed');

  final bool isVisible;

  @override
  Map<String, dynamic> toJson() => {'is_visible': isVisible};
}

class ProcessManagerShowAllChildrenToggled extends ProcessManagerEvent {
  const ProcessManagerShowAllChildrenToggled({
    required this.value,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Process_Manager_Show_All_Children_Toggled');

  final bool value;

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

class ProcessManagerKillProcess extends ProcessManagerEvent {
  const ProcessManagerKillProcess({
    required this.pid,
    super.onSuccess,
    super.onError,
  }) : super(name: 'Process_Manager_Kill_Process');

  final int pid;

  @override
  Map<String, dynamic> toJson() => {'pid': pid};
}

class ProcessManagerKillAllOrphans extends ProcessManagerEvent {
  const ProcessManagerKillAllOrphans({super.onError, super.onSuccess})
    : super(name: 'Process_Manager_Kill_All_Orphans');

  @override
  Map<String, dynamic> toJson() => const {};
}
