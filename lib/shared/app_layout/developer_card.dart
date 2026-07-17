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
      padding: .all(ft.spacing.lg),
      decoration: BoxDecoration(
        border: .all(color: ft.colors.cardBorder),
        borderRadius: .circular(ft.radius.card),
        gradient: LinearGradient(
          begin: .topLeft,
          end: .bottomRight,
          colors: [ft.colors.accent.withValues(alpha: 0.1), ft.colors.codeBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: ft.spacing.lg,
        children: [
          Row(
            crossAxisAlignment: .center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: .circular(ft.radius.input),
                  color: ft.colors.accent.withValues(alpha: 0.14),
                  border: .all(color: ft.colors.accent.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.code_rounded,
                  color: ft.colors.accent,
                  size: 24,
                ),
              ).padOnly(r: ft.spacing.md),
              Column(
                crossAxisAlignment: .start,
                children: [
                  const AppText.subtitle('Senpai', weight: .w700),
                  AppText.custom(
                    'Creator of Fluship',
                    color: ft.colors.textDim,
                    size: .caption,
                  ),
                ],
              ).expanded(),
              Icon(
                Icons.auto_awesome_rounded,
                color: ft.colors.accent.withValues(alpha: 0.75),
                size: 18,
              ),
            ],
          ),
          Container(
            height: 1,
            color: ft.colors.cardBorder.withValues(alpha: 0.7),
          ),
          Wrap(
            alignment: .end,
            spacing: ft.spacing.sm,
            runSpacing: ft.spacing.sm,
            children: [
              for (final social in _socials)
                AppButton.icon(
                  onPressed: () => _openSocial(social.url),
                  semanticLabel: social.label,
                  tooltip: social.label,
                  leading: Icon(social.icon),
                  variant: .outline,
                  size: .sm,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
