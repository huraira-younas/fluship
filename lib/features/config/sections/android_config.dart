import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/labels_builder.dart';
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
            Row(
              spacing: 10,
              children: <Widget>[
                SwitchLabel(
                  label: "Build Type",
                  value: android.buildType != null,
                  disabled: !android.enabled,
                  onChange: (value) => bloc.add(
                    UpdateConfig(
                      config: android.copyWith(
                        buildType: value ? .apk : null,
                        clearBuildType: !value,
                      ),
                    ),
                  ),
                ).expanded(),
                LabelsBuilder<AndroidBuildType>(
                  contentPadding: const .symmetric(horizontal: 20, vertical: 4),
                  disabled: !android.enabled || android.buildType == null,
                  onChange: (v) => bloc.add(
                    UpdateConfig(config: android.copyWith(buildType: v)),
                  ),
                  label: android.buildType ?? .apk,
                  labels: AndroidBuildType.values,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
