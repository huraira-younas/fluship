import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats play, drive, and app store labels from one model', () {
    const play = PipelineUploadProgress(
      channel: UploadChannel.play,
      fileName: 'app.aab',
      bytes: 12 * 1024 * 1024,
      total: 45 * 1024 * 1024,
      percent: 27,
    );

    expect(play.headerLabel, 'Play Store 27%');
    expect(play.panelLabel, 'Uploading to Play Store 27%');
    expect(play.caption, contains('27%'));
    expect(play.caption, contains('app.aab'));
    expect(play.consoleLine, startsWith('Play Store'));
    expect(play.fraction, closeTo(0.27, 0.001));

    const store = PipelineUploadProgress(
      channel: UploadChannel.appStore,
      fileName: 'app.ipa',
      percent: 42,
    );
    expect(store.headerLabel, 'App Store 42%');
    expect(store.consoleLine, contains('42%'));

    const drive = PipelineUploadProgress(
      channel: UploadChannel.drive,
      fileName: 'app.apk',
      bytes: 10,
      total: 20,
      percent: 50,
      fileIndex: 2,
      fileCount: 3,
    );
    expect(drive.caption, contains('file 2/3'));
  });

  test('skips the same percent for the same file', () {
    final gate = UploadProgressGate();
    const first = PipelineUploadProgress(
      channel: UploadChannel.play,
      fileName: 'app.aab',
      percent: 10,
      bytes: 10,
      total: 100,
    );
    const samePercent = PipelineUploadProgress(
      channel: UploadChannel.play,
      fileName: 'app.aab',
      percent: 10,
      bytes: 11,
      total: 100,
    );
    const nextPercent = PipelineUploadProgress(
      channel: UploadChannel.play,
      fileName: 'app.aab',
      percent: 11,
      bytes: 11,
      total: 100,
    );
    const nextFile = PipelineUploadProgress(
      channel: UploadChannel.drive,
      fileName: 'app-arm64.apk',
      percent: 11,
      fileIndex: 2,
      fileCount: 2,
    );

    expect(gate.allow(first), isTrue);
    expect(gate.allow(samePercent), isFalse);
    expect(gate.allow(nextPercent), isTrue);
    expect(gate.allow(nextFile), isTrue);
  });
}
