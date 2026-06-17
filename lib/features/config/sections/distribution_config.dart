import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/models/distribute_config.dart';
import 'package:fluship/shared/widgets/labels_builder.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class DistributionConfig extends StatelessWidget {
  const DistributionConfig({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, DistributionConfigModel>(
      selector: (state) => state.distribution,
      builder: (context, distribution) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: distribution.copyWith(enabled: value)),
            ),
            enable: distribution.enabled,
            forceDisabled: false,
          ),
          title: "Distribution Config",
          description:
              "Choose where Fluship uploads your build artifacts after compilation: publish to Google Play (production or internal track) or share via Google Drive. "
              "Pick the right channel here so testers and store reviewers get the build without a manual upload step.",
          children: [
            Row(
              spacing: 10,
              children: <Widget>[
                SwitchLabel(
                  label: "Play Store",
                  value: distribution.playstore != null,
                  disabled: !distribution.enabled,
                  onChange: (value) => bloc.add(
                    UpdateConfig(
                      config: distribution.copyWith(
                        playstore: value ? .production : null,
                        clearPlaystore: !value,
                      ),
                    ),
                  ),
                ).expanded(),
                LabelsBuilder<PlayStoreDistribution>(
                  contentPadding: const .symmetric(horizontal: 20, vertical: 4),
                  disabled:
                      !distribution.enabled || distribution.playstore == null,
                  onChange: (v) => bloc.add(
                    UpdateConfig(config: distribution.copyWith(playstore: v)),
                  ),
                  label: distribution.playstore ?? .production,
                  labels: PlayStoreDistribution.values,
                ),
              ],
            ),
            SwitchLabel(
              disabled: !distribution.enabled,
              value: distribution.drive,
              label: "Drive",
              onChange: (value) => bloc.add(
                UpdateConfig(config: distribution.copyWith(drive: value)),
              ),
            ),
          ],
        );
      },
    );
  }
}
