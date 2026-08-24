import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert' show jsonDecode;
import 'dart:io' show Directory, File;

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

class FakeDriveUploader implements DriveUploader {
  FakeDriveUploader({
    this.outcome = const DriveUploadOutcome(
      fileNames: ['Demo-v1.0.0+42.apk'],
      link: 'https://drive.google.com/drive/folders/abc',
      label: 'Demo',
    ),
  });

  final DriveUploadOutcome outcome;
  List<String>? lastFiles;
  Object? throwError;
  var uploadCalls = 0;

  @override
  Future<DriveUploadOutcome> upload({
    Future<void> Function(String fileName)? onFileUploaded,
    UploadByteProgress? onProgress,
    required GoogleDriveConfig driveConfig,
    required List<String> files,
    required String buildNumber,
    required String appName,
    required String version,
  }) async {
    uploadCalls++;
    lastFiles = files;
    if (throwError != null) throw throwError!;
    await onFileUploaded?.call('Demo.apk');
    return outcome;
  }
}

PipelineRunSnapshot _snapshot({
  required String artifactsDir,
  List<String> collected = const [],
}) {
  return PipelineRunSnapshot(
    collectedArtifacts: collected,
    steps: const [],
    runStatus: PipelineRunStatus.completed,
    totalElapsed: Duration.zero,
    finishedAt: DateTime(2026, 6, 21, 14, 30),
    startedAt: DateTime(2026, 6, 21, 14, 29),
    logFilePath: '',
    artifactsDir: artifactsDir,
    buildNumber: '42',
    platforms: 'Android',
    appName: 'Demo App',
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
          driveConfig: GoogleDriveConfig(
            enabled: true,
            oauthJson: '/secrets/oauth.json',
          ),
          reportRecipient: ReportRecipientConfig(
            gmailAddress: 'sender@gmail.com',
            appPassword: 'secret',
            emails: [
              DistributionEmail(email: 'tester@example.com', name: 'Tester'),
            ],
          ),
        ),
    logger: FakeDistributionLogger(),
  );
}

void main() {
  late FakeEmailClient emailClient;
  late FakeDriveUploader driveUploader;
  late GoogleDriveHandler handler;
  late Directory artifactsDir;
  late String apkPath;

  PipelineRunSnapshot withArtifacts() =>
      _snapshot(artifactsDir: artifactsDir.path, collected: [apkPath]);

  setUp(() async {
    emailClient = FakeEmailClient();
    driveUploader = FakeDriveUploader();
    handler = GoogleDriveHandler(
      htmlBuilder: const ReportHtmlBuilder(),
      emailClient: emailClient,
      uploader: driveUploader,
    );
    artifactsDir = await Directory.systemTemp.createTemp(
      'fluship_gdrive_test_',
    );
    apkPath = '${artifactsDir.path}/Demo.apk';
    await File(apkPath).writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    if (await artifactsDir.exists()) {
      await artifactsDir.delete(recursive: true);
    }
  });

  test('skips when drive is disabled', () async {
    final result = await handler.run(
      _context(
        snapshot: withArtifacts(),
        config: const DistributionConfigModel(
          enabled: true,
          driveConfig: GoogleDriveConfig(enabled: false),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(driveUploader.uploadCalls, 0);
    expect(emailClient.sendCalls, 0);
  });

  test('skips artifacts left in the folder by an earlier run', () async {
    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('No APK'));
    expect(driveUploader.uploadCalls, 0);
    expect(emailClient.sendCalls, 0);
  });

  test('skips when the run collected an app bundle but no apk', () async {
    final aabPath = '${artifactsDir.path}/Demo.aab';
    await File(aabPath).writeAsBytes([1, 2, 3]);

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('No APK'));
    expect(driveUploader.uploadCalls, 0);
    expect(emailClient.sendCalls, 0);
  });

  test('uploads only the apks out of everything collected', () async {
    final aabPath = '${artifactsDir.path}/Demo.aab';
    final ipaPath = '${artifactsDir.path}/Demo.ipa';
    final splitApkPath = '${artifactsDir.path}/Demo-arm64-v8a.apk';
    for (final path in [aabPath, ipaPath, splitApkPath]) {
      await File(path).writeAsBytes([1, 2, 3]);
    }

    await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath, apkPath, ipaPath, splitApkPath],
        ),
      ),
    );

    expect(driveUploader.lastFiles, [splitApkPath, apkPath]);
  });

  test('returns failed when upload throws', () async {
    driveUploader.throwError = Exception('auth failed');

    final result = await handler.run(_context(snapshot: withArtifacts()));

    expect(result.isFailed, isTrue);
    expect(result.message, contains('auth failed'));
    expect(emailClient.sendCalls, 0);
  });

  test('uploads only when email is not configured', () async {
    final result = await handler.run(
      _context(
        snapshot: withArtifacts(),
        config: const DistributionConfigModel(
          enabled: true,
          driveConfig: GoogleDriveConfig(
            enabled: true,
            oauthJson: '/secrets/oauth.json',
          ),
        ),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(driveUploader.uploadCalls, 1);
    expect(emailClient.sendCalls, 0);
    expect(result.message, contains('Uploaded to Drive'));
  });

  test('uploads and emails when fully configured', () async {
    final context = _context(snapshot: withArtifacts());
    final logger = context.logger as FakeDistributionLogger;

    final result = await handler.run(context);

    expect(result.isSuccess, isTrue);
    expect(driveUploader.uploadCalls, 1);
    expect(emailClient.sendCalls, 1);
    expect(emailClient.lastMessage?.recipients, ['tester@example.com']);
    expect(emailClient.lastMessage?.subject, contains('Download Link'));
    expect(logger.lines, contains('[drive] uploading: Demo.apk\n'));
  });

  test('posts slack after upload when webhook is set', () async {
    Uri? url;
    String? body;
    handler = GoogleDriveHandler(
      htmlBuilder: const ReportHtmlBuilder(),
      emailClient: emailClient,
      uploader: driveUploader,
      slackNotifier: SlackNotifier(
        post: (posted, raw) async {
          url = posted;
          body = raw;
        },
      ),
    );

    await handler.run(
      _context(
        snapshot: withArtifacts(),
        config: const DistributionConfigModel(
          enabled: true,
          driveConfig: GoogleDriveConfig(
            enabled: true,
            oauthJson: '/secrets/oauth.json',
          ),
          slackConfig: SlackConfig(
            enabled: true,
            webhookUrl: 'https://hooks.slack.com/x',
          ),
        ),
      ),
    );

    expect(url.toString(), 'https://hooks.slack.com/x');
    expect(jsonDecode(body!), {
      'version': '1.0.0+42',
      'platform': 'Android',
      'artifacts': 'https://drive.google.com/drive/folders/abc',
      'app': 'Demo App',
      'status': 'Artifacts for QA',
    });
  });

  test('keeps drive success when slack post throws', () async {
    handler = GoogleDriveHandler(
      htmlBuilder: const ReportHtmlBuilder(),
      emailClient: emailClient,
      uploader: driveUploader,
      slackNotifier: SlackNotifier(
        post: (_, _) async {
          throw Exception('slack down');
        },
      ),
    );

    final result = await handler.run(
      _context(
        snapshot: withArtifacts(),
        config: const DistributionConfigModel(
          enabled: true,
          driveConfig: GoogleDriveConfig(
            enabled: true,
            oauthJson: '/secrets/oauth.json',
          ),
          slackConfig: SlackConfig(
            enabled: true,
            webhookUrl: 'https://hooks.slack.com/x',
          ),
        ),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(driveUploader.uploadCalls, 1);
  });

  test('returns failed when email client throws after upload', () async {
    emailClient.throwError = Exception('smtp down');

    final result = await handler.run(_context(snapshot: withArtifacts()));

    expect(result.isFailed, isTrue);
    expect(result.message, contains('smtp down'));
    expect(driveUploader.uploadCalls, 1);
  });
}
