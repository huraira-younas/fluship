import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

const _testTheme = ReportHtmlTheme(
  borderLr: 'border-left:1px solid #1e293b;border-right:1px solid #1e293b;',
  bodyOpen: '<!DOCTYPE html><html><head></head><body><div>',
  cardBorder: '#1e293b',
  success: '#a3be8c',
  section: '#94a3b8',
  textDim: '#64748b',
  accent: '#81a1c1',
  cardBg: '#3b4252',
  error: '#bf616a',
  text: '#eceff4',
  bg: '#2e3440',
);

class FakeDistributionLogger implements DistributionLogger {
  final lines = <String>[];

  @override
  Future<void> logLine(DistributionResult result) async {
    lines.add(result.message);
  }
}

class RecordingHandler implements DistributionHandler {
  RecordingHandler(this.name, this.result);

  final DistributionResult result;

  @override
  final String name;

  var runCount = 0;

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    runCount++;
    return result;
  }
}

PipelineRunSnapshot _snapshot() {
  return PipelineRunSnapshot(
    steps: const [],
    runStatus: PipelineRunStatus.completed,
    totalElapsed: Duration.zero,
    finishedAt: DateTime(2026, 6, 20),
    startedAt: DateTime(2026, 6, 20),
    logFilePath: '',
    buildNumber: '1',
    platforms: 'None',
    appName: 'Demo',
    version: '1.0.0',
  );
}

void main() {
  test('does nothing when distribution is disabled', () async {
    final first = RecordingHandler('First', DistributionResult.success());
    final second = RecordingHandler('Second', DistributionResult.success());
    final logger = FakeDistributionLogger();
    final service = DistributionService(handlers: [first, second]);

    await service.run(
      emailTheme: _testTheme,
      snapshot: _snapshot(),
      config: const DistributionConfigModel(enabled: false),
      logger: logger,
    );

    expect(first.runCount, 0);
    expect(second.runCount, 0);
    expect(logger.lines, isEmpty);
  });

  test('runs handlers in order and continues after failure', () async {
    final first = RecordingHandler('First', DistributionResult.failed('boom'));
    final second = RecordingHandler(
      'Second',
      DistributionResult.skipped('n/a'),
    );
    final third = RecordingHandler('Third', DistributionResult.success('ok'));
    final logger = FakeDistributionLogger();
    final service = DistributionService(handlers: [first, second, third]);

    await service.run(
      emailTheme: _testTheme,
      snapshot: _snapshot(),
      config: const DistributionConfigModel(enabled: true),
      logger: logger,
    );

    expect(first.runCount, 1);
    expect(second.runCount, 1);
    expect(third.runCount, 1);
    expect(logger.lines.first, '[distribution started]\n');
    expect(logger.lines.last, '[distribution finished]\n');
    expect(
      logger.lines.any((line) => line.contains('First failed: boom')),
      isTrue,
    );
  });
}
