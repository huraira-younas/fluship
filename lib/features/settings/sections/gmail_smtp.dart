import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class GmailSmtp extends StatelessWidget {
  const GmailSmtp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
          hint: '••••••••••••••••',
          label: 'App password',
          onChanged: (value) {},
          obscureText: true,
        ),
      ],
    );
  }
}
