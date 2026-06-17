import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/context_extensions.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/material.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    required this.showDivider,
    required this.displayName,
    required this.isActive,
    required this.onApply,
    required this.theme,
    super.key,
  });

  final VoidCallback onApply;
  final String displayName;
  final bool showDivider;
  final AppTheme theme;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = context.textTheme.bodyLarge;
    final ft = context.flushipTheme;
    final palette = theme.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? palette.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: isActive
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onApply();
                  },
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? palette.accent : Colors.transparent,
                    borderRadius: .circular(99),
                  ),
                ).padOnly(r: 10),
                _ThemeThumbnail(palette: palette),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: bodyStyle!.copyWith(
                        fontWeight: isActive ? .w600 : .w500,
                        color: ft.colors.text,
                        letterSpacing: -0.2,
                      ),
                      child: Text(displayName),
                    ),
                    if (isActive)
                      Text(
                        'Currently active',
                        style: context.textTheme.labelSmall!.copyWith(
                          color: palette.accent.withValues(alpha: 0.9),
                          fontWeight: .w500,
                        ),
                      ),
                  ],
                ).expanded(),
                _SelectionRing(accent: palette.accent, selected: isActive),
              ],
            ).padSym(h: 14, v: 11),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: ft.colors.cardBorder.withValues(alpha: 0.7),
          ),
      ],
    );
  }
}

class _ThemeThumbnail extends StatelessWidget {
  const _ThemeThumbnail({required this.palette});
  final ThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: .all(color: palette.cardBorder.withValues(alpha: 0.9)),
        borderRadius: .circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: .antiAlias,
      child: Stack(
        fit: .expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                end: .bottomRight,
                begin: .topLeft,
                colors: [
                  palette.bg,
                  Color.lerp(palette.bg, palette.accent, 0.4)!,
                  palette.consoleBg,
                ],
              ),
            ),
          ),
          SizedBox(
            width: 11,
            child: Column(
              children: [
                Container(color: palette.success, height: 11),
                Container(color: palette.accent, height: 11),
                Container(color: palette.danger, height: 12),
                Container(color: palette.warn, height: 12),
              ],
            ),
          ).align(align: .centerRight),
        ],
      ),
    ).padOnly(r: 14);
  }
}

class _SelectionRing extends StatelessWidget {
  const _SelectionRing({required this.accent, required this.selected});

  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final border = context.flushipTheme.colors.cardBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? accent : Colors.transparent,
        shape: .circle,
        boxShadow: selected
            ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8)]
            : null,
        border: .all(
          color: selected ? accent : border.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: selected
            ? const Icon(
                key: ValueKey('check'),
                color: Colors.white,
                Icons.check_rounded,
                size: 15,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}
