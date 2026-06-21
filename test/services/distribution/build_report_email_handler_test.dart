import 'dart:io';

import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';
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
  Future<void> logLine(String text) async {
    lines.add(text);
  }
}

class FakeEmailClient implements EmailClient {
  EmailMessage? lastMessage;
  var sendCalls = 0;
  Object? throwError;

  @override
  Future<void> send(EmailMessage message) async {
    sendCalls++;
    if (throwError != null) throw throwError!;
    lastMessage = message;
  }
}

PipelineRunSnapshot _snapshot({String logFilePath = 'logs.txt'}) {
  return PipelineRunSnapshot(
    steps: const [
      PipelineStepView(
        command: 'flutter build apk',
        status: PipelineStepStatus.completed,
        name: 'Build APK',
        elapsed: Duration(seconds: 3),
      ),
    ],
    runStatus: PipelineRunStatus.completed,
    totalElapsed: const Duration(seconds: 3),
    finishedAt: DateTime(2026, 6, 20, 14, 30),
    startedAt: DateTime(2026, 6, 20, 14, 29, 57),
    logFilePath: logFilePath,
    buildNumber: '42',
    platforms: 'Android',
    appName: 'Demo',
    version: '1.0.0',
  );
}

DistributionContext _context({
  required PipelineRunSnapshot snapshot,
  DistributionConfigModel? config,
}) {
  return DistributionContext(
    emailTheme: _testTheme,
    snapshot: snapshot,
    config:
        config ??
        const DistributionConfigModel(
          enabled: true,
          reportRecipient: ReportRecipientConfig(
            reportRecipient: 'dev@example.com',
            gmailAddress: 'sender@gmail.com',
            appPassword: 'secret',
          ),
        ),
    logger: FakeDistributionLogger(),
  );
}

void main() {
  late FakeEmailClient emailClient;
  late ReportEmailHandler handler;

  setUp(() {
    emailClient = FakeEmailClient();
    handler = ReportEmailHandler(
      htmlBuilder: const ReportHtmlBuilder(),
      emailClient: emailClient,
    );
  });

  test('skips when report recipient is missing', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(),
        config: const DistributionConfigModel(
          enabled: true,
          reportRecipient: ReportRecipientConfig(),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(emailClient.sendCalls, 0);
  });

  test('skips when gmail credentials are missing', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(),
        config: const DistributionConfigModel(
          enabled: true,
          reportRecipient: ReportRecipientConfig(
            reportRecipient: 'dev@example.com',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(emailClient.sendCalls, 0);
  });

  test('sends email when configured and log file exists', () async {
    final logFile = File('build_report_handler_test_log.txt');
    await logFile.writeAsString('pipeline log');

    addTearDown(() async {
      if (await logFile.exists()) await logFile.delete();
    });

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logFile.path)),
    );

    expect(result.isSuccess, isTrue);
    expect(emailClient.sendCalls, 1);
    expect(emailClient.lastMessage?.recipients, ['dev@example.com']);
    expect(emailClient.lastMessage?.attachmentPath, logFile.path);
    expect(emailClient.lastMessage?.subject, contains('Build Report'));
  });

  test('returns failed when email client throws', () async {
    final logFile = File('build_report_handler_test_log_fail.txt');
    await logFile.writeAsString('pipeline log');
    emailClient.throwError = Exception('smtp down');

    addTearDown(() async {
      if (await logFile.exists()) await logFile.delete();
    });

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logFile.path)),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('smtp down'));
  });
}
