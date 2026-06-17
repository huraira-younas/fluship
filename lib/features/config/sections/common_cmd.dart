import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/labels_builder.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class CommonCmd extends StatelessWidget {
  const CommonCmd({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, CommonCmdModel>(
      selector: (state) => state.commonCmd,
      builder: (context, commonCmd) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) => bloc.add(
              UpdateConfig(config: commonCmd.copyWith(enabled: value)),
            ),
            enable: commonCmd.enabled,
            forceDisabled: false,
          ),
          title: "Common Config",
          description:
              "Run Flutter housekeeping commands before the build kicks off: wipe stale artifacts with flutter clean and restore packages with pub get or pub upgrade. "
              "Keeping these steps consistent prevents build failures caused by outdated caches or missing dependencies.",
          children: [
            SwitchLabel(
              disabled: !commonCmd.enabled,
              value: commonCmd.clean,
              label: "Clean → flutter clean",
              onChange: (value) => bloc.add(
                UpdateConfig(config: commonCmd.copyWith(clean: value)),
              ),
            ),
            Row(
              spacing: 10,
              children: <Widget>[
                SwitchLabel(
                  value: commonCmd.type != null,
                  disabled: !commonCmd.enabled,
                  label: "Dependencies",
                  onChange: (value) => bloc.add(
                    UpdateConfig(
                      config: commonCmd.copyWith(
                        type: value ? .get : null,
                        clearType: !value,
                      ),
                    ),
                  ),
                ).expanded(),
                LabelsBuilder<FlutterGetType>(
                  contentPadding: const .symmetric(horizontal: 20, vertical: 4),
                  disabled: !commonCmd.enabled || commonCmd.type == null,
                  onChange: (v) => bloc.add(
                    UpdateConfig(config: commonCmd.copyWith(type: v)),
                  ),
                  label: commonCmd.type ?? .get,
                  labels: FlutterGetType.values,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
