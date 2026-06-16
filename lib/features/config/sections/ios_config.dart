import 'package:fluship/shared/models/ios_config.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:fluship/shared/widgets/switch_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class IosConfig extends StatelessWidget {
  const IosConfig({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<ConfigBloc>();
    return BlocSelector<ConfigBloc, ConfigState, IosConfigModel>(
      selector: (state) => state.ios,
      builder: (context, ios) {
        return AppCard(
          state: AppCardState(
            onEnable: (value) =>
                bloc.add(UpdateConfig(config: ios.copyWith(enabled: value))),
            enable: ios.enabled,
            forceDisabled: false,
          ),
          title: "iOS Config",
          description:
              "Control what iOS artifacts Fluship produces: enable IPA for App Store uploads or choose for direct distribution. "
              "Selecting the right output type here avoids a separate manual build step after the pipeline finishes.",
          children: [
            SwitchLabel(
              disabled: !ios.enabled,
              value: ios.podClean,
              label: "Pod Clean → pod deintegrate && pod update && pod install",
              onChange: (value) =>
                  bloc.add(UpdateConfig(config: ios.copyWith(podClean: value))),
            ),
            SwitchLabel(
              disabled: !ios.enabled,
              value: ios.buildIpa,
              label: "Build IPA → flutter build ipa",
              onChange: (value) =>
                  bloc.add(UpdateConfig(config: ios.copyWith(buildIpa: value))),
            ),
          ],
        );
      },
    );
  }
}
