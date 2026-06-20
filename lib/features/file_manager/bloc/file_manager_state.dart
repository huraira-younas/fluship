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
    required this.currentPath,
    required this.segments,
    required this.entries,
    super.loading = false,
    super.error,
  });

  final List<FileManagerSegment> segments;
  final List<FileEntry> entries;
  final String currentPath;

  factory FileManagerState.empty() => const FileManagerState(
    currentPath: '',
    segments: [],
    entries: [],
  );

  @override
  List<Object?> get props => [currentPath, segments, entries, loading, error];

  @override
  FileManagerState copyWith({
    List<FileManagerSegment>? segments,
    List<FileEntry>? entries,
    String? currentPath,
    CustomState? error,
    bool? loading,
  }) {
    return FileManagerState(
      currentPath: currentPath ?? this.currentPath,
      segments: segments ?? this.segments,
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
