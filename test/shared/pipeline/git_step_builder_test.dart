import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitStepBuilder', () {
    test('commit builds git add and commit command that ignores errors', () {
      final step = GitStepBuilder.commit(
        name: 'Pre-Commit',
        message: '1.0.0 cleanup',
      );

      expect(step.name, 'Pre-Commit');
      expect(
        step.command,
        '(git add . && git commit -m "1.0.0 cleanup") || true',
      );
      expect(step.isInternal, isFalse);
    });

    test('pull builds git pull command that ignores errors', () {
      final step = GitStepBuilder.pull(branch: 'develop', name: 'Pre-Pull');

      expect(step.name, 'Pre-Pull');
      expect(step.command, '(git pull origin develop) || true');
    });

    test('push builds git push command that ignores errors', () {
      final step = GitStepBuilder.push(branch: 'main', name: 'Post-Push');

      expect(step.name, 'Post-Push');
      expect(step.command, '(git push origin main) || true');
    });
  });
}
