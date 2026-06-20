import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

import '../repository/file_manager_repository.dart';
import '../models/file_entry.dart';

part 'file_manager_event.dart';
part 'file_manager_state.dart';

class FileManagerBloc extends BaseBloc<FileManagerEvent, FileManagerState> {
  final FileManagerRepository _repository;

  FileManagerBloc({required this._repository})
    : super(FileManagerState.empty()) {
    on<FileManagerNavigateToSegment>(handler(_onNavigateToSegment));
    on<FileManagerToggleSelection>(handler(_onToggleSelection));
    on<FileManagerClearSelection>(handler(_onClearSelection));
    on<FileManagerDeleteSelected>(handler(_onDeleteSelected));
    on<FileManagerOpenDirectory>(handler(_onOpenDirectory));
    on<FileManagerInitialized>(handler(_onInitialized));
    on<FileManagerSelectAll>(handler(_onSelectAll));
  }

  Future<void> _onInitialized(
    Emitter<FileManagerState> emit,
    FileManagerInitialized event,
  ) async {
    emit(state.copyWith(clearSelection: true, loading: true, error: null));

    final outputsRoot = p.normalize(await _repository.resolveOutputsRoot());
    emit(state.copyWith(outputsRoot: outputsRoot));
    await _loadDirectory(emit, outputsRoot);
  }

  Future<void> _onNavigateToSegment(
    Emitter<FileManagerState> emit,
    FileManagerNavigateToSegment event,
  ) async {
    if (event.index < 0 || event.index >= state.segments.length) return;

    final targetPath = state.segments[event.index].path;

    emit(state.copyWith(clearSelection: true, loading: true, error: null));
    await _loadDirectory(emit, targetPath);
  }

  Future<void> _onOpenDirectory(
    Emitter<FileManagerState> emit,
    FileManagerOpenDirectory event,
  ) async {
    emit(state.copyWith(clearSelection: true, loading: true, error: null));
    await _loadDirectory(emit, p.normalize(event.path));
  }

  Future<void> _onToggleSelection(
    Emitter<FileManagerState> emit,
    FileManagerToggleSelection event,
  ) async {
    final normalizedPath = p.normalize(event.path);
    final selected = Set<String>.from(state.selectedPaths);

    if (selected.contains(normalizedPath)) {
      selected.remove(normalizedPath);
    } else {
      selected.add(normalizedPath);
    }

    emit(state.copyWith(selectedPaths: selected));
  }

  Future<void> _onSelectAll(
    Emitter<FileManagerState> emit,
    FileManagerSelectAll event,
  ) async {
    final selected = state.entries
        .map((entry) => p.normalize(entry.path))
        .toSet();
    emit(state.copyWith(selectedPaths: selected));
  }

  Future<void> _onClearSelection(
    Emitter<FileManagerState> emit,
    FileManagerClearSelection event,
  ) async {
    emit(state.copyWith(clearSelection: true));
  }

  Future<void> _onDeleteSelected(
    Emitter<FileManagerState> emit,
    FileManagerDeleteSelected event,
  ) async {
    if (state.selectedPaths.isEmpty) return;

    emit(state.copyWith(loading: true, error: null));

    await _repository.deletePaths(
      paths: state.selectedPaths.toList(),
      outputsRoot: state.outputsRoot,
    );

    final currentPath = state.currentPath;
    emit(state.copyWith(clearSelection: true));
    await _loadDirectory(emit, currentPath);
  }

  Future<void> _loadDirectory(
    Emitter<FileManagerState> emit,
    String path,
  ) async {
    final normalizedPath = p.normalize(path);
    final entries = await _repository.listDirectory(normalizedPath);
    final segments = _buildSegments(
      outputsRoot: state.outputsRoot,
      currentPath: normalizedPath,
    );

    emit(
      state.copyWith(
        currentPath: normalizedPath,
        segments: segments,
        entries: entries,
        loading: false,
      ),
    );
  }

  List<FileManagerSegment> _buildSegments({
    required String currentPath,
    required String outputsRoot,
  }) {
    final normalizedCurrent = p.normalize(currentPath);
    final normalizedRoot = p.normalize(outputsRoot);

    if (normalizedRoot.isEmpty) {
      return [
        FileManagerSegment(
          name: p.basename(normalizedCurrent),
          path: normalizedCurrent,
        ),
      ];
    }

    final segments = <FileManagerSegment>[
      FileManagerSegment(name: 'outputs', path: normalizedRoot),
    ];

    if (p.equals(normalizedCurrent, normalizedRoot)) {
      return segments;
    }

    final relative = p.relative(normalizedCurrent, from: normalizedRoot);
    if (relative == '.' || relative.isEmpty) {
      return segments;
    }

    var current = normalizedRoot;
    for (final part in p.split(relative).where((part) => part.isNotEmpty)) {
      current = p.normalize(p.join(current, part));
      segments.add(FileManagerSegment(name: part, path: current));
    }

    return segments;
  }
}
