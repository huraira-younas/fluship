import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/switch_labels_row.dart';
import '../widgets/switch_label.dart';
import '../bloc/config_bloc.dart';

class PostBuild extends StatelessWidget {
  const PostBuild({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, PostBuildConfigModel>(
      selector: (state) => state.postBuild,
      builder: (context, postBuild) {
        final powerConfig = postBuild.powerConfig;
        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: postBuild.copyWith(enabled: value)),
            ),
            enable: postBuild.enabled,
            forceDisabled: false,
          ),
          title: "Post Build Config",
          description:
              "Manage your iOS build steps in one place: run a full CocoaPods reset to clear stale pod caches before compilation, and toggle IPA export for App Store or ad-hoc distribution. "
              "Pod Clean is especially useful when native dependency versions change and a simple pod install isn't enough.",
          children: [
            SwitchLabel(
              disabled: !postBuild.enabled,
              value: postBuild.openOutputs,
              label: "Open output folder",
              onChange: (value) => bloc.add(
                UpdateConfig(config: postBuild.copyWith(openOutputs: value)),
              ),
            ),
            SwitchLabelsRow<PowerAction>(
              disabled: !postBuild.enabled,
              labels: PowerAction.values,
              value: powerConfig?.action,
              defaultValue: .shutdown,
              switchLabel: 'Power',
              onChange: (value) => bloc.add(
                UpdateConfig(
                  config: postBuild.copyWith(
                    clearPowerConfig: value == null,
                    powerConfig: value != null
                        ? (powerConfig ?? const PowerConfig()).copyWith(
                            action: value,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (powerConfig != null) ...[
              AppTextField.label(
                initialValue: powerConfig.delay.inSeconds.toString(),
                enabled: postBuild.enabled,
                label: "Delay (seconds)",
                keyboardType: .number,
                hint: "10",
                onChanged: (value) {
                  final seconds = int.tryParse(value.trim());
                  if (seconds == null) return;
                  bloc.add(
                    UpdateConfig(
                      config: postBuild.copyWith(
                        powerConfig: powerConfig.copyWith(
                          delay: Duration(seconds: seconds),
                        ),
                      ),
                    ),
                  );
                },
              ).padOnly(t: 5),
            ],
          ],
        );
      },
    );
  }
}
