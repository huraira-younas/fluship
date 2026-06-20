import 'dart:io' show Directory, File, Platform;

import 'package:fluship/features/pipeline/services/pipeline_log_writer.dart';
import 'package:fluship/features/pipeline/fluship_workspace_paths.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/pipeline/pipeline_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('sanitizeProjectFolderName', () {
    test('lowercases and slugifies app names', () {
      expect(PipelineUtils.sanitizeProjectFolderName('ReelStay'), 'reelstay');
      expect(
        PipelineUtils.sanitizeProjectFolderName('My Cool App'),
        'my_cool_app',
      );
    });
  });

  group('buildPipelineLogFileName', () {
    test('builds versioned log file name', () {
      expect(
        PipelineUtils.buildPipelineLogFileName(
          version: '1.5.7',
          buildNumber: '5705',
        ),
        'v1.5.7_5705_logs.txt',
      );
    });

    test('sanitizes unsafe characters', () {
      expect(
        PipelineUtils.buildPipelineLogFileName(
          version: '1/0',
          buildNumber: '2*',
        ),
        'v1_0_2__logs.txt',
      );
    });
  });

  group('pipelineLogRelativePath', () {
    test('builds fluship lib logs path', () {
      expect(
        pipelineLogRelativePath(
          projectName: 'ReelStay',
          version: '1.5.4',
          buildNumber: '5700',
        ),
        'lib/logs/reelstay/v1.5.4_5700_logs.txt',
      );
    });
  });

  group('formatPipelineLogLines', () {
    test('writes each console line on its own row', () {
      final text = PipelineUtils.formatPipelineLogLines(const [
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

    test('writes logs under fluship lib/logs/project folder', () async {
      final writer = FilePipelineLogWriter(
        workspacePaths: FlushipWorkspacePaths(overrideRoot: tempDir.path),
      );
      final savedPath = await writer.save(
        projectName: 'ReelStay',
        buildNumber: '5700',
        version: '1.5.4',
        lines: const [
          ConsoleLine(stream: ConsoleStream.system, text: '[pipeline started]'),
          ConsoleLine(stream: ConsoleStream.system, text: '[exit 0]'),
        ],
      );

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(
        savedPath,
        contains(
          'lib${Platform.pathSeparator}logs${Platform.pathSeparator}reelstay${Platform.pathSeparator}v1.5.4_5700_logs.txt',
        ),
      );
      expect(
        savedPath,
        p.join(tempDir.path, 'lib', 'logs', 'reelstay', 'v1.5.4_5700_logs.txt'),
      );

      final content = await file.readAsString();
      expect(content, contains('[pipeline started]'));
      expect(content, contains('[exit 0]'));
    });
  });
}
