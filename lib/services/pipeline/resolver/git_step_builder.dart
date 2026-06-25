import 'command_step.dart';

abstract final class GitStepBuilder {
  static CommandStep commit({
    required String message,
    String name = 'Git Commit',
  }) => CommandStep(
    description: message.trim().isEmpty
        ? 'Stage all changes and create a git commit'
        : 'Stage all changes and commit with message "$message"',
    command: '(git add . && git commit -m "$message") || true',
    name: name,
  );

  static CommandStep pull({required String branch, String name = 'Git Pull'}) =>
      CommandStep(
        description: 'Pull the latest changes from origin/$branch',
        command: '(git pull origin $branch) || true',
        name: name,
      );

  static CommandStep push({required String branch, String name = 'Git Push'}) =>
      CommandStep(
        description: 'Push local commits to origin/$branch',
        command: '(git push origin $branch) || true',
        name: name,
      );
}
