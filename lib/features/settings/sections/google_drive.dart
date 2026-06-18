import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class GoogleDrive extends StatelessWidget {
  const GoogleDrive({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Google Drive',
      description:
          'Upload build artifacts to Google Drive and share them with your team. '
          'Add your OAuth client credentials from Google Cloud Console, and optionally set a parent folder where uploads are stored.',
      spacing: 15,
      children: [
        FieldButton(
          hint: 'C:/Users/Username/Documents/oauth_client.json',
          label: 'OAuth client JSON',
          onBrowse: () {},
        ),
        FieldButton(
          hint: 'C:/Users/Username/Documents/gdrive_token.json',
          label: 'Token JSON (optional)',
          onBrowse: () {},
        ),
        AppTextField.label(
          hint: '1k21HPdFxA8Xa8R9qh7CBcB6A6TtE0kQF',
          label: 'Parent folder ID (optional)',
          onChanged: (value) {},
        ),
      ],
    );
  }
}
