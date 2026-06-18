import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/pipeline/bloc/pipeline_bloc.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_config_source.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_executor.dart';
import 'package:fluship/services/console/models/shell_run_result.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/pipeline/command_step.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePipelineConfigSource implements PipelineConfigSource {
  FakePipelineConfigSource(this._state);

  ConfigState _state;
  var persistCalls = 0;

  @override
  ConfigState get state => _state;

  set state(ConfigState value) => _state = value;

  @override
  Future<void> persistCurrentConfig() async {
    persistCalls++;
  }
}

class FakePipelineConsolePort implements PipelineConsolePort {
  FakePipelineConsolePort({
    this.exitCode = 0,
    this.failCommand,
    this.delayStep = false,
  });

  final int exitCode;
  final String? failCommand;
  final bool delayStep;

  final commands = <String>[];
  final logLines = <String>[];
  var cancelCalls = 0;
  var disposeCalls = 0;
  var createCalls = 0;
  var _cancelNextRun = false;
  var _sessionCounter = 0;
  String? activeSessionId;

  @override
  Future<String> createSession({required String projectRoot}) async {
    createCalls++;
    activeSessionId = 'fake_pipeline_${++_sessionCounter}';
    return activeSessionId!;
  }

  @override
  Future<ShellRunResult> runCommand({
    required String sessionId,
    required String command,
  }) async {
    commands.add(command);

    if (delayStep) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (_cancelNextRun) {
      _cancelNextRun = false;
      return const ShellRunResult(exitCode: 1, wasCancelled: true);
    }

    if (failCommand != null && command == failCommand) {
      return ShellRunResult(exitCode: exitCode);
    }

    return ShellRunResult(exitCode: exitCode);
  }

  @override
  Future<void> logLine({
    required String sessionId,
    required ConsoleStream stream,
    required String text,
  }) async {
    logLines.add(text);
  }

  @override
  Future<void> cancelCommand(String sessionId) async {
    cancelCalls++;
    _cancelNextRun = true;
  }

  @override
  Future<void> disposeSession(String sessionId) async {
    disposeCalls++;
    if (activeSessionId == sessionId) {
      activeSessionId = null;
    }
  }
}

ConfigState _configWithSteps() {
  return ConfigState.empty().copyWith(
    appInfo: const AppInfoModel(flutterProjectPath: '/project'),
    commonCmd: const CommonCmdModel(enabled: true, clean: true),
    android: const AndroidConfigModel(enabled: true, buildAab: true),
  );
}

Future<void> _pumpBloc(PipelineBloc bloc) async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('PipelineBloc', () {
    test('persists config and runs shell steps in order', () async {
      final config = FakePipelineConfigSource(_configWithSteps());
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(config.persistCalls, 1);
      expect(console.createCalls, 1);
      expect(console.disposeCalls, 0);
      expect(console.commands, [
        'flutter clean',
        'flutter build aab --release',
      ]);
      expect(bloc.state.runStatus, PipelineRunStatus.completed);
      expect(
        bloc.state.steps.map((step) => step.status),
        everyElement(PipelineStepStatus.completed),
      );

      await bloc.close();
    });

    test('fails when no project path is set', () async {
      final config = FakePipelineConfigSource(ConfigState.empty());
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      expect(bloc.state.runStatus, PipelineRunStatus.failed);
      expect(console.commands, isEmpty);
      expect(console.createCalls, 0);

      await bloc.close();
    });

    test('fails when pipeline has no steps', () async {
      final config = FakePipelineConfigSource(
        ConfigState.empty().copyWith(
          appInfo: const AppInfoModel(flutterProjectPath: '/project'),
        ),
      );
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      expect(bloc.state.runStatus, PipelineRunStatus.failed);
      expect(bloc.state.summaryMessage, contains('No pipeline steps'));
      expect(console.createCalls, 0);

      await bloc.close();
    });

    test('stops pipeline and skips remaining steps on failure', () async {
      final config = FakePipelineConfigSource(_configWithSteps());
      final console = FakePipelineConsolePort(
        exitCode: 1,
        failCommand: 'flutter clean',
      );
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(bloc.state.runStatus, PipelineRunStatus.failed);
      expect(bloc.state.steps.first.status, PipelineStepStatus.failed);
      expect(
        bloc.state.steps.skip(1).map((step) => step.status),
        everyElement(PipelineStepStatus.skipped),
      );
      expect(console.commands, ['flutter clean']);
      expect(console.disposeCalls, 0);

      await bloc.close();
      expect(console.disposeCalls, 1);
    });

    test('cancel marks pipeline as cancelled', () async {
      final config = FakePipelineConfigSource(_configWithSteps());
      final console = FakePipelineConsolePort(delayStep: true);
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const CancelPipeline());

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(bloc.state.runStatus, PipelineRunStatus.cancelled);
      expect(console.cancelCalls, greaterThan(0));
      expect(console.disposeCalls, 0);

      await bloc.close();
      expect(console.disposeCalls, 1);
    });

    test('dismiss resets panel to idle', () async {
      final config = FakePipelineConfigSource(
        ConfigState.empty().copyWith(
          appInfo: const AppInfoModel(flutterProjectPath: '/project'),
        ),
      );
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(configSource: config, consolePort: console);

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      expect(bloc.state.isPanelVisible, isTrue);

      bloc.add(const DismissPipelinePanel());
      await _pumpBloc(bloc);

      expect(bloc.state.runStatus, PipelineRunStatus.idle);
      expect(bloc.state.isPanelVisible, isFalse);

      await bloc.close();
    });

    test('logs internal steps to console without shell commands', () async {
      final config = FakePipelineConfigSource(
        ConfigState.empty().copyWith(
          appInfo: const AppInfoModel(
            flutterProjectPath: '/project',
            buildNumber: '2',
            version: '1.1.0',
          ),
        ),
      );
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(
        configSource: config,
        consolePort: console,
        executor: _StubPipelineExecutor(),
      );

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(console.createCalls, 1);
      expect(console.commands, isEmpty);
      expect(
        console.logLines.any((line) => line.contains('Bump Version')),
        isTrue,
      );
      expect(bloc.state.runStatus, PipelineRunStatus.completed);
      expect(bloc.state.steps.single.name, 'Bump Version');

      await bloc.close();
    });
  });
}

class _StubPipelineExecutor extends PipelineExecutor {
  const _StubPipelineExecutor();

  @override
  Future<PipelineStepResult> executeInternal(CommandStep step) async {
    return const PipelineStepResult(success: true);
  }
}
