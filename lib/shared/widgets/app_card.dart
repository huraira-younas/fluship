import 'package:fluship/core/app_theme/app_theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.description,
    required this.children,
    required this.title,
    super.key,
  });

  final List<Widget> children;
  final String description;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Container(
      padding: .all(ft.spacing.lg),
      decoration: BoxDecoration(
        border: .all(color: ft.colors.cardBorder),
        borderRadius: .circular(ft.radius.card),
        color: ft.colors.codeBg,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 4,
        children: [
          AppText.title(title),
          AppText.label(description),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
