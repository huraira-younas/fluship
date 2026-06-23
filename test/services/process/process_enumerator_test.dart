import 'package:fluship/services/process/process_enumerator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessEnumerator.parseUnixOutput', () {
    test('parses ps rows', () {
      const output = '''
  123  456 flutter build apk
  789   12 /bin/sh
''';

      final rows = ProcessEnumerator.parseUnixOutput(output);

      expect(rows, hasLength(2));
      expect(rows.first.pid, 123);
      expect(rows.first.ppid, 456);
      expect(rows.first.command, 'flutter build apk');
    });

    test('ignores malformed lines', () {
      final rows = ProcessEnumerator.parseUnixOutput('not-a-process\n');
      expect(rows, isEmpty);
    });
  });

  group('ProcessEnumerator.parseWindowsOutput', () {
    test('parses PowerShell csv rows', () {
      const output = '''
"ProcessId","ParentProcessId","CommandLine"
"123","456","cmd.exe /c flutter build"
''';

      final rows = ProcessEnumerator.parseWindowsOutput(output);

      expect(rows, hasLength(1));
      expect(rows.single.pid, 123);
      expect(rows.single.ppid, 456);
      expect(rows.single.command, 'cmd.exe /c flutter build');
    });

    test('parses quoted command lines with commas', () {
      const output = '''
"ProcessId","ParentProcessId","CommandLine"
"123","456","flutter build apk, --debug"
''';

      final rows = ProcessEnumerator.parseWindowsOutput(output);

      expect(rows, hasLength(1));
      expect(rows.single.command, 'flutter build apk, --debug');
    });

    test('parses legacy wmic csv rows', () {
      const output = '''
Node,CommandLine,ParentProcessId,ProcessId
DESKTOP,cmd.exe /c flutter build,456,123
''';

      final rows = ProcessEnumerator.parseWindowsOutput(output);

      expect(rows, hasLength(1));
      expect(rows.single.pid, 123);
      expect(rows.single.ppid, 456);
      expect(rows.single.command, 'cmd.exe /c flutter build');
    });
  });
}
