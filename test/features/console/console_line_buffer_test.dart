import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/console/utils/console_line_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsoleLineBuffer', () {
    test('mergeChunk merges consecutive same stream', () {
      const lines = [ConsoleLine(stream: ConsoleStream.stdout, text: 'a')];
      final merged = ConsoleLineBuffer.mergeChunk(
        stream: .stdout,
        lines: lines,
        chunk: 'b',
      );

      expect(merged, hasLength(1));
      expect(merged.first.text, 'ab');
      expect(merged.first.kind, ConsoleLineKind.info);
    });

    test('mergeChunk upgrades kind when a later chunk is an error', () {
      const lines = [
        ConsoleLine(
          stream: ConsoleStream.stderr,
          text: 'Running Gradle task',
          kind: ConsoleLineKind.info,
        ),
      ];
      final merged = ConsoleLineBuffer.mergeChunk(
        stream: .stderr,
        lines: lines,
        chunk: ' FAILURE: Build failed with an exception.',
      );

      expect(merged, hasLength(1));
      expect(merged.first.kind, ConsoleLineKind.error);
    });

    test('appendLine does not merge with later process chunks', () {
      final lines = ConsoleLineBuffer.appendLine(
        lines: const [],
        stream: .system,
        text: 'Play Store: creating edit for com.example',
      );
      final merged = ConsoleLineBuffer.mergeChunk(
        stream: .system,
        lines: lines,
        chunk: ' extra',
      );

      expect(merged, hasLength(2));
      expect(lines.single.complete, isTrue);
      expect(lines.single.kind, ConsoleLineKind.info);
    });

    test('trimLines caps output', () {
      final lines = List.generate(
        2100,
        (i) => ConsoleLine(stream: ConsoleStream.stdout, text: '$i'),
      );
      final trimmed = ConsoleLineBuffer.trimLines(lines);

      expect(trimmed.length, 2000);
      expect(trimmed.first.text, '100');
    });

    test('limitText truncates long text', () {
      final text = 'x' * 300000;
      final limited = ConsoleLineBuffer.limitText(text);

      expect(limited.length, lessThan(text.length));
      expect(limited, contains('[output truncated]'));
    });
  });
}
