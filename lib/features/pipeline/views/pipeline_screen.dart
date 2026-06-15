import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;
    return Scaffold(
      body: SingleChildScrollView(
        padding: .symmetric(horizontal: spacing.lg, vertical: spacing.lg),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                AppText.headline("ReelStay"),
                AppButton.primary(label: "Run Pipeline"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
