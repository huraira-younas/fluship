import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ReportsRecipients extends StatelessWidget {
  const ReportsRecipients({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Reports & Recipients',
      description:
          '• Enter your Gmail address and an App Password from Google Account → Security → 2-Step Verification.\n'
          '• Set the report recipient who receives the build summary after each run.\n'
          '• Add a comma-separated distribution list for who gets each build.',
      spacing: 15,
      children: [
        AppTextField.label(
          keyboardType: TextInputType.emailAddress,
          label: 'Gmail address',
          onChanged: (value) {},
          hint: 'you@gmail.com',
        ),
        AppTextField.label(
          hint: '••••••••••••••••',
          label: 'App password',
          onChanged: (value) {},
          obscureText: true,
        ),
        AppTextField.label(
          keyboardType: TextInputType.emailAddress,
          hint: 'reports@example.com',
          label: 'Report recipient',
          onChanged: (value) {},
        ),
        AppTextField.label(
          hint: 'alice@example.com, bob@example.com',
          keyboardType: TextInputType.emailAddress,
          label: 'Distribution list',
          onChanged: (value) {},
        ),
      ],
    );
  }
}
