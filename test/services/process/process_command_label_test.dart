import 'package:fluship/services/process/process_command_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessCommandLabel', () {
    test('extracts flutter command name', () {
      expect(
        ProcessCommandLabel.displayName('flutter build apk --release'),
        'flutter build',
      );
    });

    test('extracts gradle label', () {
      expect(
        ProcessCommandLabel.displayName('/path/java -gradle-daemon'),
        'Gradle',
      );
    });

    test('extracts aapt2 label', () {
      expect(
        ProcessCommandLabel.displayName('/cache/aapt2-8.11.1-osx/aapt2'),
        'aapt2',
      );
    });
  });
}
