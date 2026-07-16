import 'package:fluship/services/pipeline/pipeline.dart';
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
import 'package:flutter_test/flutter_test.dart';

class FakePipelineConfigSource implements PipelineConfigSource {
  FakePipelineConfigSource(this._state);

  ConfigState _state;
  var persistCalls = 0;

  @override
  ConfigState get state => _state;

  set state(ConfigState value) => _state = value;

  @override
  Future<void> persistActiveProfile() async {
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
  final capturedLines = <ConsoleLine>[];
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
    capturedLines.add(
      ConsoleLine(stream: ConsoleStream.input, text: '> $command'),
    );

    if (delayStep) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (_cancelNextRun) {
      _cancelNextRun = false;
      return const ShellRunResult(exitCode: 1, wasCancelled: true);
    }

    if (failCommand != null && command == failCommand) {
      capturedLines.add(
        ConsoleLine(stream: ConsoleStream.system, text: '[exit $exitCode]'),
      );
      return ShellRunResult(exitCode: exitCode);
    }

    capturedLines.add(
      const ConsoleLine(stream: ConsoleStream.system, text: '[exit 0]'),
    );
    return ShellRunResult(exitCode: exitCode);
  }

  @override
  Future<void> logLine({
    required String sessionId,
    required ConsoleStream stream,
    required String text,
  }) async {
    logLines.add(text);
    capturedLines.add(ConsoleLine(stream: stream, text: text));
  }

  @override
  List<ConsoleLine> sessionLines(String sessionId) {
    return List<ConsoleLine>.from(capturedLines);
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

class FakePipelineLogWriter implements PipelineLogWriter {
  List<ConsoleLine>? lastLines;
  String? lastProjectName;
  String? lastVersion;
  String? lastBuildNumber;

  @override
  Future<String> save({
    required String projectName,
    required String buildNumber,
    required List<ConsoleLine> lines,
    required String version,
  }) async {
    lastProjectName = projectName;
    lastBuildNumber = buildNumber;
    lastLines = List<ConsoleLine>.from(lines);
    lastVersion = version;
    return 'outputs/reelstay/v1.5.4/5700/logs.txt';
  }
}

ConfigState _configWithSteps() {
  return ConfigState.empty().copyWith(
    appInfo: const AppInfoModel(
      flushipWorkspacePath: '/fluship',
      flutterProjectPath: '/project',
    ),
    commonCmd: const CommonCmdModel(enabled: true, clean: true),
    android: const AndroidConfigModel(enabled: true, buildAab: true),
  );
}

ConfigState _configWithStepsAndAppInfo() {
  return _configWithSteps().copyWith(
    appInfo: const AppInfoModel(
      flushipWorkspacePath: '/fluship',
      flutterProjectPath: '/project',
      appName: 'ReelStay',
      buildNumber: '5700',
      version: '1.5.4',
    ),
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
      final bloc = PipelineBloc(
        executor: const _StubPipelineExecutor(),
        configSource: config,
        consolePort: console,
      );

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
      expect(bloc.state.steps.every((step) => step.elapsed != null), isTrue);
      expect(
        console.logLines.any((line) => line.contains('completed in')),
        isTrue,
      );
      expect(
        console.logLines.any((line) => line.contains('[pipeline completed in')),
        isTrue,
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
          appInfo: const AppInfoModel(
            flushipWorkspacePath: '/fluship',
            flutterProjectPath: '/project',
          ),
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

    test('continues pipeline after a step failure', () async {
      final config = FakePipelineConfigSource(_configWithSteps());
      final console = FakePipelineConsolePort(
        exitCode: 1,
        failCommand: 'flutter clean',
      );
      final bloc = PipelineBloc(
        executor: const _StubPipelineExecutor(),
        configSource: config,
        consolePort: console,
      );

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(bloc.state.runStatus, PipelineRunStatus.failed);
      expect(bloc.state.steps.first.status, PipelineStepStatus.failed);
      expect(bloc.state.steps.first.name, 'Clean');
      expect(
        bloc.state.steps.skip(1).every((step) => step.status != .skipped),
        isTrue,
      );
      expect(console.commands, [
        'flutter clean',
        'flutter build aab --release',
      ]);
      expect(bloc.state.summaryMessage, contains('finished with failed steps'));
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
          appInfo: const AppInfoModel(
            flushipWorkspacePath: '/fluship',
            flutterProjectPath: '/project',
          ),
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
            flushipWorkspacePath: '/fluship',
            flutterProjectPath: '/project',
            buildNumber: '2',
            version: '1.1.0',
          ),
        ),
      );
      final console = FakePipelineConsolePort();
      final bloc = PipelineBloc(
        executor: const _StubPipelineExecutor(),
        configSource: config,
        consolePort: console,
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
      expect(
        console.logLines.any(
          (line) => line.contains('Bump Version completed in'),
        ),
        isTrue,
      );
      expect(bloc.state.runStatus, PipelineRunStatus.completed);
      expect(bloc.state.steps.single.name, 'Bump Version');

      await bloc.close();
    });

    test('saves full pipeline console output to logs file', () async {
      final config = FakePipelineConfigSource(_configWithStepsAndAppInfo());
      final console = FakePipelineConsolePort();
      final logWriter = FakePipelineLogWriter();
      final bloc = PipelineBloc(
        executor: const _StubPipelineExecutor(),
        configSource: config,
        consolePort: console,
        logWriter: logWriter,
      );

      bloc.add(const RunPipeline());
      await _pumpBloc(bloc);

      while (bloc.state.isRunning) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(logWriter.lastProjectName, 'ReelStay');
      expect(logWriter.lastLines, isNotNull);
      expect(logWriter.lastLines, isNotEmpty);
      expect(
        logWriter.lastLines!.any((line) => line.text.contains('flutter clean')),
        isTrue,
      );
      expect(
        console.logLines.any(
          (line) => line.contains('[pipeline log saved to outputs/reelstay/'),
        ),
        isTrue,
      );

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
