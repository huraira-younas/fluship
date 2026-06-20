import 'dart:io' show Directory, File, Platform;

import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/pipeline/services/pipeline_log_writer.dart';
import 'package:fluship/features/pipeline/utils/pipeline_log_file_name.dart';
import 'package:fluship/features/pipeline/utils/pipeline_log_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPipelineLogFileName', () {
    test('builds versioned log file name', () {
      expect(
        buildPipelineLogFileName(version: '1.5.7', buildNumber: '5705'),
        'v1.5.7_5705_logs.txt',
      );
    });

    test('sanitizes unsafe characters', () {
      expect(
        buildPipelineLogFileName(version: '1/0', buildNumber: '2*'),
        'v1_0_2__logs.txt',
      );
    });
  });

  group('formatPipelineLogLines', () {
    test('writes each console line on its own row', () {
      final text = formatPipelineLogLines(const [
        ConsoleLine(stream: ConsoleStream.system, text: '[pipeline started]'),
        ConsoleLine(stream: ConsoleStream.input, text: '> flutter clean'),
        ConsoleLine(stream: ConsoleStream.system, text: '[exit 0]'),
      ]);

      expect(text, '[pipeline started]\n> flutter clean\n[exit 0]\n');
    });
  });

  group('FilePipelineLogWriter', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fluship_pipeline_log_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes logs under project logs folder', () async {
      const writer = FilePipelineLogWriter();
      final savedPath = await writer.save(
        projectRoot: tempDir.path,
        buildNumber: '42',
        version: '2.0.0',
        lines: const [
          ConsoleLine(stream: ConsoleStream.system, text: '[pipeline started]'),
          ConsoleLine(stream: ConsoleStream.system, text: '[exit 0]'),
        ],
      );

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(savedPath, contains('logs${Platform.pathSeparator}v2.0.0_42_logs.txt'));

      final content = await file.readAsString();
      expect(content, contains('[pipeline started]'));
      expect(content, contains('[exit 0]'));
    });
  });
}
