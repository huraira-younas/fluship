import 'command_step.dart';

abstract final class GitStepBuilder {
  static CommandStep commit({
    required String message,
    String name = 'Git Commit',
  }) => CommandStep(
    command: '(git add . && git commit -m "$message") || true',
    name: name,
  );

  static CommandStep pull({required String branch, String name = 'Git Pull'}) =>
      CommandStep(command: '(git pull origin $branch) || true', name: name);

  static CommandStep push({required String branch, String name = 'Git Push'}) =>
      CommandStep(command: '(git push origin $branch) || true', name: name);
}
