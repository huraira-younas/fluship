import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/core/responsive/responsive.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/features/layout_wrapper.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return LayoutWrapper(
      child: SingleChildScrollView(
        padding: .all(spacing.md),
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
