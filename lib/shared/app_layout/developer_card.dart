import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_ui/material_ui.dart';

class DeveloperCard extends StatelessWidget {
  const DeveloperCard({super.key});

  static const _wideMinWidth = 400.0;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth >= _wideMinWidth;

        return Container(
          padding: .all(wide ? ft.spacing.lg : ft.spacing.md),
          decoration: BoxDecoration(
            border: .all(color: ft.colors.cardBorder),
            borderRadius: .circular(ft.radius.card),
            color: ft.colors.codeBg,
          ),
          child: wide ? _wideBody(ft) : _compactBody(ft),
        );
      },
    );
  }

  Widget _wideBody(FlushipThemeExtension ft) {
    return Row(
      spacing: ft.spacing.md,
      children: [_identity(ft, markSize: 48).expanded(), _socialsRow(ft)],
    );
  }

  Widget _compactBody(FlushipThemeExtension ft) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: ft.spacing.md,
      children: [_identity(ft, markSize: 40), _socialsRow(ft, wrap: true)],
    );
  }

  Widget _identity(FlushipThemeExtension ft, {required double markSize}) {
    return Row(
      spacing: ft.spacing.md,
      children: [
        _mark(ft, size: markSize),
        Column(
          crossAxisAlignment: .start,
          children: [
            const AppText.subtitle(
              'Senpai',
              overflow: .ellipsis,
              weight: .w700,
              maxLines: 1,
            ),
            AppText.custom(
              'Creator of Fluship',
              color: ft.colors.textDim,
              overflow: .ellipsis,
              size: .caption,
              maxLines: 1,
            ),
          ],
        ).expanded(),
      ],
    );
  }

  Widget _mark(FlushipThemeExtension ft, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: .circular(ft.radius.input),
        color: ft.colors.accent.withValues(alpha: 0.14),
        border: .all(color: ft.colors.accent.withValues(alpha: 0.3)),
      ),
      child: Icon(
        color: ft.colors.accent,
        Icons.code_rounded,
        size: size * 0.5,
      ),
    );
  }

  Widget _socialsRow(FlushipThemeExtension ft, {bool wrap = false}) {
    final buttons = [
      for (final social in _socials)
        AppButton.icon(
          onPressed: () => _openSocial(social.url),
          semanticLabel: social.label,
          leading: Icon(social.icon),
          tooltip: social.label,
          variant: .outline,
          size: .sm,
        ),
    ];

    if (wrap) {
      return Wrap(
        runSpacing: ft.spacing.sm,
        spacing: ft.spacing.sm,
        children: buttons,
      );
    }

    return Row(mainAxisSize: .min, spacing: ft.spacing.sm, children: buttons);
  }
}
