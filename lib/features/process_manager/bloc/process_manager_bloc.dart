import 'dart:async' show Timer;
import 'dart:io' show pid;

import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/process/process.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'process_manager_event.dart';
part 'process_manager_state.dart';

class ProcessManagerBloc({
  ProcessClassifier? classifier,
  ProcessEnumerator? enumerator,
  required final IConsoleSessionPool _sessionPool,
  ProcessKiller? killer,
}) extends BaseBloc<ProcessManagerEvent, ProcessManagerState> {
  this : super(ProcessManagerState.initial()) {
    on<ProcessManagerShowAllChildrenToggled>(handler(_onShowAllToggled));
    on<ProcessManagerVisibilityChanged>(handler(_onVisibilityChanged));
    on<ProcessManagerKillAllOrphans>(handler(_onKillAllOrphans));
    on<ProcessManagerInitialized>(handler(_onInitialized));
    on<ProcessManagerKillProcess>(handler(_onKillProcess));
    on<ProcessManagerRefreshed>(handler(_onRefreshed));
  }

  final ProcessClassifier _classifier = classifier ?? const ProcessClassifier();
  final ProcessEnumerator _enumerator = enumerator ?? const ProcessEnumerator();
  final ProcessKiller _killer = killer ?? const ProcessKiller();

  Timer? _refreshTimer;
  String _projectRoot = '';

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitialized(
    Emitter<ProcessManagerState> emit,
    ProcessManagerInitialized event,
  ) async {
    _projectRoot = event.projectRoot;
    emit(state.copyWith(isSupported: _enumerator.isSupported, error: null));
    await _refresh(emit);
  }

  Future<void> _onRefreshed(
    Emitter<ProcessManagerState> emit,
    ProcessManagerRefreshed event,
  ) async {
    if (event.projectRoot != null) {
      _projectRoot = event.projectRoot!;
    }
    await _refresh(emit);
  }

  Future<void> _onVisibilityChanged(
    Emitter<ProcessManagerState> emit,
    ProcessManagerVisibilityChanged event,
  ) async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    if (event.isVisible) {
      await _refresh(emit);
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => add(const ProcessManagerRefreshed()),
      );
    }
  }

  Future<void> _onShowAllToggled(
    Emitter<ProcessManagerState> emit,
    ProcessManagerShowAllChildrenToggled event,
  ) async {
    emit(state.copyWith(showAllChildren: event.value));
    await _refresh(emit);
  }

  Future<void> _onKillProcess(
    Emitter<ProcessManagerState> emit,
    ProcessManagerKillProcess event,
  ) async {
    final result = await _killer.kill(event.pid);
    if (!result.success) {
      emit(
        state.copyWith(
          error: CustomState(
            message: result.message.isEmpty
                ? 'Failed to kill process ${event.pid}.'
                : result.message,
            title: 'Kill process',
          ),
        ),
      );
      return;
    }

    await _refresh(emit);
  }

  Future<void> _onKillAllOrphans(
    Emitter<ProcessManagerState> emit,
    ProcessManagerKillAllOrphans event,
  ) async {
    final orphanPids = state.orphans.map((row) => row.pid);
    if (orphanPids.isEmpty) return;

    final results = await _killer.killAll(orphanPids);
    final failed = results.where((result) => !result.success).toList();
    if (failed.isNotEmpty) {
      emit(
        state.copyWith(
          error: CustomState(
            message: failed.map((r) => r.message).join('\n'),
            title: 'Kill orphans',
          ),
        ),
      );
    }

    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<ProcessManagerState> emit) async {
    if (!_enumerator.isSupported) {
      emit(
        state.copyWith(loading: false, isSupported: false, processes: const []),
      );
      return;
    }

    emit(state.copyWith(loading: true, error: null));

    final raw = await _enumerator.listProcesses();
    final classified = _classifier.classify(
      trackedShellPids: _sessionPool.trackedShellPids,
      showAllChildren: state.showAllChildren,
      projectRoot: _projectRoot,
      rows: raw,
      selfPid: pid,
    );

    emit(
      state.copyWith(
        lastRefreshedAt: DateTime.now(),
        processes: classified,
        loading: false,
      ),
    );
  }
}
