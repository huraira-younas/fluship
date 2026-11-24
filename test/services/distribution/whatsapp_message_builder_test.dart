import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

const _own = 'Send to WhatsApp';

PipelineStepView _step(
  String name,
  PipelineStepStatus status, {
  Duration? elapsed = const Duration(seconds: 3),
  String? error,
}) => PipelineStepView(
  errorMessage: error,
  description: name,
  elapsed: elapsed,
  status: status,
  name: name,
);

PipelineRunSnapshot _snapshot({
  PipelineRunStatus status = PipelineRunStatus.completed,
  List<PipelineStepView> steps = const [],
  Map<String, String> links = const {},
}) => PipelineRunSnapshot(
  totalElapsed: const Duration(minutes: 2, seconds: 5),
  finishedAt: DateTime(2026, 6, 20, 14, 30),
  startedAt: DateTime(2026, 6, 20, 14, 28),
  artifactsDir: '/tmp/artifacts',
  platforms: 'Android',
  logFilePath: '',
  buildNumber: '42',
  runStatus: status,
  appName: 'Demo',
  version: '1.0.0',
  links: links,
  steps: steps,
);

void main() {
  const builder = WhatsAppMessageBuilder();

  test('summarises a successful run', () {
    final text = builder.build(
      _snapshot(
        steps: [
          _step('Clean', .completed),
          _step('Build APK', .completed, elapsed: const Duration(seconds: 90)),
        ],
      ),
      ownStepName: _own,
    );

    expect(
      text,
      '✅ *Demo* v1.0.0+42 succeeded\n'
      'Platforms: Android\n'
      'Duration: 2m 5s\n'
      '\n'
      '*Steps*\n'
      '✓ Clean (3.0s)\n'
      '✓ Build APK (1m 30s)',
    );
  });

  test('marks failed, skipped and cancelled steps', () {
    final text = builder.build(
      _snapshot(
        status: .failed,
        steps: [
          _step('Build APK', .failed, error: 'Gradle failed\nstack trace'),
          _step('Collect APK', .skipped, elapsed: null),
          _step('Post-Push', .cancelled, elapsed: null),
        ],
      ),
      ownStepName: _own,
    );

    expect(text, startsWith('❌ *Demo* v1.0.0+42 failed\n'));
    expect(text, contains('✗ Build APK (3.0s): Gradle failed'));
    expect(text, isNot(contains('stack trace')));
    expect(text, contains('– Collect APK (skipped)'));
    expect(text, contains('– Post-Push (cancelled)'));
  });

  test('leaves out its own step and steps that have not run', () {
    final text = builder.build(
      _snapshot(
        steps: [
          _step('Clean', .completed),
          _step(_own, .running, elapsed: null),
          _step('Later', .pending, elapsed: null),
        ],
      ),
      ownStepName: _own,
    );

    expect(text, contains('✓ Clean'));
    expect(text, isNot(contains(_own)));
    expect(text, isNot(contains('Later')));
  });

  test('lists built files and published links', () {
    final text = builder.build(
      _snapshot(
        links: {'Google Drive': 'https://drive.google.com/drive/folders/abc'},
      ),
      files: [(name: 'Demo.apk', bytes: 25 * 1024 * 1024)],
      ownStepName: _own,
    );

    expect(text, contains('*Files*\n• Demo.apk (25.0 MB)'));
    expect(
      text,
      endsWith(
        '*Links*\nGoogle Drive: https://drive.google.com/drive/folders/abc',
      ),
    );
    expect(text, isNot(contains('*Steps*')));
  });

  test('omits the file and link sections when there are none', () {
    final text = builder.build(_snapshot(), ownStepName: _own);

    expect(text, isNot(contains('*Files*')));
    expect(text, isNot(contains('*Links*')));
  });

  test('drops steps before it drops the link when the text is too long', () {
    final text = builder.build(
      _snapshot(
        links: {'Google Drive': 'https://drive.google.com/drive/folders/abc'},
        steps: [
          for (var i = 0; i < 400; i++)
            _step('Step number $i with a long name', .completed),
        ],
      ),
      ownStepName: _own,
    );

    expect(text.length, lessThanOrEqualTo(WhatsAppLimits.maxTextLength));
    expect(text, contains('✓ Step number 0 '));
    expect(text, contains(RegExp(r'… and \d+ more')));
    expect(text, endsWith('https://drive.google.com/drive/folders/abc'));
  });

  test('never exceeds the limit it is given', () {
    final text = builder.build(
      _snapshot(
        links: {'Google Drive': 'https://example.com/${'x' * 300}'},
        steps: [_step('Clean', .completed)],
      ),
      ownStepName: _own,
      maxLength: 120,
    );

    expect(text.length, lessThanOrEqualTo(120));
  });
}
