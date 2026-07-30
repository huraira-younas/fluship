import 'pipeline_step_id.dart';
import 'command_step.dart';

abstract final class GitStepBuilder {
  static CommandStep commit({
    String name = 'Git Commit',
    required String message,
    PipelineStepId? id,
  }) => CommandStep(
    description: message.trim().isEmpty
        ? 'Stage all changes and create a git commit'
        : 'Stage all changes and commit with message "$message"',
    command: '(git add . && git commit -m "$message") || true',
    name: name,
    id: id,
  );

  static CommandStep pull({
    String name = 'Git Pull',
    required String branch,
    PipelineStepId? id,
  }) => CommandStep(
    description: 'Pull the latest changes from origin/$branch',
    command: '(git pull origin $branch) || true',
    name: name,
    id: id,
  );

  static CommandStep push({
    String name = 'Git Push',
    required String branch,
    PipelineStepId? id,
  }) => CommandStep(
    description: 'Push local commits to origin/$branch',
    command: '(git push origin $branch) || true',
    name: name,
    id: id,
  );
}
