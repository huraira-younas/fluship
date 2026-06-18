import 'package:fluship/services/console/parsing/marker_shell_output_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkerShellOutputParser', () {
    late MarkerShellOutputParser parser;

    setUp(() => parser = MarkerShellOutputParser());

    test('extracts stdout between markers', () {
      const input =
          'noise\n__FLUSHIP_BEGIN__\nHello World\n__FLUSHIP_END__:0\n';
      final result = parser.feed(input);

      expect(result.stdoutChunk, contains('Hello World'));
    });

    test('completes with exit code and cwd', () {
      const input =
          '__FLUSHIP_BEGIN__\noutput line\n'
          '__FLUSHIP_END__:0\n'
          '__FLUSHIP_CWD__\n'
          'C:\\project\\android\n'
          '__FLUSHIP_CWD_END__\n';

      final result = parser.feed(input);

      expect(result.isCommandComplete, isTrue);
      expect(result.exitCode, 0);
      expect(result.cwd, 'C:\\project\\android');
      expect(result.stdoutChunk, contains('output line'));
    });

    test('normalizes Windows cmd prompt duplication in cwd', () {
      const input =
          '__FLUSHIP_BEGIN__\n'
          '__FLUSHIP_END__:0\n'
          '__FLUSHIP_CWD__\n'
          'C:\\Users\\app>cd\r\n'
          'C:\\Users\\app\r\n'
          '__FLUSHIP_CWD_END__\n';

      final result = parser.feed(input);

      expect(result.cwd, r'C:\Users\app');
    });

    test('handles partial chunks across feeds', () {
      final first = parser.feed('__FLUSHIP_BEGIN__\nhel');
      expect(first.stdoutChunk ?? '', contains('hel'));

      final mid = parser.feed('lo\n__FLUSHIP_END__:1\n__FLUSHIP_CWD__\npwd\n');

      expect(mid.stdoutChunk ?? '', contains('lo'));
      expect(mid.exitCode, 1);

      final done = parser.feed('__FLUSHIP_CWD_END__\n');
      expect(done.isCommandComplete, isTrue);
    });

    test('streams stdout before end marker arrives', () {
      final first = parser.feed('__FLUSHIP_BEGIN__\nDeleting build...');
      expect(first.stdoutChunk, contains('Deleting build...'));

      final partial = parser.feed('\nStill working...');

      expect(partial.stdoutChunk, contains('Still working...'));
      expect(partial.isCommandComplete, isFalse);
    });
  });
}
