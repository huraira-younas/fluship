import 'dart:io';

import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:flutter_test/flutter_test.dart';

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
    snapshot: snapshot,
    config:
        config ??
        DistributionConfigModel(
          enabled: true,
          reportRecipient: const ReportRecipientConfig(
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
  late BuildReportEmailHandler handler;

  setUp(() {
    emailClient = FakeEmailClient();
    handler = BuildReportEmailHandler(
      htmlBuilder: const BuildReportHtmlBuilder(),
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
