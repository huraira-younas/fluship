import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

import '../widgets/credentials_builder.dart';
import '../widgets/theme_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return Column(
      spacing: spacing.md,
      children: [
        CredentialsBuilder(spacing: spacing.md),
        ThemeSelector(spacing: spacing.md),
      ],
    );
  }
}
