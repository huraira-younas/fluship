part of 'file_manager_bloc.dart';

class FileManagerSegment extends Equatable {
  const FileManagerSegment({required this.name, required this.path});

  final String name;
  final String path;

  @override
  List<Object?> get props => [name, path];
}

class FileManagerState extends BaseBlocState {
  const FileManagerState({
    required this.selectedPaths,
    required this.outputsRoot,
    required this.currentPath,
    required this.segments,
    required this.entries,
    super.loading = false,
    super.error,
  });

  final List<FileManagerSegment> segments;
  final Set<String> selectedPaths;
  final List<FileEntry> entries;
  final String outputsRoot;
  final String currentPath;

  bool get hasSelection => selectedPaths.isNotEmpty;

  factory FileManagerState.empty() => const FileManagerState(
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
