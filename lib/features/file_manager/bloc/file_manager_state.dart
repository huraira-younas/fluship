part of 'file_manager_bloc.dart';

class const FileManagerSegment({
  required final String name,
  required final String path,
}) extends Equatable {
  @override
  List<Object?> get props => [name, path];
}

class const FileManagerState({
  required final Set<String> selectedPaths,
  required final String outputsRoot,
  required final String currentPath,
  required final List<FileManagerSegment> segments,
  required final List<FileEntry> entries,
  super.loading = false,
  super.error,
}) extends BaseBlocState {
  bool get hasSelection => selectedPaths.isNotEmpty;

  factory empty() => const FileManagerState(
    selectedPaths: {},
    outputsRoot: '',
    currentPath: '',
    segments: [],
    entries: [],
  );

  @override
  List<Object?> get props => [
    selectedPaths,
    outputsRoot,
    currentPath,
    segments,
    entries,
    loading,
    error,
  ];

  @override
  FileManagerState copyWith({
    List<FileManagerSegment>? segments,
    bool clearSelection = false,
    Set<String>? selectedPaths,
    List<FileEntry>? entries,
    String? outputsRoot,
    String? currentPath,
    CustomState? error,
    bool? loading,
  }) {
    return FileManagerState(
      selectedPaths: clearSelection
          ? const {}
          : (selectedPaths ?? this.selectedPaths),
      outputsRoot: outputsRoot ?? this.outputsRoot,
      currentPath: currentPath ?? this.currentPath,
      segments: segments ?? this.segments,
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
