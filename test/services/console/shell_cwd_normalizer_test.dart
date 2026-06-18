import 'package:fluship/services/console/parsing/shell_cwd_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeShellCwd', () {
    test('returns clean path unchanged', () {
      expect(
        normalizeShellCwd(r'C:\Users\Senpai\Desktop\Programs\reelstay'),
        r'C:\Users\Senpai\Desktop\Programs\reelstay',
      );
    });

    test('strips duplicated Windows prompt prefix', () {
      expect(
        normalizeShellCwd(
          r'C:\Users\Senpai\Desktop\Programs\reelstay>'
          r'C:\Users\Senpai\Desktop\Programs\reelstay',
        ),
        r'C:\Users\Senpai\Desktop\Programs\reelstay',
      );
    });

    test('uses last path-like line from multiline capture', () {
      expect(
        normalizeShellCwd(
          'C:\\project\\android>cd\r\n'
          'C:\\project\\android\r\n',
        ),
        r'C:\project\android',
      );
    });
  });
}
