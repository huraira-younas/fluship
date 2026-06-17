import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return Column(
      spacing: spacing.md,
      children: [
        AppCard(
          description: 'Configure your Flutter project root path',
          title: 'Fluship Project',
          children: [
            FieldButton(
              hint: 'C:/Users/Username/Desktop/flutter_project',
              label: 'Root path',
              onBrowse: () {},
            ),
          ],
        ),
        AppCard(
          description: 'Configure your Google Drive credentials',
          title: 'Google Drive Credentials',
          spacing: 15,
          children: [
            FieldButton(
              hint: 'C:/Users/Username/Desktop/flutter_project/oauth_client.json',
              label: 'Oauth client json',
              onBrowse: () {},
            ),

            FieldButton(
              hint: 'C:/Users/Username/Desktop/flutter_project/token.json',
              label: 'Token json',
              onBrowse: () {},
            ),
          ],
        ),
      ],
    );
  }
}
