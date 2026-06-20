import 'package:fluship/features/pipeline/pipeline_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPipelineDuration', () {
    test('formats sub-second durations as milliseconds', () {
      expect(
        PipelineUtils.formatPipelineDuration(const Duration(milliseconds: 450)),
        '450ms',
      );
    });

    test('formats seconds with one decimal under 10s', () {
      expect(
        PipelineUtils.formatPipelineDuration(
          const Duration(milliseconds: 1200),
        ),
        '1.2s',
      );
    });

    test('formats whole seconds at 10s or above', () {
      expect(
        PipelineUtils.formatPipelineDuration(const Duration(seconds: 12)),
        '12s',
      );
    });

    test('formats minutes and seconds', () {
      expect(
        PipelineUtils.formatPipelineDuration(const Duration(seconds: 83)),
        '1m 23s',
      );
    });
  });
}
