import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          description: 'Configure Fluship Project and Distribution Settings',
          title: 'Environment Settings',
          children: [
            Row(
              spacing: 10,
              crossAxisAlignment: .end,
              children: <Widget>[
                const AppTextField.label(
                  hint: 'C:/Users/Username/Desktop/flutter_project',
                  label: 'Flutter Project Path',
                  enabled: false,
                ).expanded(),
                AppButton.primary(
                  label: "Browse",
                  onPressed: () {
                  },
                ).padOnly(b: 3),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
