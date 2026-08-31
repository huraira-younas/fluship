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

class FakePlayStoreUploader implements PlayStoreUploader {
  FakePlayStoreUploader({this.uploadedName = 'Demo.aab'});

  final String uploadedName;
  String? lastReleaseNotes;
  var uploadCalls = 0;
  String? lastAabPath;
  Object? throwError;

  @override
  Future<String> upload({
    required PlayStoreDistribution distribution,
    required String packageName,
    DistributionLogger? logger,
    required String saJsonPath,
    required String aabPath,
    String? releaseNotes,
    UploadByteProgress? onProgress,
  }) async {
    uploadCalls++;
    lastAabPath = aabPath;
    lastReleaseNotes = releaseNotes;
    if (throwError != null) throw throwError!;
    onProgress?.call(50, 100, uploadedName);
    return uploadedName;
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
  void Function(PipelineUploadProgress progress)? onUploadProgress,
}) {
  return DistributionContext(
    emailTheme: _testTheme,
    snapshot: snapshot,
    config:
        config ??
        const DistributionConfigModel(
          enabled: true,
          playstore: GooglePlayConsoleConfig(
            distribution: PlayStoreDistribution.internal,
            packageName: 'com.example.demo',
            saJsonPath: '/secrets/play-sa.json',
          ),
        ),
    logger: FakeDistributionLogger(),
    onUploadProgress: onUploadProgress,
  );
}

void main() {
  late FakePlayStoreUploader uploader;
  late PlayStoreHandler handler;
  late Directory artifactsDir;
  late String aabPath;

  setUp(() async {
    uploader = FakePlayStoreUploader();
    handler = PlayStoreHandler(uploader: uploader);
    artifactsDir = await Directory.systemTemp.createTemp(
      'fluship_playstore_test_',
    );
    aabPath = '${artifactsDir.path}/Demo.aab';
  });

  tearDown(() async {
    if (await artifactsDir.exists()) {
      await artifactsDir.delete(recursive: true);
    }
  });

  test('skips when play store distribution is disabled', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(artifactsDir: artifactsDir.path),
        config: const DistributionConfigModel(
          enabled: true,
          playstore: GooglePlayConsoleConfig(
            packageName: 'com.example.demo',
            saJsonPath: '/secrets/play-sa.json',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(uploader.uploadCalls, 0);
  });

  test('skips when service account json is missing', () async {
    final result = await handler.run(
      _context(
        snapshot: _snapshot(artifactsDir: artifactsDir.path),
        config: const DistributionConfigModel(
          enabled: true,
          playstore: GooglePlayConsoleConfig(
            distribution: PlayStoreDistribution.internal,
            packageName: 'com.example.demo',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('Service account JSON'));
    expect(uploader.uploadCalls, 0);
  });

  test('skips when package name is missing', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
        config: const DistributionConfigModel(
          enabled: true,
          playstore: GooglePlayConsoleConfig(
            distribution: PlayStoreDistribution.production,
            saJsonPath: '/secrets/play-sa.json',
          ),
        ),
      ),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('Package name'));
    expect(uploader.uploadCalls, 0);
  });

  test('skips when this run collected no aab', () async {
    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isSkipped, isTrue);
    expect(result.message, contains('No AAB'));
    expect(uploader.uploadCalls, 0);
  });

  test('skips an aab left in the folder by an earlier run', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);

    final result = await handler.run(
      _context(snapshot: _snapshot(artifactsDir: artifactsDir.path)),
    );

    expect(result.isSkipped, isTrue);
    expect(uploader.uploadCalls, 0);
  });

  test('uploads aab when fully configured', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(uploader.uploadCalls, 1);
    expect(uploader.lastAabPath, aabPath);
    expect(result.message, contains('Uploaded to Play Store'));
  });

  test('passes release notes to uploader when configured', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
        config: const DistributionConfigModel(
          enabled: true,
          releaseNotes: 'Bug fixes and performance improvements.',
          playstore: GooglePlayConsoleConfig(
            distribution: PlayStoreDistribution.internal,
            packageName: 'com.example.demo',
            saJsonPath: '/secrets/play-sa.json',
          ),
        ),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(
      uploader.lastReleaseNotes,
      'Bug fixes and performance improvements.',
    );
  });

  test('passes null release notes when empty', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);

    await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
        config: const DistributionConfigModel(
          enabled: true,
          releaseNotes: '   ',
          playstore: GooglePlayConsoleConfig(
            distribution: PlayStoreDistribution.internal,
            packageName: 'com.example.demo',
            saJsonPath: '/secrets/play-sa.json',
          ),
        ),
      ),
    );

    expect(uploader.lastReleaseNotes, isNull);
  });

  test('forwards byte progress to the context', () async {
    await File(aabPath).writeAsBytes([1, 2, 3]);
    PipelineUploadProgress? last;

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
        onUploadProgress: (progress) => last = progress,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(last?.channel, UploadChannel.play);
    expect(last?.percent, 50);
    expect(last?.fileName, 'Demo.aab');
  });

  test('returns failed when upload throws', () async {
    uploader.throwError = Exception('play api failed');

    final result = await handler.run(
      _context(
        snapshot: _snapshot(
          artifactsDir: artifactsDir.path,
          collected: [aabPath],
        ),
      ),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('play api failed'));
    expect(uploader.uploadCalls, 1);
  });
}
