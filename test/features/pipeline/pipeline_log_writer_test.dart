import 'dart:io' show Directory, File, Platform;

import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:fluship/features/console/models/console_line.dart';
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

  group('sanitizePathSegment', () {
    test('sanitizes unsafe characters', () {
      expect(PipelineUtils.sanitizePathSegment('1/0'), '1_0');
      expect(PipelineUtils.sanitizePathSegment('2*'), '2_');
    });
  });

  group('pipelineLogRelativePath', () {
    test('builds fluship outputs path', () {
      expect(
        pipelineLogRelativePath(
          projectName: 'ReelStay',
          version: '1.5.4',
          buildNumber: '5700',
        ),
        'outputs/reelstay/v1.5.4/5700/logs.txt',
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

    test('writes logs under fluship outputs/project/version/build folder', () async {
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
          'outputs${Platform.pathSeparator}reelstay${Platform.pathSeparator}v1.5.4${Platform.pathSeparator}5700${Platform.pathSeparator}logs.txt',
        ),
      );
      expect(
        savedPath,
        p.join(tempDir.path, 'outputs', 'reelstay', 'v1.5.4', '5700', 'logs.txt'),
      );

      final content = await file.readAsString();
      expect(content, contains('[pipeline started]'));
      expect(content, contains('[exit 0]'));
    });
  });
}
