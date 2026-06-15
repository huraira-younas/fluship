import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/labels_builder.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/core/responsive/responsive.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum Tabs { config, console, settings }

class TopBuilder extends StatelessWidget {
  const TopBuilder({required this.spacing, super.key});
  final ThemeSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ResponsiveBuilder(
          builder: (context, info) {
            final isMobile = info.isMobile;
            final header = <Widget>[
              if (isMobile)
                const AppText.headline('ReelStay')
              else
                const AppText.headline('ReelStay').expanded(),
              AppButton.primary(label: 'Run Pipeline', onPressed: () {}),
            ];

            if (isMobile) {
              return Column(
                crossAxisAlignment: .stretch,
                spacing: spacing.md,
                children: header,
              );
            }

            return Row(spacing: spacing.md, children: header);
          },
        ),
        LabelsBuilder(
          padding: .symmetric(horizontal: spacing.md),
          labels: Tabs.values,
          label: Tabs.config,
          onChange: (value) {},
        ),
      ],
    );
  }
}
