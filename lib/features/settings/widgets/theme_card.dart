import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/responsive/responsive_extension.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

import 'theme_preview_box.dart';
import 'theme_swatch_row.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    required this.displayName,
    required this.isActive,
    required this.isMobile,
    required this.onApply,
    required this.theme,
    super.key,
  });

  final VoidCallback onApply;
  final String displayName;
  final AppTheme theme;
  final bool isMobile;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final palette = theme.palette;
    final radius = ft.radius.card;

    final previewHeight = context.responsiveValue(
      compact: 112.0,
      medium: 116.0,
      large: 120.0,
    );

    final swatchSize = context.responsiveValue(
      compact: 9.0,
      medium: 10.0,
      large: 10.0,
    );

    final footerPad = context.responsiveValue(
      compact: ft.spacing.sm + 2,
      medium: ft.spacing.sm + 4,
      large: ft.spacing.md,
    );

    return AnimatedContainer(
      padding: isMobile ? const .only(bottom: 10) : null,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: .circular(radius),
        border: .all(
          color: isActive
              ? palette.accent.withValues(alpha: 0.85)
              : ft.colors.cardBorder.withValues(alpha: 0.75),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.22),
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                  blurRadius: 18,
                ),
              ]
            : null,
        color: ft.colors.cardBg,
      ),
      clipBehavior: .antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onApply();
                },
          hoverColor: palette.accent.withValues(alpha: 0.06),
          splashColor: palette.accent.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .min,
            children: [
              Stack(
                children: [
                  ThemePreviewCanvas(
                    height: previewHeight,
                    palette: palette,
                    radius: radius,
                  ),
                  if (isActive)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _ActiveBadge(
                        accent: palette.accent,
                        bg: palette.bg,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: .fromLTRB(
                  footerPad,
                  footerPad - 2,
                  footerPad,
                  footerPad,
                ),
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: ft.spacing.sm,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            size: context.isMobile ? .body : .subtitle,
                            weight: .w600,
                            displayName,
                          ),
                        ),
                        if (isActive)
                          _StatusPill(
                            background: palette.success.withValues(alpha: 0.14),
                            foreground: palette.success,
                            label: 'In use',
                          )
                        else
                          _StatusPill(
                            background: palette.accent.withValues(alpha: 0.12),
                            foreground: palette.accent,
                            label: 'Tap to apply',
                          ),
                      ],
                    ),
                    ThemeSwatchRow(palette: palette, size: swatchSize),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.accent, required this.bg});

  final Color accent;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(5),
      decoration: BoxDecoration(
        border: .all(color: accent.withValues(alpha: 0.6)),
        color: bg.withValues(alpha: 0.92),
        shape: .circle,
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10),
        ],
      ),
      child: Icon(Icons.check_rounded, color: accent, size: 14),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.background,
    required this.foreground,
    required this.label,
  });

  final Color background;
  final Color foreground;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: .circular(99), color: background),
      padding: const .symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          letterSpacing: 0.15,
          color: foreground,
          fontWeight: .w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
