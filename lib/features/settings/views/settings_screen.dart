import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter/material.dart';

import '../sections/exports.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return Column(
      spacing: spacing.md,
      children: [
        const ProjectRoot(),
        const GoogleDrive(),
        const GooglePlayConsole(),
        const GmailSmtp(),
        const ReportsRecipients(),
        ThemeSelector(spacing: spacing.md),
      ],
    );
  }
}
