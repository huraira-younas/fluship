import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import '../widgets/field_button.dart';

class CredentialsBuilder extends StatelessWidget {
  const CredentialsBuilder({super.key, required this.spacing});
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spacing,
      children: [
        AppCard(
          title: 'Project Root',
          description:
              'Point Fluship at your Flutter app folder — the directory that contains pubspec.yaml. '
              'Build commands, config files, and artifact paths are all resolved from here.',
          children: [
            FieldButton(
              hint: 'C:/Users/Username/Desktop/flutter_project',
              label: 'Flutter project path',
              onBrowse: () {},
            ),
          ],
        ),
        AppCard(
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
              label: 'Parent folder ID (optional)',
              onChanged: (value) {},
              hint: '1k21HPdFxA8Xa8R9qh7CBcB6A6TtE0kQF',
            ),
          ],
        ),
        AppCard(
          title: 'Google Play Console',
          description:
              'Authorize Play Store uploads with a service account JSON key from Google Cloud Console. '
              'Leave the package name blank to use the value from your Flutter project automatically.',
          spacing: 15,
          children: [
            AppTextField.label(
              label: 'Package name (optional)',
              onChanged: (value) {},
              hint: 'com.example.my_app',
            ),
            FieldButton(
              hint: 'C:/Users/Username/Documents/play_service_account.json',
              label: 'Service account JSON',
              onBrowse: () {},
            ),
          ],
        ),
        AppCard(
          title: 'Gmail SMTP',
          description:
              'Fluship sends build reports and distribution emails through your Gmail account. '
              'Use an App Password from Google Account → Security → 2-Step Verification — not your regular login password.',
          spacing: 15,
          children: [
            AppTextField.label(
              keyboardType: TextInputType.emailAddress,
              label: 'Gmail address',
              onChanged: (value) {},
              hint: 'you@gmail.com',
            ),
            AppTextField.label(
              label: 'App password',
              onChanged: (value) {},
              obscureText: true,
              hint: '••••••••••••••••',
            ),
          ],
        ),
        AppCard(
          title: 'Reports & Recipients',
          description:
              'Choose who receives build summaries after each run and which addresses are included in automated distribution. '
              'Separate multiple emails with commas.',
          spacing: 15,
          children: [
            AppTextField.label(
              keyboardType: TextInputType.emailAddress,
              label: 'Report recipient',
              onChanged: (value) {},
              hint: 'reports@example.com',
            ),
            AppTextField.label(
              keyboardType: TextInputType.emailAddress,
              label: 'Distribution list',
              onChanged: (value) {},
              hint: 'alice@example.com, bob@example.com',
            ),
          ],
        ),
      ],
    );
  }
}
