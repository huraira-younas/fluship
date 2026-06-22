part of 'process_manager_bloc.dart';

class ProcessManagerState extends BaseBlocState {
  const ProcessManagerState({
    required this.showAllChildren,
    required this.isSupported,
    required this.processes,
    this.lastRefreshedAt,

    super.loading = false,
    super.error,
  });

  final List<ProcessRow> processes;
  final DateTime? lastRefreshedAt;
  final bool showAllChildren;
  final bool isSupported;

  factory ProcessManagerState.initial() => const ProcessManagerState(
    showAllChildren: false,
    isSupported: true,
    processes: [],
  );

  List<ProcessRow> get actives =>
      processes.where((row) => row.kind == .active).toList();

  List<ProcessRow> get orphans =>
      processes.where((row) => row.kind == .orphan).toList();

  @override
  List<Object?> get props => [
    showAllChildren,
    lastRefreshedAt,
    isSupported,
    processes,
    loading,
    error,
  ];

  @override
  ProcessManagerState copyWith({
    List<ProcessRow>? processes,
    DateTime? lastRefreshedAt,
    bool? showAllChildren,
    CustomState? error,
    bool? isSupported,
    bool? loading,
  }) {
    return ProcessManagerState(
      showAllChildren: showAllChildren ?? this.showAllChildren,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      isSupported: isSupported ?? this.isSupported,
      processes: processes ?? this.processes,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
