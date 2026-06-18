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
