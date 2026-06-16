import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/models/pre_git.dart';

import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

class PreGit extends StatefulWidget {
  const PreGit({super.key});

  @override
  State<PreGit> createState() => _PreGitState();
}

class _PreGitState extends State<PreGit> {
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
              "Set the commit message Fluship will use when committing your changes.",
          children: [
            AppTextField.label(
              initialValue: preGit.commitMessage,
              hint: "pre-release cleanup",
              label: "Commit Message",
              onChanged: (value) => bloc.add(
                UpdateConfig(config: preGit.copyWith(commitMessage: value)),
              ),
            ),
            const SizedBox(height: 16),
            SwitchLabel(
              value: preGit.preCommit,
              label: "Pre-Release commit → git add . && git commit",
              onChange: (value) => bloc.add(
                UpdateConfig(config: preGit.copyWith(preCommit: value)),
              ),
            ),
            SwitchLabel(
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
