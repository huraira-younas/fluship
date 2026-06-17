import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/validator_builder.dart';

import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';

import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import '../bloc/config_bloc.dart';

class BuildConfig extends StatefulWidget {
  const BuildConfig({super.key});

  @override
  State<BuildConfig> createState() => _BuildConfigState();
}

class _BuildConfigState extends State<BuildConfig> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  final _keys = List.generate(3, (_) => GlobalKey<FormFieldState>());

  final bValidator = ValidatorBuilder.chain()
      .required("Build Version is required")
      .build();

  final bnValidator = ValidatorBuilder.chain()
      .required("Build Number is required")
      .build();

  final gbValidator = ValidatorBuilder.chain()
      .required("Target Git Branch is required")
      .build();

  void _onChange(dynamic _) {
    final buildNumber = _controllers[1].text.trim();
    final gitBranch = _controllers[2].text.trim();
    final version = _controllers[0].text.trim();

    final bloc = getIt<ConfigBloc>();
    final appInfo = bloc.state.appInfo.copyWith(
      buildNumber: buildNumber.isEmpty ? null : buildNumber,
      gitBranch: gitBranch.isEmpty ? null : gitBranch,
      version: version.isEmpty ? null : version,
    );

    bloc.add(UpdateConfig(config: appInfo));
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      spacing: 15,
      title: "Build Config",
      description:
          "Set the release version and build number Fluship will apply before compiling your app. "
          "The version is what users see in the store; the build number tracks each new binary. "
          "Pick the Git branch to pull source from when you run the build in the Console tab.",
      children: [
        Row(
          crossAxisAlignment: .start,
          spacing: context.flushipTheme.spacing.lg * 1.4,
          children: <Widget>[
            AppTextField.label(
              controller: _controllers[0],
              label: "Build Version",
              validator: bValidator,
              onChanged: _onChange,
              hint: "1.0.0",
              key: _keys[0],
            ).expanded(),
            AppTextField.label(
              controller: _controllers[1],
              validator: bnValidator,
              label: "Build Number",
              onChanged: _onChange,
              key: _keys[1],
              hint: "1",
            ).expanded(),
          ],
        ),
        AppTextField.label(
          controller: _controllers[2],
          label: "Target Git Branch",
          validator: gbValidator,
          onChanged: _onChange,
          hint: "master",
          key: _keys[2],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final bloc = getIt<ConfigBloc>();
    _controllers[1].text = bloc.state.appInfo.buildNumber ?? "";
    _controllers[2].text = bloc.state.appInfo.gitBranch ?? "";
    _controllers[0].text = bloc.state.appInfo.version ?? "";
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
