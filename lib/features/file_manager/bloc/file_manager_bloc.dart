import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

import '../repository/file_manager_repository.dart';
import '../models/file_entry.dart';

part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends BaseBloc<FileManagerEvent, FileManagerState> {
  FileManagerBloc({required this._repository})
    : super(FileManagerState.empty()) {
    on<FileManagerNavigateToSegment>(handler(_onNavigateToSegment));
    on<FileManagerOpenDirectory>(handler(_onOpenDirectory));
    on<FileManagerInitialized>(handler(_onInitialized));
  }

  final FileManagerRepository _repository;

  Future<void> _onInitialized(
    Emitter<FileManagerState> emit,
    FileManagerInitialized event,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    final outputsRoot = await _repository.resolveOutputsRoot();
    await _loadDirectory(emit, outputsRoot);
  }

  Future<void> _onNavigateToSegment(
    Emitter<FileManagerState> emit,
    FileManagerNavigateToSegment event,
  ) async {
    if (event.index < 0 || event.index >= state.segments.length) return;

    final targetPath = state.segments[event.index].path;

    emit(state.copyWith(loading: true, error: null));
    await _loadDirectory(emit, targetPath);
  }

  Future<void> _onOpenDirectory(
    Emitter<FileManagerState> emit,
    FileManagerOpenDirectory event,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    await _loadDirectory(emit, event.path);
  }

  Future<void> _loadDirectory(
    Emitter<FileManagerState> emit,
    String path,
  ) async {
    final entries = await _repository.listDirectory(path);
    final segments = _buildSegments(path);

    emit(
      state.copyWith(
        segments: segments,
        currentPath: path,
        entries: entries,
        loading: false,
      ),
    );
  }

  List<FileManagerSegment> _buildSegments(String path) {
    final normalized = p.normalize(path);
    final outputsMarker = '${p.separator}outputs';
    final markerIndex = normalized.toLowerCase().indexOf(
      outputsMarker.toLowerCase(),
    );

    late final List<String> relativeParts;
    late final String basePath;

    if (markerIndex >= 0) {
      basePath = normalized.substring(0, markerIndex + outputsMarker.length);
      final remainder = normalized.substring(basePath.length);
      relativeParts = p
          .split(remainder)
          .where((part) => part.isNotEmpty)
          .toList();
    } else {
      basePath = normalized;
      relativeParts = const [];
    }

    final segments = <FileManagerSegment>[
      FileManagerSegment(name: 'outputs', path: basePath),
    ];

    var current = basePath;
    for (final part in relativeParts) {
      current = p.join(current, part);
      segments.add(FileManagerSegment(name: part, path: current));
    }

    return segments;
  }
}
