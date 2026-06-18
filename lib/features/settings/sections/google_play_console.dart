import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class GooglePlayConsole extends StatelessWidget {
  const GooglePlayConsole({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
    );
  }
}
