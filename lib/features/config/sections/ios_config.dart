import 'package:fluship/shared/models/ios_config.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/switch_label.dart';
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
              "Manage your iOS build steps in one place: run a full CocoaPods reset to clear stale pod caches before compilation, and toggle IPA export for App Store or ad-hoc distribution. "
              "Pod Clean is especially useful when native dependency versions change and a simple pod install isn't enough.",
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
