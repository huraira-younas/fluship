import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/console/utils/console_line_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyConsoleLine', () {
    test('keeps flutter and gradle stderr notes as info or warn', () {
      expect(
        classifyConsoleLine(
          'Running Gradle task assembleRelease...',
          ConsoleStream.stderr,
        ),
        ConsoleLineKind.info,
      );
      expect(
        classifyConsoleLine(
          'Note: Some input files use or override a deprecated API.',
          ConsoleStream.stderr,
        ),
        ConsoleLineKind.warn,
      );
      expect(
        classifyConsoleLine(
          'warning: The option setting is experimental',
          ConsoleStream.stderr,
        ),
        ConsoleLineKind.warn,
      );
    });

    test('marks real failures as error', () {
      expect(
        classifyConsoleLine('FAILURE: Build failed with an exception.'),
        ConsoleLineKind.error,
      );
      expect(
        classifyConsoleLine('error: undefined identifier'),
        ConsoleLineKind.error,
      );
      expect(classifyConsoleLine('[exit 1]'), ConsoleLineKind.error);
      expect(
        classifyConsoleLine('Play Store failed: missing service account'),
        ConsoleLineKind.error,
      );
    });

    test('does not treat zero-error summaries as errors', () {
      expect(classifyConsoleLine('0 errors found'), ConsoleLineKind.info);
    });

    test('classifies progress, success, and cancel', () {
      expect(
        classifyConsoleLine('Play Store  12.3 / 45.0 MB  27%  app.aab'),
        ConsoleLineKind.progress,
      );
      expect(
        classifyConsoleLine('Play Store finished in 1m 2s'),
        ConsoleLineKind.success,
      );
      expect(
        classifyConsoleLine('Pipeline cancelled after 12s'),
        ConsoleLineKind.warn,
      );
      expect(classifyConsoleLine('[exit 0]'), ConsoleLineKind.info);
      expect(
        classifyConsoleLine('> flutter clean', ConsoleStream.input),
        ConsoleLineKind.info,
      );
      expect(
        classifyConsoleLine('Play Store: creating edit for com.example'),
        ConsoleLineKind.info,
      );
    });

    test('upgradeConsoleLineKind keeps the stronger kind', () {
      expect(
        upgradeConsoleLineKind(ConsoleLineKind.info, ConsoleLineKind.error),
        ConsoleLineKind.error,
      );
      expect(
        upgradeConsoleLineKind(ConsoleLineKind.error, ConsoleLineKind.warn),
        ConsoleLineKind.error,
      );
    });
  });
}
