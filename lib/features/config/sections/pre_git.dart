import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/models/pre_git.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/switch_label.dart';
import '../bloc/config_bloc.dart';

class PreGit extends StatelessWidget {
  const PreGit({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, PreGitModel>(
      selector: (state) => state.preGit,
      builder: (context, preGit) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) =>
                bloc.add(UpdateConfig(config: preGit.copyWith(enabled: value))),
            enable: preGit.enabled,
            forceDisabled: false,
          ),
          title: "Pre-Git Config",
          description:
              "Automate Git hygiene before each build: write a commit message and let Fluship stage and commit any local changes for you. "
              "Enable Pre-Pull to sync with the remote branch first, so your build always starts from the latest code.",
          children: [
            AppTextField.label(
              initialValue: preGit.commitMessage,
              hint: "pre-release cleanup",
              enabled: preGit.enabled,
              label: "Commit Message",
              onChanged: (value) => bloc.add(
                UpdateConfig(config: preGit.copyWith(commitMessage: value)),
              ),
            ),
            const SizedBox(height: 16),
            SwitchLabel(
              disabled: !preGit.enabled,
              value: preGit.preCommit,
              label: "Pre-Release commit → git add . && git commit",
              onChange: (value) => bloc.add(
                UpdateConfig(config: preGit.copyWith(preCommit: value)),
              ),
            ),
            SwitchLabel(
              disabled: !preGit.enabled,
              value: preGit.prePull,
              label: "Pre-Pull → git pull",
              onChange: (value) => bloc.add(
                UpdateConfig(config: preGit.copyWith(prePull: value)),
              ),
            ),
          ],
        );
      },
    );
  }
}
