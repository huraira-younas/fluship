import 'package:fluship/shared/pipeline/git_step_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitStepBuilder', () {
    test('commit builds git add and commit command', () {
      final step = GitStepBuilder.commit(
        name: 'Pre-Commit',
        message: '1.0.0 cleanup',
      );

      expect(step.name, 'Pre-Commit');
      expect(step.command, 'git add . && git commit -m "1.0.0 cleanup"');
      expect(step.isInternal, isFalse);
    });

    test('pull builds git pull command with branch', () {
      final step = GitStepBuilder.pull(branch: 'develop', name: 'Pre-Pull');

      expect(step.name, 'Pre-Pull');
      expect(step.command, 'git pull origin develop');
    });

    test('push builds git push command with branch', () {
      final step = GitStepBuilder.push(branch: 'main', name: 'Post-Push');

      expect(step.name, 'Post-Push');
      expect(step.command, 'git push origin main');
    });
  });
}
