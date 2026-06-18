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
          'Choose who receives build summaries after each run and which addresses are included in automated distribution. '
          'Separate multiple emails with commas.',
      spacing: 15,
      children: [
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
