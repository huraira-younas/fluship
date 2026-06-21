import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = BuildReportHtmlBuilder();

  group('BuildReportHtmlBuilder', () {
    test('includes escaped app name and step rows', () {
      final html = builder.build(
        steps: const [
          BuildReportStepResult(
            name: 'Build APK',
            elapsed: Duration(seconds: 12),
            success: true,
          ),
          BuildReportStepResult(
            name: 'Collect & <script>',
            elapsed: Duration(milliseconds: 500),
            success: false,
          ),
        ],
        totalElapsed: '1m 5s',
        platforms: 'Android',
        buildNumber: '42',
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
  });
}
