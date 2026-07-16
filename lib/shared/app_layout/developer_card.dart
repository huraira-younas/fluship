import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class DeveloperCard extends StatelessWidget {
  const DeveloperCard({super.key});

  static final _socials = [
    (
      url: Uri.parse('https://www.linkedin.com/in/senpai'),
      icon: Icons.work_outline_rounded,
      label: 'LinkedIn',
    ),
    (
      url: Uri.parse('https://www.youtube.com/@senpai'),
      icon: Icons.play_arrow_rounded,
      label: 'YouTube',
    ),
    (
      url: Uri.parse('https://github.com/senpai'),
      icon: Icons.code_rounded,
      label: 'GitHub',
    ),
  ];

  Future<void> _openSocial(Uri url) async {
    try {
      final opened = await launchUrl(url, mode: .externalApplication);
      if (!opened) AppToast.error('Could not open social profile');
    } catch (_) {
      AppToast.error('Could not open social profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Container(
      padding: .all(ft.spacing.md),
      decoration: BoxDecoration(
        border: .all(color: ft.colors.cardBorder),
        borderRadius: .circular(ft.radius.card),
        color: ft.colors.codeBg,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: ft.spacing.md,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: .circular(ft.radius.input),
                  color: ft.colors.accent.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: ft.colors.accent,
                  size: 20,
                ).padAll(ft.spacing.md),
              ).padOnly(r: ft.spacing.md),
              const Column(
                crossAxisAlignment: .start,
                children: [
                  AppText.subtitle('Made by Senpai', weight: .w700),
                  AppText.label('Developer of Fluship'),
                ],
              ).expanded(),
            ],
          ),
          Row(
            spacing: ft.spacing.sm,
            children: [
              for (final social in _socials)
                AppButton.secondary(
                  onPressed: () => _openSocial(social.url),
                  leading: Icon(social.icon),
                  label: social.label,
                  size: .sm,
                ).expanded(),
            ],
          ),
        ],
      ),
    );
  }
}
