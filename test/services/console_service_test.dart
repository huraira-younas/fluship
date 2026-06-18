import 'package:fluship/services/console_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ConsoleService runs command in working directory', () async {
    final service = ConsoleService();
    final output = <String>[];

    final exitCode = await service.run(
      workingDirectory: r'c:\Users\Senpai\Desktop\fluship',
      command: 'echo hello',
      onStdout: output.add,
      onStderr: (_) {},
    );

    expect(exitCode, 0);
    expect(output.join(), contains('hello'));
    expect(service.isRunning, isFalse);
  });

  test('ConsoleService rejects missing working directory', () async {
    final service = ConsoleService();

    expect(
      () => service.run(
        workingDirectory: r'c:\nonexistent\path\fluship',
        command: 'echo test',
        onStdout: (_) {},
        onStderr: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
  });
}
