import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/switch_labels_row.dart';
import '../widgets/switch_label.dart';
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
            SwitchLabelsRow<FlutterGetType>(
              labels: FlutterGetType.values,
              disabled: !commonCmd.enabled,
              switchLabel: 'Dependencies',
              value: commonCmd.type,
              defaultValue: .get,
              onChange: (value) => bloc.add(
                UpdateConfig(
                  config: commonCmd.copyWith(
                    clearType: value == null,
                    type: value,
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
