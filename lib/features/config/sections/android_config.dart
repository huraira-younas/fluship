import 'package:fluship/shared/widgets/switch_labels_row.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class AndroidConfig extends StatelessWidget {
  const AndroidConfig({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, AndroidConfigModel>(
      selector: (state) => state.android,
      builder: (context, android) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: android.copyWith(enabled: value)),
            ),
            enable: android.enabled,
            forceDisabled: false,
          ),
          title: "Android Config",
          description:
              "Control what Android artifacts Fluship produces: enable AAB for Play Store uploads or choose APK/split-APK for direct distribution. "
              "Selecting the right output type here avoids a separate manual build step after the pipeline finishes.",
          children: [
            SwitchLabel(
              label: "Build AAB → flutter build aab",
              disabled: !android.enabled,
              value: android.buildAab,
              onChange: (value) => bloc.add(
                UpdateConfig(config: android.copyWith(buildAab: value)),
              ),
            ),
            SwitchLabelsRow<AndroidBuildType>(
              labels: AndroidBuildType.values,
              disabled: !android.enabled,
              switchLabel: 'Build Type',
              value: android.buildType,
              defaultValue: .apk,
              onChange: (value) => bloc.add(
                UpdateConfig(
                  config: android.copyWith(
                    clearBuildType: value == null,
                    buildType: value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
