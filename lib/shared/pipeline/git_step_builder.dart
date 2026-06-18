import 'command_step.dart';

abstract final class GitStepBuilder {
  static CommandStep commit({
    required String message,
    String name = 'Git Commit',
  }) =>
      CommandStep(command: 'git add . && git commit -m "$message"', name: name);

  static CommandStep pull({required String branch, String name = 'Git Pull'}) =>
      CommandStep(command: 'git pull origin $branch', name: name);

  static CommandStep push({required String branch, String name = 'Git Push'}) =>
      CommandStep(command: 'git push origin $branch', name: name);
}
