import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class BuildConfig extends StatefulWidget {
  const BuildConfig({super.key});

  @override
  State<BuildConfig> createState() => _BuildConfigState();
}

class _BuildConfigState extends State<BuildConfig> {
  final controllers = List.generate(3, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: "Build Config",
      description:
          "Set the release version and build number Fluship will apply before compiling your app. "
          "The version is what users see in the store; the build number tracks each new binary. "
          "Pick the Git branch to pull source from when you run the build in the Console tab.",
      children: [
        Row(
          spacing: context.flushipTheme.spacing.lg * 1.4,
          children: <Widget>[
            AppTextField.label(
              controller: controllers[0],
              label: "Build Version",
              hint: "1.0.0",
            ).expanded(),
            AppText.custom(
              "•",
              color: context.flushipTheme.colors.section,
              size: .headline,
            ),
            AppTextField.label(
              controller: controllers[1],
              label: "Build Number",
              hint: "1",
            ).expanded(),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField.label(
          controller: controllers[2],
          label: "Target Git Branch",
          hint: "master",
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
