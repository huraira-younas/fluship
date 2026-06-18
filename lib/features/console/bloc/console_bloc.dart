import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:fluship/services/console_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'console_event.dart';
part 'console_state.dart';

class ConsoleBloc extends BaseBloc<ConsoleEvent, ConsoleState> {
  ConsoleBloc() : super(ConsoleState.empty()) {
    on<SyncProjectPath>(handler(_onSyncProjectPath));
    on<ClearConsole>(handler(_onClearConsole));
    on<SubmitCommand>(_onSubmitCommand);
    on<CancelCommand>(_onCancelCommand);
  }

  final _consoleService = ConsoleService();

  @override
  Future<void> close() {
    _consoleService.cancel();
    return super.close();
  }

  Future<void> _onSubmitCommand(
    SubmitCommand event,
    Emitter<ConsoleState> emit,
  ) async {
    final command = event.command.trim();
    if (command.isEmpty) return;

    if (state.isRunning) {
      emit(
        state.copyWith(lines: _appendSystem('A command is already running.')),
      );
      return;
    }

    final projectPath = state.projectPath;
    if (projectPath == null || projectPath.isEmpty) {
      emit(
        state.copyWith(
          lines: _appendSystem('Set Flutter project path in Settings first.'),
        ),
      );
      return;
    }

    final history = [...state.commandHistory, command];
    if (history.length > 50) history.removeAt(0);

    emit(
      state.copyWith(
        lines: _appendLine(.input, '> $command'),
        commandHistory: history,
        isRunning: true,
      ),
    );

    try {
      final exitCode = await _consoleService.run(
        onStdout: (chunk) => _appendChunk(emit, .stdout, chunk),
        onStderr: (chunk) => _appendChunk(emit, .stderr, chunk),
        workingDirectory: projectPath,
        command: command,
      );

      if (_consoleService.wasCancelled) {
        emit(
          state.copyWith(lines: _appendSystem('[cancelled]'), isRunning: false),
        );
        return;
      }

      emit(
        state.copyWith(
          lines: _appendSystem('[exit $exitCode]'),
          isRunning: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(lines: _appendSystem(e.toString()), isRunning: false),
      );
    }
  }

  Future<void> _onCancelCommand(
    CancelCommand event,
    Emitter<ConsoleState> emit,
  ) async {
    if (!state.isRunning) return;
    await _consoleService.cancel();
    emit(state.copyWith(isRunning: false));
  }

  Future<void> _onClearConsole(
    Emitter<ConsoleState> emit,
    ClearConsole event,
  ) async {
    emit(state.copyWith(lines: const []));
  }

  Future<void> _onSyncProjectPath(
    Emitter<ConsoleState> emit,
    SyncProjectPath event,
  ) async {
    emit(state.copyWith(projectPath: event.path));
  }

  void _appendChunk(
    Emitter<ConsoleState> emit,
    ConsoleStream stream,
    String chunk,
  ) {
    if (chunk.isEmpty) return;

    final lines = List<ConsoleLine>.from(state.lines);
    if (lines.isNotEmpty && lines.last.stream == stream) {
      lines[lines.length - 1] = lines.last.copyWith(
        text: lines.last.text + chunk,
      );
    } else {
      lines.add(ConsoleLine(stream: stream, text: chunk));
    }

    emit(state.copyWith(lines: lines));
  }

  List<ConsoleLine> _appendLine(ConsoleStream stream, String text) {
    return [...state.lines, ConsoleLine(stream: stream, text: text)];
  }

  List<ConsoleLine> _appendSystem(String text) {
    return _appendLine(.system, text);
  }
}
