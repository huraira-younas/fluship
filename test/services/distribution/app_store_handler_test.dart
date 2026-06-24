import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';
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

class FakeAppStoreUploader implements AppStoreUploader {
  FakeAppStoreUploader({this.ipaPath, this.uploadedName = 'Demo.ipa'});

  final String? ipaPath;
  final String uploadedName;
  Object? throwError;
  var uploadCalls = 0;
  String? lastIpaPath;

  @override
  Future<String?> findIpa(String artifactsDir) async => ipaPath;

  @override
  Future<String> upload({
    required IosConfig appstore,
    required String ipaPath,
    DistributionLogger? logger,
  }) async {
    uploadCalls++;
    lastIpaPath = ipaPath;
    if (throwError != null) throw throwError!;
    return uploadedName;
  }
}

PipelineRunSnapshot _snapshot({required String artifactsDir}) {
  return PipelineRunSnapshot(
    steps: const [],
    runStatus: PipelineRunStatus.completed,
    totalElapsed: Duration.zero,
    finishedAt: DateTime(2026, 6, 21, 14, 30),
    startedAt: DateTime(2026, 6, 21, 14, 29),
    logFilePath: '',
    artifactsDir: artifactsDir,
    buildNumber: '42',
    platforms: 'iOS',
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
          appstore: IosConfig(
            enabled: true,
            issuerId: 'issuer-123',
            apiKeyId: 'key-456',
            apiKeyPath: '/secrets/AuthKey.p8',
          ),
        ),
    logger: FakeDistributionLogger(),
  );
}

void main() {
  late FakeAppStoreUploader uploader;
  late AppStoreHandler handler;
  late Directory artifactsDir;

  setUp(() async {
    uploader = FakeAppStoreUploader();
    handler = AppStoreHandler(uploader: uploader);
    artifactsDir = await Directory.systemTemp.createTemp(
      'fluship_appstore_test_',
    );
  });

  tearDown(() async {
    if (await artifactsDir.exists()) {
      await artifactsDir.delete(recursive: true);
    }
  });

  test('skips when app store is disabled', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(artifactsDir: artifactsDir.path),
        config: const DistributionConfigModel(
          enabled: true,
          appstore: IosConfig(
            enabled: false,
            issuerId: 'issuer-123',
            apiKeyId: 'key-456',
            apiKeyPath: '/secrets/AuthKey.p8',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(uploader.uploadCalls, 0);
  });

  test('skips when issuer id is missing', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(artifactsDir: artifactsDir.path),
        config: const DistributionConfigModel(
          enabled: true,
          appstore: IosConfig(
            enabled: true,
            apiKeyId: 'key-456',
            apiKeyPath: '/secrets/AuthKey.p8',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('Issuer ID'));
    expect(uploader.uploadCalls, 0);
  });

  test('skips when auth key path is missing', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(artifactsDir: artifactsDir.path),
        config: const DistributionConfigModel(
          enabled: true,
          appstore: IosConfig(
            enabled: true,
            issuerId: 'issuer-123',
            apiKeyId: 'key-456',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('Auth Key'));
    expect(uploader.uploadCalls, 0);
  });

  test('skips when no ipa artifact is found', () async {
    uploader = FakeAppStoreUploader(ipaPath: null);
    handler = AppStoreHandler(uploader: uploader);

    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('No IPA'));
    expect(uploader.uploadCalls, 0);
  });

  test('uploads ipa when fully configured', () async {
    final ipaPath = '${artifactsDir.path}/Demo.ipa';
    await File(ipaPath).writeAsBytes([1, 2, 3]);
    uploader = FakeAppStoreUploader(ipaPath: ipaPath);
    handler = AppStoreHandler(uploader: uploader);

    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isSuccess, isTrue);
    expect(uploader.uploadCalls, 1);
    expect(uploader.lastIpaPath, ipaPath);
    expect(result.message, contains('Uploaded to App Store'));
  });

  test('returns failed when upload throws', () async {
    final ipaPath = '${artifactsDir.path}/Demo.ipa';
    uploader = FakeAppStoreUploader(ipaPath: ipaPath)
      ..throwError = Exception('transporter failed');
    handler = AppStoreHandler(uploader: uploader);

    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('transporter failed'));
    expect(uploader.uploadCalls, 1);
  });
}
