import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class GmailSmtp extends StatelessWidget {
  const GmailSmtp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Gmail Drive',
      description:
          '• Add your OAuth client JSON from Google Cloud Console to enable Drive uploads.\n'
          '• Optionally provide a saved token JSON to skip re-authorization on the next run.\n'
          '• Set a parent folder ID to control where build artifacts are stored in Drive.',
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
