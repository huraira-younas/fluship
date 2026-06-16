import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/models/post_git.dart';

import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class PostGit extends StatelessWidget {
  const PostGit({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, PostGitModel>(
      selector: (state) => state.postGit,
      builder: (context, postGit) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: postGit.copyWith(enabled: value)),
            ),
            enable: postGit.enabled,
            forceDisabled: false,
          ),
          title: "Post-Git Config",
          description:
              "Clean up your repo after a successful build: Fluship can stage and commit any files changed during the pipeline — version bumps, generated assets, changelogs. "
              "Enable Post-Push to automatically push those commits to the remote, so your branch stays in sync without manual intervention.",
          children: [
            AppTextField.label(
              initialValue: postGit.commitMessage,
              hint: "post-build release",
              enabled: postGit.enabled,
              label: "Commit Message",
              onChanged: (value) => bloc.add(
                UpdateConfig(config: postGit.copyWith(commitMessage: value)),
              ),
            ),
            const SizedBox(height: 16),
            SwitchLabel(
              disabled: !postGit.enabled,
              value: postGit.postCommit,
              label: "Post-Build commit → git add . && git commit",
              onChange: (value) => bloc.add(
                UpdateConfig(config: postGit.copyWith(postCommit: value)),
              ),
            ),
            SwitchLabel(
              disabled: !postGit.enabled,
              value: postGit.postPush,
              label: "Post-Push → git push",
              onChange: (value) => bloc.add(
                UpdateConfig(config: postGit.copyWith(postPush: value)),
              ),
            ),
          ],
        );
      },
    );
  }
}
