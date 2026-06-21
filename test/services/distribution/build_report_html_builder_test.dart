import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

const _testTheme = ReportHtmlTheme(
  borderLr: 'border-left:1px solid #1e293b;border-right:1px solid #1e293b;',
  bodyOpen:
      '<!DOCTYPE html><html><head><meta charset="utf-8"></head>'
      '<body style="margin:0;padding:24px 12px;background:#2e3440;">'
      '<div style="max-width:560px;margin:0 auto;">',
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

void main() {
  const builder = ReportHtmlBuilder();

  group('ReportHtmlBuilder', () {
    test('includes escaped app name and step rows', () {
      final html = builder.build(
        steps: const [
          ReportStepResult(
            name: 'Build APK',
            elapsed: Duration(seconds: 12),
            success: true,
          ),
          ReportStepResult(
            name: 'Collect & <script>',
            elapsed: Duration(milliseconds: 500),
            success: false,
          ),
        ],
        totalElapsed: '1m 5s',
        platforms: 'Android',
        buildNumber: '42',
        theme: _testTheme,
        success: false,
        appName: 'My App & Co',
        version: '1.2.0',
      );

      expect(html, contains('My App &amp; Co'));
      expect(html, contains('Build APK'));
      expect(html, contains('Collect &amp; &lt;script&gt;'));
      expect(html, contains('✗ Failed'));
      expect(html, contains('Build Failed'));
      expect(html, contains('v1.2.0+42'));
      expect(html, contains('Pipeline Steps'));
    });

    test('uses theme colors in HTML output', () {
      final html = builder.build(
        steps: const [
          ReportStepResult(
            name: 'Clean',
            elapsed: Duration(seconds: 1),
            success: true,
          ),
        ],
        totalElapsed: '1s',
        buildNumber: '1',
        platforms: 'Android',
        theme: _testTheme,
        appName: 'Demo',
        version: '1.0.0',
        success: true,
      );

      expect(html, contains('#2e3440'));
      expect(html, contains('#3b4252'));
      expect(html, contains('#81a1c1'));
      expect(html, contains('#a3be8c'));
    });

    test('stepsFromPipelineViews skips pending steps', () {
      final steps = builder.stepsFromPipelineViews(const [
        PipelineStepView(
          command: 'flutter clean',
          status: PipelineStepStatus.completed,
          name: 'Clean',
          elapsed: Duration(seconds: 2),
        ),
        PipelineStepView(
          command: 'flutter pub get',
          status: PipelineStepStatus.pending,
          name: 'Get',
        ),
      ]);

      expect(steps, hasLength(1));
      expect(steps.first.name, 'Clean');
      expect(steps.first.success, isTrue);
    });

    test('buildDriveLink includes files and escaped link', () {
      final html = builder.buildDriveLink(
        fileNames: const ['MyApp-v1.0+1.apk', 'evil<script>.aab'],
        buildNumber: '1',
        theme: _testTheme,
        version: '1.0.0',
        label: 'My App',
        link: 'https://drive.google.com/drive/folders/abc?id=1&x=2',
      );

      expect(html, contains('MyApp-v1.0+1.apk'));
      expect(html, contains('evil&lt;script&gt;.aab'));
      expect(html, contains('Open in Google Drive'));
      expect(html, contains('Anyone with the link can view'));
      expect(html, contains('Uploaded Files'));
      expect(
        html,
        contains(
          'https://drive.google.com/drive/folders/abc?id=1&amp;x=2',
        ),
      );
    });
  });
}
